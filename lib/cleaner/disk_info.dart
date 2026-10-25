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

  /// 시스템 볼륨의 용량. 읽지 못하면 null.
  Future<VolumeInfo?> volume() async {
    try {
      if (_isMac) {
        final r = await _channel.invokeMapMethod<String, dynamic>('volumeInfo', {'path': '/'});
        if (r == null) return null;
        return VolumeInfo(total: (r['total'] as num).toInt(), free: (r['free'] as num).toInt());
      }
      if (_isWindows) {
        // 드라이브 문자 한 글자만 받아 스크립트에 넣는다 (환경 변수 값을 그대로 넣지 않는다).
        final letter = RegExp(r'^[A-Za-z]').firstMatch(_env['SystemDrive'] ?? 'C:')?.group(0) ?? 'C';
        final r = await _run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "\$d = New-Object System.IO.DriveInfo('$letter'); Write-Output ('{0} {1}' -f \$d.TotalSize, \$d.AvailableFreeSpace)",
        ]);
        if (r.exitCode != 0) return null;
        return parseDriveOutput('${r.stdout}');
      }
    } on Object {
      // 읽지 못하면 화면은 "—"로 보여 준다.
    }
    return null;
  }

  /// `"<총량> <여유>"` 한 줄을 읽는다.
  @visibleForTesting
  static VolumeInfo? parseDriveOutput(String output) {
    final parts = output.trim().split(RegExp(r'\s+'));
    if (parts.length != 2) return null;
    final total = int.tryParse(parts[0]);
    final free = int.tryParse(parts[1]);
    if (total == null || free == null || total <= 0) return null;
    return VolumeInfo(total: total, free: free);
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

  VolumeInfo? volume;

  /// null 이면 해당 없음(macOS 가 아님)이거나 알 수 없음.
  bool? fullDiskAccess;
  bool loaded = false;

  Future<void> refresh() async {
    volume = await info.volume();
    fullDiskAccess = await info.hasFullDiskAccess();
    loaded = true;
    notifyListeners();
  }
}
