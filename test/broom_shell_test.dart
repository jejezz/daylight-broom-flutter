import 'dart:io';

import 'package:daylight_broom/engine/history.dart';
import 'package:daylight_broom/engine/tidy_engine.dart';
import 'package:daylight_broom/engine/tidy_service.dart';
import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/rules/rule.dart';
import 'package:daylight_broom/rules/rule_store.dart';
import 'package:daylight_broom/settings/app_settings.dart';
import 'package:daylight_broom/system/login_item.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:daylight_broom/theme/broom_style.dart';
import 'package:daylight_broom/ui/broom/buttons.dart';
import 'package:daylight_broom/ui/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory root;
  late TidyService service;
  late AppSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await AppSettings.load();
    root = Directory.systemTemp.createTempSync('daylight_broom_shell_');
    final support = Directory('${root.path}/DaylightBroom');
    service = TidyService(engine: TidyEngine(), ruleStore: RuleStore(support), historyStore: HistoryStore(support));
    await service.init();
    await service.engine.stop();
    await service.saveRule(Rule(
      id: 'r1',
      name: '이미지',
      watchedFolder: '${root.path}/in',
      condition: const RuleCondition(extensions: ['png']),
      action: const TrashAction(),
    ));
  });
  tearDown(() async {
    await service.engine.dispose();
    root.deleteSync(recursive: true);
  });

  Widget host({required ThemeMode mode, required VoidCallback onAbout}) => AppSettingsScope(
        settings: settings,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BroomShell(onAbout: onAbout, service: service, loginItem: LoginItemController(null)),
        ),
      );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('레일과 자동 정리 화면이 ${mode.name} 테마에서 그려진다', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var about = 0;
      await tester.pumpWidget(host(mode: mode, onAbout: () => about++));
      await tester.pump();

      expect(find.text('자동 정리'), findsOneWidget); // 레일 항목
      expect(find.byType(GradientButton), findsOneWidget); // 지금 정리
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('정보'));
      expect(about, 1);

      final style = Theme.of(tester.element(find.byType(BroomShell))).extension<BroomStyle>()!;
      expect(style.glowScale, mode == ThemeMode.dark ? 1 : lessThan(1));
    });
  }

  test('BroomStyle.lerp는 양 끝에서 각 테마 값과 같다', () {
    expect(BroomStyle.dark.lerp(BroomStyle.light, 0).glowScale, BroomStyle.dark.glowScale);
    expect(BroomStyle.dark.lerp(BroomStyle.light, 1).border, BroomStyle.light.border);
  });
}
