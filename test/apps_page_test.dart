import 'dart:io';

import 'package:daylight_broom/cleaner/disk_info.dart';
import 'package:daylight_broom/cleaner/folder_sizer.dart';
import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:daylight_broom/ui/apps_page.dart';
import 'package:daylight_broom/uninstaller/app_scanner.dart';
import 'package:daylight_broom/uninstaller/app_trasher.dart';
import 'package:daylight_broom/uninstaller/apps_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _WalkSizer implements FolderSizer {
  @override
  Future<SizeResult> measure(List<String> paths) async {
    final (bytes, restricted) = walkSizes(paths);
    return SizeResult(bytes, restricted);
  }
}

class _Reader implements AppInfoReader {
  @override
  Future<({String? bundleId, String? name, String? version})?> read(String appPath) async =>
      (bundleId: 'com.spotify.client', name: 'Spotify', version: '1.2');
}

class _Trash implements AppTrasher {
  final List<String> trashed = [];

  @override
  Future<Map<String, String>> trash(List<String> paths) async {
    trashed.addAll(paths);
    return {};
  }
}

void main() {
  late Directory home;
  late _Trash trash;
  late AppsController controller;

  setUp(() {
    home = Directory.systemTemp.createTempSync('daylight_broom_apps_ui_');
    for (final (rel, n) in [
      ('Applications/Spotify.app/Contents/MacOS/x', 5000),
      ('Library/Caches/com.spotify.client/a', 700),
      ('Library/Application Support/Spotify/data', 900),
    ]) {
      File('${home.path}/$rel')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(n, 1));
    }
    trash = _Trash();
    controller = AppsController(
      scanner: AppScanner(
        reader: _Reader(),
        sizer: _WalkSizer(),
        env: {'HOME': home.path},
        appDirsOverride: ['${home.path}/Applications'],
      ),
      trasher: trash,
    );
  });
  tearDown(() {
    controller.dispose();
    home.deleteSync(recursive: true);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('목록 → 남은 파일(이름 일치는 미선택) → 확인 → 휴지통 (${mode.name})', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AppsPage(controller: controller, disk: DiskInfo(isMac: false, isWindows: false))),
      ));
      for (var i = 0; i < 20 && !controller.loaded; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }
      await tester.pump();
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('No installed apps found.'), findsNothing);

      await tester.tap(find.text('Spotify'));
      for (var i = 0; i < 20 && (controller.findingLeftovers || controller.selected == null); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }
      await tester.pump();
      expect(find.text('Leftovers in ~/Library · 2'), findsOneWidget);
      expect(find.text('NAME MATCH'), findsOneWidget);
      expect(find.text('5.7 KB to remove'), findsOneWidget); // 앱 + 번들 id 로 찾은 것만

      await tester.tap(find.text('Uninstall'));
      await tester.pumpAndSettle();
      expect(find.text('Uninstall Spotify?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(trash.trashed, isEmpty);

      await tester.tap(find.text('Uninstall'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to Trash'));
      for (var i = 0; i < 20 && trash.trashed.isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(trash.trashed.length, 2);
      expect(trash.trashed.last, endsWith('Spotify.app'));
      expect(find.text('Select an app to see its leftover files'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
