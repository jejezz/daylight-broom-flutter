import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../system/login_item.dart' show ProcessRunner;

class VolumeInfo {
  const VolumeInfo({required this.total, required this.free});

  final int total;
  final int free;

  int get used => total - free;
  double get usedRatio => total == 0 ? 0 : (used / total).clamp(0, 1);
}

/// 개요에서 고를 수 있는 디스크 하나 (내장·고정 디스크만. 이동식·네트워크는 대상이 아니다).
class DiskVolume extends VolumeInfo {
  const DiskVolume({required this.name, required this.path, required this.isSystem, required super.total, required super.free});

  /// 화면에 보이는 이름. Windows 는 "C:" 또는 "C: 라벨", macOS 는 볼륨 이름.
  final String name;

  /// 마운트 위치 (macOS `/`, Windows `C:\`).
  final String path;

  /// 운영체제가 설치된 디스크.
  final bool isSystem;
}

/// 디스크 용량과 (macOS의) 전체 디스크 접근 권한. macOS는 Swift 채널
/// (`macos/Runner/MainFlutterWindow.swift`), Windows는 PowerShell 로 읽는다.
class DiskInfo {
  DiskInfo({MethodChannel? channel, ProcessRunner? run, Map<String, String>? env, bool? isMac, bool? isWindows})
      : _channel = channel ?? const MethodChannel('art.zoomon.daylightbroom/system'),
        _run = run ?? Process.run,
        _env = env ?? Platform.environment,
        _isMac = isMac ?? Platform.isMacOS,
        _isWindows = isWindows ?? Platform.isWindows;

  final MethodChannel _channel;
  final ProcessRunner _run;
  final Map<String, String> _env;
  final bool _isMac;
  final bool _isWindows;

  /// 고정(내장) 디스크 목록. 시스템 디스크가 맨 앞이다. 읽지 못하면 빈 목록.
  Future<List<DiskVolume>> volumes() async {
    try {
      if (_isMac) {
        final r = await _channel.invokeListMethod<Map<Object?, Object?>>('volumes');
        final list = <DiskVolume>[
          for (final m in r ?? const <Map<Object?, Object?>>[])
            if (((m['total'] as num?) ?? 0) > 0)
              DiskVolume(
                name: '${m['name'] ?? m['path']}',
                path: '${m['path']}',
                isSystem: m['path'] == '/',
                total: (m['total'] as num).toInt(),
                free: ((m['free'] as num?) ?? 0).toInt(),
              ),
        ];
        return _systemFirst(list);
      }
      if (_isWindows) {
        final r = await _run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          r"[System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' -and $_.IsReady } | "
              r"ForEach-Object { '{0}|{1}|{2}|{3}' -f $_.Name, $_.VolumeLabel, $_.TotalSize, $_.AvailableFreeSpace }",
        ]);
        if (r.exitCode != 0) return const [];
        final systemLetter = RegExp(r'^[A-Za-z]').firstMatch(_env['SystemDrive'] ?? 'C:')?.group(0)?.toUpperCase() ?? 'C';
        return _systemFirst(parseDrivesOutput('${r.stdout}', systemLetter: systemLetter));
      }
    } on Object {
      // 읽지 못하면 화면은 "—"로 보여 준다.
    }
    return const [];
  }

  static List<DiskVolume> _systemFirst(List<DiskVolume> list) =>
      [...list.where((v) => v.isSystem), ...list.where((v) => !v.isSystem)];

  /// 한 줄에 디스크 하나, `"<이름>|<라벨>|<총량>|<여유>"`.
  @visibleForTesting
  static List<DiskVolume> parseDrivesOutput(String output, {String systemLetter = 'C'}) {
    final volumes = <DiskVolume>[];
    for (final line in output.split(RegExp(r'[\r\n]+'))) {
      final parts = line.trim().split('|');
      if (parts.length < 4) continue;
      final path = parts.first.trim();
      final total = int.tryParse(parts[parts.length - 2].trim());
      final free = int.tryParse(parts.last.trim());
      if (path.isEmpty || total == null || free == null || total <= 0) continue;
      final label = parts.sublist(1, parts.length - 2).join('|').trim();
      final letter = path.substring(0, 1).toUpperCase();
      final drive = '$letter:';
      volumes.add(DiskVolume(
        name: label.isEmpty ? drive : '$drive $label',
        path: path,
        isSystem: letter == systemLetter,
        total: total,
        free: free,
      ));
    }
    return volumes;
  }

  /// macOS 에서만 의미가 있다. 다른 OS 와 실패는 null (해당 없음/모름).
  Future<bool?> hasFullDiskAccess() async {
    if (!_isMac) return null;
    try {
      return await _channel.invokeMethod<bool>('hasFullDiskAccess');
    } on Object {
      return null;
    }
  }

  Future<void> openFullDiskAccessSettings() async {
    if (_isMac) await _channel.invokeMethod<void>('openFullDiskAccessSettings');
  }

  Future<void> revealInFinder(String path) async {
    if (_isMac) await _channel.invokeMethod<void>('revealInFinder', {'path': path});
  }
}

/// 개요 화면의 디스크 상태.
class DiskController extends ChangeNotifier {
  DiskController(this.info);

  final DiskInfo info;

  List<DiskVolume> volumes = const [];
  String? _selectedPath;

  /// null 이면 해당 없음(macOS 가 아님)이거나 알 수 없음.
  bool? fullDiskAccess;
  bool loaded = false;

  /// 지금 고른 디스크. 고른 적이 없으면 시스템 디스크(목록의 첫 번째).
  DiskVolume? get volume {
    for (final v in volumes) {
      if (v.path == _selectedPath) return v;
    }
    return volumes.isEmpty ? null : volumes.first;
  }

  void select(DiskVolume v) {
    if (v.path == volume?.path) return;
    _selectedPath = v.path;
    notifyListeners();
  }

  Future<void> refresh() async {
    volumes = await info.volumes();
    fullDiskAccess = await info.hasFullDiskAccess();
    loaded = true;
    notifyListeners();
  }
}
