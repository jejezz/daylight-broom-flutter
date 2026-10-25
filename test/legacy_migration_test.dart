import 'dart:io';

import 'package:daylight_broom/system/legacy_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory home;
  late LegacyMigration migration;

  setUp(() {
    home = Directory.systemTemp.createTempSync('daylight_broom_migration_');
    migration = LegacyMigration(env: {'HOME': home.path}, isMac: true, isWindows: false);
  });
  tearDown(() => home.deleteSync(recursive: true));

  File legacyFile(String name) => File('${home.path}/Library/Application Support/Stevedore/$name');

  group('설정 폴더', () {
    test('옛 폴더의 규칙·기록을 새 폴더로 복사하고 옛 것은 남긴다', () async {
      legacyFile('rules.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"rules":[]}');
      legacyFile('history.json').writeAsStringSync('{"entries":[]}');
      final target = Directory('${home.path}/Library/Application Support/DaylightBroom');

      await migration.migrateFiles(target);

      expect(File('${target.path}/rules.json').readAsStringSync(), '{"rules":[]}');
      expect(File('${target.path}/history.json').existsSync(), isTrue);
      expect(legacyFile('rules.json').existsSync(), isTrue);
    });

    test('새 폴더에 이미 내용이 있으면 덮어쓰지 않는다', () async {
      legacyFile('rules.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('old');
      final target = Directory('${home.path}/new')..createSync();
      File('${target.path}/rules.json').writeAsStringSync('mine');

      await migration.migrateFiles(target);

      expect(File('${target.path}/rules.json').readAsStringSync(), 'mine');
    });

    test('옛 폴더가 없으면 아무것도 만들지 않는다', () async {
      final target = Directory('${home.path}/new');
      await migration.migrateFiles(target);
      expect(target.existsSync(), isFalse);
    });
  });

  group('로그인 항목', () {
    test('옛 LaunchAgent가 있으면 지우고 true', () async {
      final plist = File('${home.path}/Library/LaunchAgents/art.zoomon.stevedore.plist')..createSync(recursive: true);
      expect(await migration.removeLegacyLoginItem(), isTrue);
      expect(plist.existsSync(), isFalse);
    });

    test('없으면 false', () async {
      expect(await migration.removeLegacyLoginItem(), isFalse);
    });

    test('Windows는 옛 Run 값을 지운다', () async {
      final calls = <List<String>>[];
      final win = LegacyMigration(
        env: {'APPDATA': r'C:\Users\a\AppData\Roaming'},
        isMac: false,
        isWindows: true,
        run: (exe, args) async {
          calls.add(args);
          return ProcessResult(0, 0, '', '');
        },
      );
      expect(await win.removeLegacyLoginItem(), isTrue);
      expect(calls.last, containsAll(['delete', 'Stevedore']));
    });
  });

  test('저장 값은 새 키가 비어 있을 때만 옮긴다', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final prefs = await SharedPreferences.getInstance();
    final plist = File('${home.path}/Library/Preferences/art.zoomon.stevedore.plist')..createSync(recursive: true);
    plist.writeAsStringSync('stub');
    final m = LegacyMigration(
      env: {'HOME': home.path},
      isMac: true,
      isWindows: false,
      run: (exe, args) async =>
          ProcessResult(0, 0, '{"flutter.theme_mode":"dark","flutter.app_locale":"ko","flutter.remove_empty_folders":true}', ''),
    );

    await m.migratePreferences(prefs);

    expect(prefs.getString('theme_mode'), 'light');
    expect(prefs.getString('app_locale'), 'ko');
    expect(prefs.getBool('remove_empty_folders'), isTrue);
  });
}
