// README 스크린샷을 만든다 (conventions/readme-guide.md §4). 실제 앱 창을 캡처하는 대신
// 위젯 테스트로 화면을 그리므로, 사용자의 실제 폴더·앱 이름이 이미지에 들어가지 않고 해마다 같은 결과가 나온다.
//
//   flutter test tool/screenshots/capture_test.dart
//   python3 tool/readme/frame.py docs/screenshots/raw/overview-dark.png ...   # 다듬기
//
// 결과: docs/screenshots/raw/{overview,junk,rules}-{light,dark}.png (영어 UI, 960×640 @2x).
// 앱 코드는 건드리지 않고, 보여 줄 데이터만 이 파일에서 꾸민다.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:daylight_broom/cleaner/disk_info.dart';
import 'package:daylight_broom/cleaner/folder_sizer.dart';
import 'package:daylight_broom/cleaner/junk_controller.dart';
import 'package:daylight_broom/cleaner/scan_target.dart';
import 'package:daylight_broom/cleaner/scanner.dart';
import 'package:daylight_broom/engine/history.dart';
import 'package:daylight_broom/engine/tidy_engine.dart';
import 'package:daylight_broom/engine/tidy_service.dart';
import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/rules/rule.dart';
import 'package:daylight_broom/rules/rule_store.dart';
import 'package:daylight_broom/settings/app_settings.dart';
import 'package:daylight_broom/system/login_item.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:daylight_broom/ui/shell.dart';
import 'package:daylight_broom/uninstaller/app_scanner.dart';
import 'package:daylight_broom/uninstaller/app_trasher.dart';
import 'package:daylight_broom/uninstaller/apps_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 폴더 이름으로 크기를 정해 준다 (실제로 재지 않는다).
class _FixedSizer implements FolderSizer {
  _FixedSizer(this.sizes);

  final Map<String, int> sizes;

  @override
  Future<SizeResult> measure(List<String> paths) async =>
      SizeResult({for (final p in paths) p: sizes[p.split('/').last] ?? 0});
}

class _SampleDisk extends DiskInfo {
  @override
  Future<VolumeInfo?> volume() async => const VolumeInfo(total: 494000000000, free: 183000000000);

  @override
  Future<bool?> hasFullDiskAccess() async => true;
}

class _NoApps implements AppInfoReader {
  @override
  Future<({String? bundleId, String? name, String? version})?> read(String appPath) async => null;
}

class _NoTrash implements AppTrasher {
  @override
  Future<Map<String, String>> trash(List<String> paths) async => {};
}

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  Future<ByteData> bytes(String path) async => ByteData.view((await File(path).readAsBytes()).buffer);
  final app = FontLoader('SeoulNamsan');
  for (final f in ['regular', 'bold', 'extra_bold']) {
    app.addFont(bytes('assets/fonts/seoul_namsan_$f.ttf'));
  }
  await app.load();
  await (FontLoader('MaterialIcons')..addFont(bytes('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'))).load();
}

void main() {
  late Directory root;
  late TidyService service;
  late JunkController junk;
  late AppSettings settings;

  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    settings = await AppSettings.load();
    root = Directory.systemTemp.createTempSync('daylight_broom_shots_');
    for (final d in [
      'cache/Google', 'cache/Slack', 'cache/Spotify', 'cache/com.figma.Desktop',
      'dd/App-hkmefas', 'dd/SDKPrecompiled', 'dev/gradle', 'dev/npm', 'dev/pip', 'sim/iPhone 16', 'sim/iPad Air',
    ]) {
      Directory('${root.path}/$d').createSync(recursive: true);
    }
    const gb = 1000000000, mb = 1000000;
    final sizer = _FixedSizer({
      'Google': 1400 * mb, 'Slack': 820 * mb, 'Spotify': 540 * mb, 'com.figma.Desktop': 210 * mb,
      'App-hkmefas': 2300 * mb, 'SDKPrecompiled': 480 * mb, 'gradle': 3600 * mb, 'npm': 910 * mb, 'pip': 160 * mb,
      'iPhone 16': 3700 * mb, 'iPad Air': (2.4 * gb).round(),
    });
    ScanTarget t(String id, TargetGroup g, Safety s, String dir, {bool children = true}) =>
        ScanTarget(id: id, group: g, safety: s, paths: {CleanerPlatform.macos: ['~/$dir']}, listChildren: children);
    junk = JunkController(
      scanner: JunkScanner(
        platform: CleanerPlatform.macos,
        env: {'HOME': root.path},
        sizer: sizer,
        targetsOverride: [
          t('user_caches', TargetGroup.system, Safety.safe, 'cache'),
          t('xcode_derived', TargetGroup.developer, Safety.rebuild, 'dd'),
          t('gradle', TargetGroup.developer, Safety.rebuild, 'dev/gradle', children: false),
          t('npm', TargetGroup.developer, Safety.rebuild, 'dev/npm', children: false),
          t('pip', TargetGroup.developer, Safety.rebuild, 'dev/pip', children: false),
          t('simulators', TargetGroup.developer, Safety.review, 'sim'),
        ],
      ),
    );
    final support = Directory('${root.path}/DaylightBroom');
    service = TidyService(engine: TidyEngine(), ruleStore: RuleStore(support), historyStore: HistoryStore(support));
    await service.init();
    await service.engine.stop();
    Rule rule(String id, String name, List<String> ext, RuleAction action) => Rule(
          id: id,
          name: name,
          watchedFolder: '~/Downloads',
          condition: RuleCondition(extensions: ext),
          action: action,
        );
    await service.saveRule(rule('1', 'Documents', ['pdf', 'docx', 'xlsx'], const MoveAction('~/Documents/Downloads')));
    await service.saveRule(rule('2', 'Images', ['png', 'jpg', 'heic'], const MoveAction('~/Pictures/Downloads')));
    await service.saveRule(rule('3', 'Installers', ['dmg', 'pkg'], const MoveAction('~/Documents/Installers')));
    await service.saveRule(Rule(
      id: '4',
      name: 'Old archives',
      watchedFolder: '~/Downloads',
      condition: const RuleCondition(extensions: ['zip', 'tar.gz'], olderThanDays: 30),
      action: const TrashAction(),
    ));
    final now = DateTime(2026, 10, 25, 11, 40);
    HistoryEntry moved(String file, String rule, String dest, int minutesAgo) => HistoryEntry(
          id: 'm$minutesAgo',
          time: now.subtract(Duration(minutes: minutesAgo)),
          ruleId: '1',
          ruleName: rule,
          kind: HistoryKind.move,
          fileName: file,
          sourcePath: '/Users/me/Downloads/$file',
          resultPath: '$dest/$file',
        );
    await service.recordActivity(moved('invoice-october.pdf', 'Documents', '/Users/me/Documents/Downloads', 52));
    await service.recordActivity(moved('screenshot.png', 'Images', '/Users/me/Pictures/Downloads', 31));
    await service.recordActivity(HistoryEntry(
      id: 'u1',
      time: now.subtract(const Duration(minutes: 12)),
      ruleId: 'uninstall',
      ruleName: 'Zoom',
      kind: HistoryKind.uninstall,
      fileName: 'Zoom',
      sourcePath: '/Applications/zoom.us.app',
      bytes: 612000000,
      count: 4,
    ));
    await service.recordActivity(HistoryEntry(
      id: 'j1',
      time: now.subtract(const Duration(minutes: 5)),
      ruleId: 'junk',
      ruleName: 'junk',
      kind: HistoryKind.junk,
      fileName: 'Google',
      sourcePath: '/Users/me/Library/Caches/Google',
      bytes: 4200000000,
      count: 9,
    ));
  });
  tearDown(() async {
    junk.dispose();
    await service.engine.dispose();
    root.deleteSync(recursive: true);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final page in ['overview', 'junk', 'rules']) {
      testWidgets('$page (${mode.name})', (tester) async {
        await tester.runAsync(_loadFonts);
        tester.view.physicalSize = const Size(1920, 1280);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: AppSettingsScope(
            settings: settings,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: mode,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: BroomShell(
                onAbout: () {},
                service: service,
                loginItem: LoginItemController(null),
                junk: junk,
                disk: DiskController(_SampleDisk()),
                apps: AppsController(
                  scanner: AppScanner(reader: _NoApps(), appDirsOverride: const []),
                  trasher: _NoTrash(),
                ),
              ),
            ),
          ),
        ));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();

        if (page != 'overview') {
          await tester.tap(find.text(page == 'junk' ? 'Junk' : 'Auto tidy').first);
          await tester.pump();
        }
        if (page == 'junk' || page == 'overview') {
          await tester.runAsync(junk.scan);
          await tester.pump();
        }
        // 링 애니메이션이 끝나도록 충분히 돌린다.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final out = File('docs/screenshots/raw/$page-${mode.name}.png')..createSync(recursive: true);
          out.writeAsBytesSync(data!.buffer.asUint8List());
        });
      });
    }
  }
}
