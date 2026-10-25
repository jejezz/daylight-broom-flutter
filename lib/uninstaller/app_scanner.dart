import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../cleaner/folder_sizer.dart';
import 'installed_app.dart';

/// `.app` 번들의 정체(번들 id, 이름, 버전)를 읽는다.
abstract class AppInfoReader {
  Future<({String? bundleId, String? name, String? version})?> read(String appPath);
}

/// `plutil`로 Info.plist 를 JSON 으로 바꿔 읽는다 (바이너리 plist 도 된다). 모든 macOS 에 있다.
class PlistAppInfoReader implements AppInfoReader {
  const PlistAppInfoReader();

  @override
  Future<({String? bundleId, String? name, String? version})?> read(String appPath) async {
    final plist = p.join(appPath, 'Contents', 'Info.plist');
    if (!File(plist).existsSync()) return null;
    try {
      final r = await Process.run('plutil', ['-convert', 'json', '-o', '-', plist]);
      if (r.exitCode != 0) return null;
      final info = (jsonDecode('${r.stdout}') as Map).cast<String, Object?>();
      return (
        bundleId: info['CFBundleIdentifier'] as String?,
        name: (info['CFBundleDisplayName'] ?? info['CFBundleName']) as String?,
        version: info['CFBundleShortVersionString'] as String?,
      );
    } on Object {
      return null;
    }
  }
}

/// 앱이 데이터를 두는 곳. 하위 항목 이름에 번들 id 나 앱 이름이 들어 있다.
const _leftoverDirs = [
  '~/Library/Application Support',
  '~/Library/Caches',
  '~/Library/Preferences',
  '~/Library/Logs',
  '~/Library/Containers',
  '~/Library/Group Containers',
  '~/Library/Saved Application State',
  '~/Library/HTTPStorages',
  '~/Library/WebKit',
  '~/Library/Cookies',
  '~/Library/LaunchAgents',
  '~/Library/Preferences/ByHost',
  '~/Library/Application Scripts',
  '~/Library/Application Support/CrashReporter',
  '~/Library/Internet Plug-Ins',
  '~/Library/PreferencePanes',
  '~/Library/Services',
  '~/Library/Receipts',
  '~/Library/Autosave Information',
  '~/Library/Metadata/CoreSpotlight',
  '~/Library/Daemon Containers',
];

class AppScanner {
  AppScanner({
    AppInfoReader? reader,
    FolderSizer? sizer,
    Map<String, String>? env,
    this.appDirsOverride,
    this.ownBundleId,
  })  : _reader = reader ?? const PlistAppInfoReader(),
        _sizer = sizer ?? FolderSizer.forPlatform(),
        _env = env ?? Platform.environment;

  final AppInfoReader _reader;
  final FolderSizer _sizer;
  final Map<String, String> _env;

  /// 테스트에서 폴더를 바꿔 끼운다. null 이면 `/Applications`와 `~/Applications`.
  final List<String>? appDirsOverride;

  /// 목록에서 뺄 앱 (이 앱 자신을 지우는 일이 없게).
  final String? ownBundleId;

  String get _home => _env['HOME'] ?? '';

  List<String> get appDirs => appDirsOverride ?? ['/Applications', '$_home/Applications'];

  Future<List<InstalledApp>> listApps() async {
    final bundles = <String>[];
    for (final dir in appDirs) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      try {
        for (final e in d.listSync(followLinks: false)) {
          if (e.path.endsWith('.app')) bundles.add(e.path);
        }
      } on FileSystemException {
        continue;
      }
    }
    final sizes = (await _sizer.measure(bundles)).bytes;
    final apps = <InstalledApp>[];
    // 한꺼번에 수백 개 프로세스를 띄우지 않도록 묶어서 읽는다.
    for (var i = 0; i < bundles.length; i += 16) {
      final chunk = bundles.skip(i).take(16).toList();
      final infos = await Future.wait(chunk.map(_reader.read));
      for (var j = 0; j < chunk.length; j++) {
        final info = infos[j];
        if (info == null) continue;
        if (ownBundleId != null && info.bundleId == ownBundleId) continue;
        apps.add(InstalledApp(
          path: chunk[j],
          bytes: sizes[chunk[j]] ?? 0,
          bundleId: info.bundleId,
          displayName: info.name,
          version: info.version,
        ));
      }
    }
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  List<FileSystemEntity> _list(String dir) {
    try {
      return Directory(dir).listSync(followLinks: false);
    } on FileSystemException {
      return const []; // 없거나 권한이 없다
    }
  }

  /// `~/Library`에서 [app]의 것으로 보이는 파일을 번들 id 나 이름으로 찾는다. 번들 id 로 찾은 것은
  /// 거의 확실하고, 이름으로 찾은 것은 다른 앱의 데이터일 수 있어 호출한 쪽이 기본 선택하지 않는다.
  Future<List<Leftover>> findLeftovers(InstalledApp app) async {
    final id = app.bundleId?.toLowerCase();
    final names = <String>{
      for (final n in [app.name.toLowerCase(), p.basenameWithoutExtension(app.path).toLowerCase()])
        if (n.length >= 4) ...[n, n.replaceAll(' ', '')],
    };
    // com.google.Chrome → 제작사 "google", 제품 "chrome". `Application Support/Google/Chrome`처럼 한 단계 안에 둔다.
    final parts = id?.split('.') ?? const <String>[];
    final vendor = parts.length >= 3 ? parts[1] : null;
    final product = parts.isNotEmpty ? parts.last : null;

    bool byId(String base) => id != null && id.isNotEmpty && base.contains(id);
    // 이름은 통째로 같거나, 이름 뒤가 글자·숫자가 아닐 때만 (`notes`가 `notes2hub`를 잡지 않게).
    bool byName(String base) => names.any((n) {
          if (base == n) return true;
          if (!base.startsWith(n)) return false;
          return !RegExp(r'[a-z0-9]').hasMatch(base[n.length]);
        });

    final found = <String, LeftoverMatch>{};
    for (final raw in _leftoverDirs) {
      final dir = raw.replaceFirst('~', _home);
      for (final e in _list(dir)) {
        final base = p.basename(e.path).toLowerCase();
        if (byId(base)) {
          found[e.path] = LeftoverMatch.bundleId;
        } else if (byName(base)) {
          found.putIfAbsent(e.path, () => LeftoverMatch.name);
        } else if (vendor != null && base == vendor && e is Directory) {
          for (final child in _list(e.path)) {
            final cb = p.basename(child.path).toLowerCase();
            if (byId(cb)) {
              found[child.path] = LeftoverMatch.bundleId;
            } else if (byName(cb) || (product != null && product.length >= 4 && cb == product)) {
              found.putIfAbsent(child.path, () => LeftoverMatch.name);
            }
          }
        }
      }
    }
    final sizes = (await _sizer.measure(found.keys.toList())).bytes;
    return [for (final e in found.entries) Leftover(path: e.key, bytes: sizes[e.key] ?? 0, match: e.value)]
      ..sort((a, b) {
        final byMatch = a.match.index.compareTo(b.match.index);
        return byMatch != 0 ? byMatch : b.bytes.compareTo(a.bytes);
      });
  }
}
