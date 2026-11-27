import 'dart:async';
import 'dart:io';

import 'package:daylight_broom/cleaner/disk_info.dart';
import 'package:daylight_broom/duplicates/duplicate_controller.dart';
import 'package:daylight_broom/duplicates/duplicate_scanner.dart';
import 'package:daylight_broom/engine/file_ops.dart';
import 'package:daylight_broom/engine/history.dart';
import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:daylight_broom/ui/broom/buttons.dart';
import 'package:daylight_broom/ui/duplicates_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _Ops implements FileOps {
  final trashed = <String>[];
  final failOn = <String>{};

  @override
  Future<String> move(String src, String destDir, {String? asName}) => throw UnimplementedError();

  @override
  Future<String?> trash(String path) async {
    if (failOn.contains(path)) throw const FileSystemException('busy');
    trashed.add(path);
    return null;
  }
}

class _Disk extends DiskInfo {
  final revealed = <String>[];

  @override
  Future<void> reveal(String path) async => revealed.add(path);
}

/// 손으로 조종하는 찾기: 진행·묶음을 원하는 때에 보내고, 정지를 기록한다.
class _FakeScan {
  late void Function(DuplicateProgress) progress;
  late void Function(DuplicateGroup) group;
  final done = Completer<DuplicateScanResult?>();
  var cancelled = 0;

  Future<DuplicateScanHandle> start(String root, void Function(DuplicateProgress) onProgress, void Function(DuplicateGroup) onGroup) async {
    progress = onProgress;
    group = onGroup;
    return DuplicateScanHandle(done.future, onCancel: () {
      cancelled++;
      if (!done.isCompleted) done.complete(null);
    });
  }
}

DuplicateGroup _group(String hash, int bytes, List<String> paths) => DuplicateGroup(
      hash: hash,
      bytes: bytes,
      files: [for (var i = 0; i < paths.length; i++) DuplicateFile(path: paths[i], bytes: bytes, modified: DateTime(2026, 1, i + 1))],
    );

void main() {
  group('runDuplicateScan', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('daylight_broom_dup_'));
    tearDown(() => root.deleteSync(recursive: true));

    void write(String rel, List<int> bytes) {
      final f = File(p.join(root.path, rel));
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(bytes);
    }

    test('내용이 같은 파일만 묶고, 크기만 같거나 뒷부분만 다른 파일은 뺀다', () async {
      final big = List<int>.generate(200 * 1024, (i) => i % 251);
      final bigOther = [...big]..[big.length - 1] ^= 1; // 앞부분 64KB 는 같고 끝 1바이트만 다르다
      write('a/photo.jpg', big);
      write('b/photo copy.jpg', big);
      write('c/다른이름.bin', big);
      write('d/almost.jpg', bigOther);
      write('x.txt', 'hello'.codeUnits);
      write('sub/y.txt', 'hello'.codeUnits);
      write('z.txt', 'world'.codeUnits); // 크기는 같고 내용이 다르다
      write('empty1', []);
      write('empty2', []);
      write('.hidden/copy.txt', 'hello'.codeUnits); // 숨김 폴더는 보지 않는다
      write('Some.app/Contents/x.txt', 'hello'.codeUnits); // 패키지 안은 보지 않는다
      write('dl.crdownload', 'hello'.codeUnits); // 다운로드 중인 파일

      final found = <DuplicateGroup>[];
      final progress = <DuplicateProgress>[];
      final r = await runDuplicateScan(root.path, onGroup: found.add, onProgress: progress.add);

      expect(r, isNotNull);
      expect(r!.groups, hasLength(2));
      expect(found, hasLength(2)); // 찾는 대로 알렸다
      final bigGroup = r.groups.first; // 확보 용량이 큰 것부터
      expect(bigGroup.files.map((f) => p.basename(f.path)), unorderedEquals(['photo.jpg', 'photo copy.jpg', '다른이름.bin']));
      expect(bigGroup.wastedBytes, big.length * 2);
      expect(r.groups[1].files.map((f) => p.basename(f.path)), unorderedEquals(['x.txt', 'y.txt']));
      expect(progress.last.done, progress.last.total);
      expect(progress.any((x) => x.current.isNotEmpty), isTrue);
    });

    test('취소하면 null', () async {
      write('a.txt', 'same'.codeUnits);
      write('b.txt', 'same'.codeUnits);
      expect(await runDuplicateScan(root.path, isCancelled: () => true), isNull);
    });

    test('isolate 에서 돌려도 같은 결과를 받는다', () async {
      write('a.txt', 'same'.codeUnits);
      write('b/c.txt', 'same'.codeUnits);
      final groups = <DuplicateGroup>[];
      final handle = await startDuplicateScan(root.path, onGroup: groups.add);
      final r = await handle.result;
      expect(r!.groups.single.files, hasLength(2));
      expect(groups, hasLength(1));
    });
  });

  group('DuplicateController', () {
    test('찾는 대로 목록에 붙고, 정지하면 찾은 것을 남긴다', () async {
      final fake = _FakeScan();
      final c = DuplicateController(starter: fake.start, ops: _Ops());
      final scanning = c.scan('/r');
      await Future<void>.delayed(Duration.zero);
      expect(c.scanning, isTrue);
      fake.progress(const DuplicateProgress(phase: DuplicatePhase.hashing, files: 10, done: 5, total: 20, current: '/r/a'));
      fake.group(_group('h1', 100, ['/r/a', '/r/b']));
      expect(c.groups, hasLength(1));
      expect(c.progress!.current, '/r/a');
      c.cancel();
      await scanning;
      expect(fake.cancelled, 1);
      expect(c.status, DuplicateStatus.cancelled);
      expect(c.groups, hasLength(1));
    });

    test('묶음마다 하나는 남긴다: 마지막 하나는 고를 수 없다', () async {
      final fake = _FakeScan();
      final c = DuplicateController(starter: fake.start, ops: _Ops());
      final scanning = c.scan('/r');
      await Future<void>.delayed(Duration.zero);
      final g = _group('h', 10, ['/r/a', '/r/b', '/r/c']);
      fake.group(g);
      fake.done.complete(DuplicateScanResult(root: '/r', groups: [g], scannedFiles: 3, unreadable: 0));
      await scanning;

      c.toggle(g, '/r/a', true);
      c.toggle(g, '/r/b', true);
      c.toggle(g, '/r/c', true);
      expect(c.selected, {'/r/a', '/r/b'});
      expect(c.canSelect(g, '/r/c'), isFalse);

      c.selectAllButOldest();
      expect(c.selected, {'/r/b', '/r/c'});
    });

    test('고른 것과 파일 하나를 휴지통으로 보내고 이력에 남긴다', () async {
      final fake = _FakeScan();
      final ops = _Ops()..failOn.add('/r/q2');
      final records = <HistoryEntry>[];
      var changed = 0;
      final c = DuplicateController(starter: fake.start, ops: ops, onRecord: records.add, onChanged: () => changed++);
      final scanning = c.scan('/r');
      await Future<void>.delayed(Duration.zero);
      final g1 = _group('h1', 100, ['/r/a', '/r/b', '/r/c']);
      final g2 = _group('h2', 50, ['/r/q1', '/r/q2']);
      fake.group(g1);
      fake.group(g2);
      fake.done.complete(DuplicateScanResult(root: '/r', groups: [g1, g2], scannedFiles: 5, unreadable: 0));
      await scanning;

      c.selectAllButOldest();
      await c.trashSelected();
      expect(ops.trashed, ['/r/b', '/r/c']);
      expect(c.failedCount, 1);
      expect(c.lastMoved, 200);
      expect(c.groups.single.hash, 'h2'); // h1 은 하나만 남아 빠졌다
      expect(c.selected, {'/r/q2'}); // 실패한 것만 선택에 남는다
      expect(records.single.kind, HistoryKind.duplicates);
      expect(records.single.count, 2);
      expect(changed, 1);

      ops.failOn.clear();
      await c.trashOne('/r/q1');
      expect(ops.trashed.last, '/r/q1');
      expect(c.groups, isEmpty);
    });
  });

  testWidgets('찾는 중에 진행·현재 파일·정지 단추와 찾은 묶음이 보이고, 파일마다 열기·휴지통 단추가 있다', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = _FakeScan();
    final ops = _Ops();
    final disk = _Disk();
    final c = DuplicateController(starter: fake.start, ops: ops);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DuplicatesPage(controller: c, disk: disk, pickFolder: (_) async => '/r')),
    ));
    expect(find.text('폴더 고르기'), findsOneWidget);
    await tester.tap(find.text('폴더 고르기'));
    await tester.pump();

    fake.progress(const DuplicateProgress(phase: DuplicatePhase.hashing, files: 4, done: 50, total: 100, current: '/r/sub/a.jpg'));
    fake.group(_group('h', 10, ['/r/a.jpg', '/r/sub/a.jpg']));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('/r/sub/a.jpg'), findsOneWidget); // 지금 비교 중인 파일
    expect(find.text('정지'), findsOneWidget);
    expect(find.text('a.jpg'), findsWidgets); // 끝나기 전에 이미 목록에 있다

    await tester.tap(find.byTooltip(Platform.isWindows ? '탐색기에서 열기' : 'Finder에서 보기').last);
    expect(disk.revealed, ['/r/sub/a.jpg']);

    await tester.tap(find.text('정지'));
    await tester.pump();
    expect(c.status, DuplicateStatus.cancelled);
    expect(find.text('정지'), findsNothing);
    expect(find.byType(GradientButton), findsWidgets);

    await tester.tap(find.byTooltip('휴지통으로 보내기').last);
    await tester.pump();
    expect(ops.trashed, ['/r/sub/a.jpg']);
    expect(tester.takeException(), isNull);
  });
}
