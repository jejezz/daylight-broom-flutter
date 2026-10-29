import 'package:daylight_broom/cleaner/disk_info.dart';
import 'package:daylight_broom/diskusage/file_category.dart';
import 'package:daylight_broom/diskusage/usage_controller.dart';
import 'package:daylight_broom/diskusage/usage_model.dart';
import 'package:daylight_broom/engine/file_ops.dart';
import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:daylight_broom/ui/storage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDisk extends DiskInfo {
  _FakeDisk(this.list, {this.onReveal});

  final List<DiskVolume> list;
  final void Function(String)? onReveal;

  @override
  Future<List<DiskVolume>> volumes() async => list;

  @override
  Future<bool?> hasFullDiskAccess() async => null;

  @override
  Future<void> reveal(String path) async => onReveal?.call(path);
}

DiskUsage _sample() {
  final dirs = [for (var i = 0; i < FileCategory.values.length; i++) <String, int>{}];
  dirs[FileCategory.video.index].addAll({'/r/Movies/a': 6000, '/r/Movies/b': 3000, '/r/Downloads': 1000});
  dirs[FileCategory.documents.index]['/r/Docs'] = 500;
  return DiskUsage(
    root: '/r',
    separator: '/',
    scannedAt: DateTime(2026, 1, 2, 3, 4),
    fileCounts: [0, 5, 0, 9, 0],
    dirs: dirs,
    topFiles: [
      for (final c in FileCategory.values)
        c == FileCategory.video ? [const UsageFile('/r/Movies/a/big.mp4', 6000)] : <UsageFile>[],
    ],
    unreadable: 2,
  );
}

void main() {
  testWidgets('디스크 → 종류 → 폴더로 내려가고 경로로 되돌아온다', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final revealed = <String>[];
    final disk = DiskController(_FakeDisk(
      const [DiskVolume(name: 'Mac', path: '/r', isSystem: true, total: 100000, free: 50000)],
      onReveal: revealed.add,
    ));
    await tester.runAsync(disk.refresh);
    final usage = UsageController();
    usage.of('/r')
      ..result = _sample()
      ..status = UsageStatus.done;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StoragePage(disk: disk, usage: usage)),
    ));
    await tester.pump();

    // 1단계: 종류별.
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('10.0 KB'), findsOneWidget);
    expect(find.text('9 files'), findsOneWidget);
    expect(find.textContaining('2 items could not be read'), findsOneWidget);

    // 2단계: 비디오 안의 폴더들, 큰 것부터.
    await tester.tap(find.text('Video').first);
    await tester.pump();
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('big.mp4'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Movies')).dy, lessThan(tester.getTopLeft(find.text('Downloads')).dy));

    // 3단계: Movies 안.
    await tester.tap(find.text('Movies'));
    await tester.pump();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('Downloads'), findsNothing);
    expect(find.text('Largest files'), findsNothing); // 가장 큰 파일은 종류 첫 화면에서만

    // 경로의 "Video"를 누르면 종류 첫 화면으로.
    await tester.tap(find.text('Video').first);
    await tester.pump();
    expect(find.text('Downloads'), findsOneWidget);

    // 위치 열기.
    await tester.tap(find.byTooltip('Show in folder').first);
    expect(revealed, ['/r/Movies']);

    // 디스크 이름을 누르면 처음으로.
    await tester.tap(find.text('Mac').first);
    await tester.pump();
    expect(find.text('Documents'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('분석 전에는 안내와 시작 단추, 분석 중에는 진행과 취소', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final disk = DiskController(_FakeDisk(const [DiskVolume(name: 'Mac', path: '/r', isSystem: true, total: 100, free: 50)]));
    await tester.runAsync(disk.refresh);
    final usage = UsageController();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StoragePage(disk: disk, usage: usage)),
    ));
    await tester.pump();
    expect(find.text('Analyze'), findsOneWidget);
    expect(find.textContaining('Scans the disk once'), findsOneWidget);

    usage.of('/r')
      ..status = UsageStatus.scanning
      ..progress = const UsageProgress(files: 1234, bytes: 5000000, currentDir: '/r/x');
    usage.notifyListeners();
    await tester.pump();
    expect(find.text('Analyzing… 1234 files · 5.0 MB'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Analyze'), findsNothing);
  });

  testWidgets('폴더 삭제는 확인 창을 거쳐 휴지통으로 가고, 취소하면 아무 일도 없다', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final disk = DiskController(_FakeDisk(const [DiskVolume(name: 'Mac', path: '/r', isSystem: true, total: 100000, free: 50000)]));
    await tester.runAsync(disk.refresh);
    final trashed = <String>[];
    final usage = UsageController(ops: _RecordingOps(trashed));
    usage.of('/r')
      ..result = _sample()
      ..status = UsageStatus.done;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StoragePage(disk: disk, usage: usage)),
    ));
    await tester.pump();
    await tester.tap(find.text('Video').first);
    await tester.pump();

    // 취소.
    await tester.tap(find.byTooltip('Move to Trash').first); // Movies (가장 큼)
    await tester.pumpAndSettle();
    expect(find.text('Move to the Trash?'), findsOneWidget);
    expect(find.textContaining('Everything in this folder'), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.textContaining('/r/Movies')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(trashed, isEmpty);
    expect(find.text('Movies'), findsOneWidget);

    // 확인.
    await tester.tap(find.byTooltip('Move to Trash').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Move to Trash'));
    await tester.pumpAndSettle();
    expect(trashed, ['/r/Movies']);
    expect(find.text('Movies'), findsNothing);
    expect(find.text('Downloads'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RecordingOps implements FileOps {
  _RecordingOps(this.trashed);

  final List<String> trashed;

  @override
  Future<String?> trash(String path) async {
    trashed.add(path);
    return null;
  }

  @override
  Future<String> move(String src, String destDir, {String? asName}) => throw UnimplementedError();
}
