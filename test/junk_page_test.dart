import 'dart:io';

import 'package:daylight_broom/cleaner/folder_sizer.dart';
import 'package:daylight_broom/cleaner/junk_controller.dart';
import 'package:daylight_broom/cleaner/scan_target.dart';
import 'package:daylight_broom/cleaner/scanner.dart';
import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:daylight_broom/ui/junk_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _WalkSizer implements FolderSizer {
  @override
  Future<SizeResult> measure(List<String> paths) async {
    final (bytes, restricted) = walkSizes(paths);
    return SizeResult(bytes, restricted);
  }
}

void main() {
  late Directory home;
  late JunkController controller;

  setUp(() {
    home = Directory.systemTemp.createTempSync('daylight_broom_junk_ui_');
    for (final (rel, n) in [('c/cache1/f', 1000), ('c/cache2/f', 2000), ('r/archive/f', 4000)]) {
      File('${home.path}/$rel')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(n, 1));
    }
    controller = JunkController(
      scanner: JunkScanner(
        platform: CleanerPlatform.macos,
        env: {'HOME': home.path},
        sizer: _WalkSizer(),
        targetsOverride: [
          ScanTarget(id: 'user_caches', group: TargetGroup.system, safety: Safety.safe, paths: {CleanerPlatform.macos: ['~/c']}),
          ScanTarget(id: 'xcode_archives', group: TargetGroup.developer, safety: Safety.review, paths: {CleanerPlatform.macos: ['~/r']}),
        ],
      ),
    );
  });
  tearDown(() {
    controller.dispose();
    home.deleteSync(recursive: true);
  });

  Widget host(ThemeMode mode) => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: JunkPage(controller: controller)),
      );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('스캔 → 확인 창 → 영구 삭제 (${mode.name})', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(mode));
      expect(find.text('Scan'), findsOneWidget);

      await tester.runAsync(controller.scan);
      await tester.pump();
      expect(find.text('User Caches'), findsOneWidget);
      expect(find.text('Xcode Archives'), findsOneWidget);
      expect(find.text('2 selected · 3.0 KB'), findsOneWidget); // 안전한 것만 미리 선택

      await tester.tap(find.text('Clean selected'));
      await tester.pumpAndSettle();
      expect(find.text('Delete permanently?'), findsOneWidget);

      // 취소하면 아무것도 지워지지 않는다.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(Directory('${home.path}/c/cache1').existsSync(), isTrue);

      await tester.tap(find.text('Clean selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pump();
      // 삭제는 실제 파일 I/O 라서, 실제 시간을 흘려 주고 가짜 시간의 마이크로태스크를 비우기를 반복한다.
      for (var i = 0; i < 20 && controller.lastFreed == null; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(Directory('${home.path}/c/cache1').existsSync(), isFalse);
      expect(Directory('${home.path}/r/archive').existsSync(), isTrue);
      expect(find.text('Freed 3.0 KB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('확인이 필요한 항목을 고르면 확인 창이 이름을 알린다', (tester) async {
    tester.view.physicalSize = const Size(960, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(ThemeMode.dark));
    await tester.runAsync(controller.scan);
    controller.toggle('${home.path}/r/archive', true);
    await tester.pump();
    await tester.tap(find.text('Clean selected'));
    await tester.pumpAndSettle();
    expect(find.textContaining('archive'), findsWidgets);
    expect(find.textContaining('closer look'), findsOneWidget);
  });
}
