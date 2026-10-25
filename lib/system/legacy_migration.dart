import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/app_settings.dart';
import 'login_item.dart';

/// Stevedore였던 시절의 사용자 데이터를 Daylight Broom으로 한 번 옮긴다.
/// 이름이 바뀌면서 식별자·설정 폴더·로그인 항목이 모두 달라졌기 때문이다.
/// 옛 데이터는 지우지 않고 그대로 둔다 (옛 앱을 다시 쓸 수 있게) — 로그인 항목만
/// 두 앱이 함께 뜨지 않도록 옛 것을 거둔다.
class LegacyMigration {
  LegacyMigration({Map<String, String>? env, ProcessRunner? run, bool? isMac, bool? isWindows})
      : _env = env ?? Platform.environment,
        _run = run ?? Process.run,
        _isMac = isMac ?? Platform.isMacOS,
        _isWindows = isWindows ?? Platform.isWindows;

  static const oldAppName = 'Stevedore';
  static const oldBundleId = 'art.zoomon.stevedore';

  final Map<String, String> _env;
  final ProcessRunner _run;
  final bool _isMac;
  final bool _isWindows;

  String get _home => _env['HOME'] ?? '';

  /// 옛 설정 폴더 (`rules.json`, `history.json`이 있던 곳).
  String get legacyAppSupportPath =>
      _isWindows ? p.windows.join(_env['APPDATA'] ?? '', oldAppName) : p.join(_home, 'Library', 'Application Support', oldAppName);

  /// 새 설정 폴더가 비어 있을 때만 옛 파일을 복사한다. 새 앱에서 이미 쓰기 시작했다면 건드리지 않는다.
  Future<void> migrateFiles(Directory target) async {
    final source = Directory(legacyAppSupportPath);
    if (!await source.exists()) return;
    if (await target.exists() && !await target.list().isEmpty) return;
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      if (entity is File) await entity.copy(p.join(target.path, p.basename(entity.path)));
    }
  }

  /// 테마·언어 같은 저장 값. 새 키가 이미 있으면 덮어쓰지 않는다.
  Future<void> migratePreferences(SharedPreferences prefs) async {
    final old = await _readLegacyPreferences();
    for (final key in const [
      AppSettings.themeModeKey,
      AppSettings.localeKey,
      AppSettings.removeEmptyFoldersKey,
      AppSettings.collapsedRuleFoldersKey,
    ]) {
      final value = old['flutter.$key'];
      if (value == null || prefs.containsKey(key)) continue;
      if (value is String) await prefs.setString(key, value);
      if (value is bool) await prefs.setBool(key, value);
      if (value is List) await prefs.setStringList(key, value.cast<String>());
    }
  }

  Future<Map<String, Object?>> _readLegacyPreferences() async {
    try {
      if (_isMac) {
        // shared_preferences는 앱 도메인(UserDefaults)에 `flutter.` 접두어로 저장한다.
        final plist = p.join(_home, 'Library', 'Preferences', '$oldBundleId.plist');
        if (!File(plist).existsSync()) return {};
        final result = await _run('plutil', ['-convert', 'json', '-o', '-', plist]);
        if (result.exitCode != 0) return {};
        return (jsonDecode('${result.stdout}') as Map).cast<String, Object?>();
      }
      if (_isWindows) {
        // 플러그인이 `%APPDATA%\<CompanyName>\<ProductName>\shared_preferences.json`에 쓴다.
        final file = File(p.windows.join(_env['APPDATA'] ?? '', 'Jongyun Ahn', oldAppName, 'shared_preferences.json'));
        if (!file.existsSync()) return {};
        return (jsonDecode(await file.readAsString()) as Map).cast<String, Object?>();
      }
    } on Object {
      // 옮기지 못해도 새 앱은 기본값으로 정상 시작한다.
    }
    return {};
  }

  /// 옛 로그인 항목이 있었으면 지우고 true. 호출한 쪽이 새 항목을 켠다.
  Future<bool> removeLegacyLoginItem() async {
    try {
      if (_isMac) {
        final plist = File(p.join(_home, 'Library', 'LaunchAgents', '$oldBundleId.plist'));
        if (!await plist.exists()) return false;
        await plist.delete();
        return true;
      }
      if (_isWindows) {
        const key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
        if ((await _run('reg', ['query', key, '/v', oldAppName])).exitCode != 0) return false;
        await _run('reg', ['delete', key, '/v', oldAppName, '/f']);
        return true;
      }
    } on Object {
      // 로그인 항목을 못 옮기면 사용자가 설정에서 다시 켜면 된다.
    }
    return false;
  }
}
