import 'dart:io';

import 'package:daylight_broom/diskusage/file_category.dart';
import 'package:daylight_broom/diskusage/usage_cache.dart';
import 'package:daylight_broom/diskusage/usage_controller.dart';
import 'package:daylight_broom/diskusage/usage_model.dart';
import 'package:daylight_broom/diskusage/usage_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void _file(Directory root, String rel, int bytes) {
  File('${root.path}${Platform.pathSeparator}${rel.replaceAll('/', Platform.pathSeparator)}')
    ..createSync(recursive: true)
    ..writeAsBytesSync(List.filled(bytes, 1));
}

void main() {
  group('종류 분류', () {
    test('확장자로 문서·음악·비디오·기타를 나눈다', () {
      expect(categoryOfFile(r'C:\a\report.PDF'), FileCategory.documents);
      expect(categoryOfFile('/a/b/song.flac'), FileCategory.music);
      expect(categoryOfFile('/a/b/movie.mkv'), FileCategory.video);
      expect(categoryOfFile('/a/b/photo.jpg'), FileCategory.other);
      expect(categoryOfFile('/a/b/Makefile'), FileCategory.other);
      expect(categoryOfFile('/a/b/.pdf'), FileCategory.other); // 숨김 파일이지 확장자가 아니다
      expect(categoryOfFile(r'C:\dir.mp3\file'), FileCategory.other); // 폴더 이름의 점은 무시
    });

    test('어플리케이션 폴더는 OS 별 위치로 정한다', () {
      expect(isApplicationRoot(r'C:\Program Files', windows: true), isTrue);
      expect(isApplicationRoot(r'D:\program files (x86)', windows: true), isTrue);
      expect(isApplicationRoot(r'C:\Users\a\AppData\Local\Programs', windows: true), isTrue);
      expect(isApplicationRoot(r'C:\Program Files\Foo', windows: true), isFalse); // 위에서 이미 잡힌다
      expect(isApplicationRoot(r'C:\Windows', windows: true), isFalse);
      expect(isApplicationRoot('/Applications', windows: false), isTrue);
      expect(isApplicationRoot('/Users/a/Applications', windows: false), isTrue);
      expect(isApplicationRoot('/Applications/Foo.app', windows: false), isTrue);
      expect(isApplicationRoot('/Users/a/Documents', windows: false), isFalse);
    });
  });

  group('작은 폴더 합치기', () {
    test('작은 폴더는 상위로 올라가고, 합쳐진 결과도 작으면 더 위로 간다', () {
      final m = {
        '/r': 10,
        '/r/a': 100,
        '/r/a/b': 3,
        '/r/a/b/c': 2,
        '/r/x': 1,
      };
      rollUpSmallDirs(m, root: '/r', separator: '/', min: 50);
      expect(m, {'/r': 11, '/r/a': 105});
    });

    test('루트가 "/"나 "C:\\"여도 루트로 합친다', () {
      final m = {'/Users': 1, '/Users/a': 2};
      rollUpSmallDirs(m, root: '/', separator: '/', min: 10);
      expect(m, {'/': 3});
      final w = {r'C:\Users': 1, r'C:\Users\a': 2};
      rollUpSmallDirs(w, root: r'C:\', separator: r'\', min: 10);
      expect(w, {r'C:\': 3});
    });
  });

  group('스캔', () {
    late Directory root;
    late bool windows;
    late String sep;

    setUp(() {
      windows = Platform.isWindows;
      sep = windows ? r'\' : '/';
      root = Directory.systemTemp.createTempSync('daylight_broom_usage_');
      _file(root, 'docs/a.pdf', 1000);
      _file(root, 'docs/deep/b.docx', 500);
      _file(root, 'media/song.mp3', 2000);
      _file(root, 'media/clip.mp4', 4000);
      _file(root, 'media/cover.jpg', 300);
      _file(root, 'top.txt', 50);
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('종류별 합계와 폴더별 크기를 모은다', () async {
      final u = (await runUsageScan(root.path, windows: windows, minDirBytes: 0))!;
      expect(u.bytesOf(FileCategory.documents), 1550);
      expect(u.bytesOf(FileCategory.music), 2000);
      expect(u.bytesOf(FileCategory.video), 4000);
      expect(u.bytesOf(FileCategory.other), 300);
      expect(u.bytesOf(FileCategory.applications), 0);
      expect(u.totalBytes, 7850);
      expect(u.fileCounts[FileCategory.documents.index], 3);

      final kids = u.childrenOf(FileCategory.documents, root.path);
      expect(kids.map((d) => d.path), ['${root.path}${sep}docs']);
      expect(kids.single.bytes, 1500);
      expect(u.directBytes(FileCategory.documents, root.path), 50);
      expect(u.bytesUnder(FileCategory.documents, '${root.path}${sep}docs'), 1500);
      expect(u.childrenOf(FileCategory.documents, '${root.path}${sep}docs').single.bytes, 500);

      final big = u.topFiles[FileCategory.video.index].single;
      expect(big.bytes, 4000);
      expect(big.path, endsWith('clip.mp4'));
    });

    test('작은 폴더를 합쳐도 합계는 같다', () async {
      final u = (await runUsageScan(root.path, windows: windows, minDirBytes: 1000000))!;
      expect(u.totalBytes, 7850);
      expect(u.dirs[FileCategory.documents.index].keys, [root.path]);
    });

    test('.app 번들 안은 어플리케이션이다 (macOS 규칙)', () async {
      if (windows) return;
      _file(root, 'Foo.app/Contents/MacOS/foo', 800);
      _file(root, 'Foo.app/Contents/readme.pdf', 100);
      final u = (await runUsageScan(root.path, windows: false, minDirBytes: 0))!;
      expect(u.bytesOf(FileCategory.applications), 900);
    });

    test('취소하면 null', () async {
      final u = await runUsageScan(root.path, windows: windows, isCancelled: () => true);
      expect(u, isNull);
    });

    test('별도 isolate 에서 돌려 결과와 진행을 받는다', () async {
      final h = await startUsageScan(root.path, minDirBytes: 0);
      final u = await h.result;
      expect(u!.totalBytes, 7850);
    });

    test('컨트롤러는 상태를 바꾸고 동시에 하나만 훑는다', () async {
      final c = UsageController();
      addTearDown(c.dispose);
      final first = c.scan(root.path);
      expect(c.scanning, root.path);
      await c.scan('다른 디스크'); // 이미 훑는 중이면 무시
      expect(c.of('다른 디스크').status, UsageStatus.idle);
      await first;
      expect(c.of(root.path).status, UsageStatus.done);
      expect(c.of(root.path).result!.totalBytes, 7850);
      expect(c.scanning, isNull);
    });
  });

  group('캐시', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('daylight_broom_usage_cache_'));
    tearDown(() => dir.deleteSync(recursive: true));

    DiskUsage sample(String root) => DiskUsage(
          root: root,
          separator: '/',
          scannedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          fileCounts: [1, 2, 3, 4, 5],
          dirs: [
            for (var i = 0; i < FileCategory.values.length; i++) {'$root/d$i': 100 * (i + 1)},
          ],
          topFiles: [
            for (var i = 0; i < FileCategory.values.length; i++) [UsageFile('$root/d$i/f', 7)],
          ],
          unreadable: 9,
        );

    test('파일 이름은 디스크마다 다르고 경로 문자를 쓰지 않는다', () {
      expect(UsageCache.fileNameFor(r'C:'), 'usage_C.json');
      expect(UsageCache.fileNameFor('/'), 'usage_root.json');
      expect(UsageCache.fileNameFor('/Volumes/Data'), 'usage_Volumes_Data.json');
    });

    test('저장했다가 같은 내용으로 읽는다', () async {
      final cache = UsageCache(dir);
      await cache.save(sample('/r'));
      final u = (await cache.load('/r'))!;
      expect(u.root, '/r');
      expect(u.unreadable, 9);
      expect(u.fileCounts, [1, 2, 3, 4, 5]);
      expect(u.bytesOf(FileCategory.video), 400);
      expect(u.topFiles[0].single.path, '/r/d0/f');
      expect(u.scannedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(await cache.load('/other'), isNull);
    });

    test('깨진 파일은 null 이고 .bak 으로 옮긴다', () async {
      final cache = UsageCache(dir);
      final name = UsageCache.fileNameFor('/r');
      File('${dir.path}${Platform.pathSeparator}$name').writeAsStringSync('{"v":1,"dirs":3}');
      expect(await cache.load('/r'), isNull);
      expect(File('${dir.path}${Platform.pathSeparator}$name.bak').existsSync(), isTrue);
    });

    test('컨트롤러는 분석 끝에 저장하고, 다음 실행에서 불러온다', () async {
      final tree = Directory.systemTemp.createTempSync('daylight_broom_usage_tree_');
      addTearDown(() => tree.deleteSync(recursive: true));
      _file(tree, 'a.pdf', 123);
      final first = UsageController(cache: UsageCache(dir));
      addTearDown(first.dispose);
      await first.scan(tree.path);
      expect(first.of(tree.path).status, UsageStatus.done);

      final second = UsageController(cache: UsageCache(dir));
      addTearDown(second.dispose);
      expect(second.of(tree.path).result, isNull);
      await second.restore(tree.path);
      expect(second.of(tree.path).status, UsageStatus.done);
      expect(second.of(tree.path).result!.bytesOf(FileCategory.documents), 123);
    });
  });
}
