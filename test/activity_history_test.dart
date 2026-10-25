import 'dart:io';

import 'package:daylight_broom/cleaner/folder_sizer.dart';
import 'package:daylight_broom/cleaner/junk_controller.dart';
import 'package:daylight_broom/cleaner/scan_target.dart';
import 'package:daylight_broom/cleaner/scanner.dart';
import 'package:daylight_broom/engine/history.dart';
import 'package:daylight_broom/engine/tidy_engine.dart';
import 'package:daylight_broom/engine/tidy_service.dart';
import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/rules/rule_store.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:daylight_broom/ui/history_list.dart';
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
      (bundleId: 'com.spotify.client', name: 'Spotify', version: '1');
}

class _Trash implements AppTrasher {
  _Trash({this.failAll = false});

  final bool failAll;

  @override
  Future<Map<String, String>> trash(List<String> paths) async => failAll ? {for (final p in paths) p: 'denied'} : {};
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('daylight_broom_activity_'));
  tearDown(() => root.deleteSync(recursive: true));

  void file(String rel, int n) => File('${root.path}/$rel')
    ..createSync(recursive: true)
    ..writeAsBytesSync(List.filled(n, 1));

  HistoryEntry junk() => HistoryEntry(
        id: 'j1',
        time: DateTime(2026, 10, 25, 11, 30),
        ruleId: 'junk',
        ruleName: 'junk',
        kind: HistoryKind.junk,
        fileName: 'Naver',
        sourcePath: '/x/Naver',
        bytes: 5000,
        count: 3,
      );

  test('정크·앱 제거 기록은 용량과 항목 수까지 JSON 으로 왕복하고, 되돌릴 수는 없다', () {
    final back = HistoryEntry.fromJson(junk().toJson());
    expect((back.kind, back.bytes, back.count), (HistoryKind.junk, 5000, 3));
    expect(back.canUndo, isFalse);
    expect(back.withRestored('/y').bytes, 5000);
  });

  test('옛 기록(용량·항목 수 필드 없음)도 그대로 읽는다', () {
    final old = HistoryEntry.fromJson({
      'id': 'a',
      'time': '2026-10-01T10:00:00.000',
      'ruleId': 'r',
      'ruleName': '이미지',
      'kind': 'move',
      'fileName': 'a.png',
      'sourcePath': '/d/a.png',
      'resultPath': '/p/a.png',
    });
    expect((old.bytes, old.count, old.canUndo), (null, null, true));
  });

  test('recordActivity 는 규칙 정리 기록과 같은 파일에 저장되고 다시 불러온다', () async {
    final support = Directory('${root.path}/DaylightBroom');
    final service = TidyService(engine: TidyEngine(), ruleStore: RuleStore(support), historyStore: HistoryStore(support));
    await service.init();
    await service.engine.stop();
    await service.recordActivity(junk());
    expect(service.history.first.kind, HistoryKind.junk);
    expect((await HistoryStore(support).load()).single.id, 'j1');
    await service.engine.dispose();
  });

  test('정크 정리는 한 번에 한 줄, 지운 것이 없으면 남기지 않는다', () async {
    file('c/a/f', 1000);
    file('c/b/f', 2000);
    final recorded = <HistoryEntry>[];
    final c = JunkController(
      scanner: JunkScanner(
        platform: CleanerPlatform.macos,
        env: {'HOME': root.path},
        sizer: _WalkSizer(),
        targetsOverride: [
          ScanTarget(id: 'user_caches', group: TargetGroup.system, safety: Safety.safe, paths: {CleanerPlatform.macos: ['~/c']}),
        ],
      ),
      onRecord: recorded.add,
    );
    await c.scan();
    await c.cleanSelected();
    expect(recorded.length, 1);
    expect((recorded.single.kind, recorded.single.count, recorded.single.bytes), (HistoryKind.junk, 2, 3000));
    expect(recorded.single.canUndo, isFalse);

    await c.scan(); // 비었다
    await c.cleanSelected();
    expect(recorded.length, 1);
    c.dispose();
  });

  test('앱 제거는 옮긴 것이 있을 때만 앱 이름으로 남긴다', () async {
    file('Applications/Spotify.app/Contents/MacOS/x', 5000);
    file('Library/Caches/com.spotify.client/a', 700);
    AppsController make(AppTrasher t, List<HistoryEntry> out) => AppsController(
          scanner: AppScanner(reader: _Reader(), sizer: _WalkSizer(), env: {'HOME': root.path}, appDirsOverride: ['${root.path}/Applications']),
          trasher: t,
          onRecord: out.add,
        );

    final failedOut = <HistoryEntry>[];
    final bad = make(_Trash(failAll: true), failedOut);
    await bad.load();
    await bad.select(bad.apps.single);
    await bad.uninstall();
    expect(failedOut, isEmpty);
    bad.dispose();

    final out = <HistoryEntry>[];
    final good = make(_Trash(), out);
    await good.load();
    await good.select(good.apps.single);
    await good.uninstall();
    expect((out.single.kind, out.single.fileName, out.single.count, out.single.bytes), (HistoryKind.uninstall, 'Spotify', 2, 5700));
    good.dispose();
  });

  testWidgets('이력 목록이 정크·앱 제거 기록을 알아보게 보여 준다', (tester) async {
    final uninstall = HistoryEntry(
      id: 'u1',
      time: DateTime(2026, 10, 25, 12),
      ruleId: 'uninstall',
      ruleName: 'Spotify',
      kind: HistoryKind.uninstall,
      fileName: 'Spotify',
      sourcePath: '/Applications/Spotify.app',
      bytes: 5700,
      count: 2,
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: HistoryList(entries: [uninstall, junk()], onUndo: (_) {})),
    ));
    expect(find.text('Uninstalled Spotify'), findsOneWidget);
    expect(find.textContaining('Moved to Trash · 2 items · 5.7 KB'), findsOneWidget);
    expect(find.text('Cleaned 3 junk items'), findsOneWidget);
    expect(find.textContaining('Deleted permanently · 5.0 KB'), findsOneWidget);
    expect(find.text('Undo'), findsNothing); // 되돌리기 단추가 없다
  });
}
