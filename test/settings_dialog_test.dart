import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/settings/app_settings.dart';
import 'package:daylight_broom/settings/settings_dialog.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await AppSettings.load();
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(960, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppSettingsScope(
      settings: settings,
      child: MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsDialog()),
      ),
    ));
  }

  testWidgets('외형 구역: 모드 → 색 구성 → 언어 → 글자 크기, 슬라이더로 배율을 바꾸고 기본값으로 되돌린다', (tester) async {
    await open(tester);
    final headings = ['모드', '색 구성', '언어', '글자 크기'];
    final ys = [for (final h in headings) tester.getTopLeft(find.text(h)).dy];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text('100%'), findsOneWidget);

    // 슬라이더 오른쪽 끝을 누르면 150%. 창 높이가 낮아 내려야 보인다.
    await tester.ensureVisible(find.byType(Slider));
    await tester.pumpAndSettle();
    final slider = tester.getRect(find.byType(Slider));
    await tester.tapAt(Offset(slider.right - 4, slider.center.dy));
    await tester.pumpAndSettle();
    expect(settings.textScale, 1.5);
    expect(find.text('150%'), findsWidgets);

    await tester.ensureVisible(find.text('기본값'));
    await tester.tap(find.text('기본값'));
    await tester.pumpAndSettle();
    expect(settings.textScale, 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('정리 구역에서 비게 된 폴더 지우기를 켜고 끈다', (tester) async {
    await open(tester);
    await tester.tap(find.text('정리'));
    await tester.pumpAndSettle();
    expect(find.text('파일을 옮긴 뒤 비게 된 폴더 지우기'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(settings.removeEmptyFolders, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(settings.removeEmptyFolders, isFalse);
  });

  testWidgets('글자 크기 150%에서도 설정 창이 넘치지 않는다', (tester) async {
    await settings.setTextScale(1.5);
    await open(tester);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(960, 640), textScaler: TextScaler.linear(1.5)),
      child: AppSettingsScope(
        settings: settings,
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsDialog()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
