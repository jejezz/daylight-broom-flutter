import 'dart:io';

import 'package:daylight_broom/cleaner/deleter.dart';
import 'package:daylight_broom/cleaner/folder_sizer.dart';
import 'package:daylight_broom/cleaner/format.dart';
import 'package:daylight_broom/cleaner/junk_controller.dart';
import 'package:daylight_broom/cleaner/scan_target.dart';
import 'package:daylight_broom/cleaner/scanner.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 디스크를 걷되 `du`가 없는 환경(Windows)과 같은 코드 경로를 쓴다.
class _WalkSizer implements FolderSizer {
  @override
  Future<SizeResult> measure(List<String> paths) async {
    final (bytes, restricted) = walkSizes(paths);
    return SizeResult(bytes, restricted);
  }
}

void main() {
  late Directory home;

  setUp(() => home = Directory.systemTemp.createTempSync('daylight_broom_cleaner_'));
  tearDown(() => home.deleteSync(recursive: true));

  File write(String rel, int bytes) {
    final f = File('${home.path}/$rel')..createSync(recursive: true);
    f.writeAsBytesSync(List.filled(bytes, 1));
    return f;
  }

  Map<String, String> macEnv() => {'HOME': home.path};

  group('대상 목록', () {
    test('경로의 ~ 와 %VAR% 를 풀고 OS 구분자로 맞춘다', () {
      final env = {'HOME': '/Users/a', 'LOCALAPPDATA': r'C:\Users\a\AppData\Local'};
      expect(expandTargetPath('~/.gradle/caches', env, CleanerPlatform.macos), '/Users/a/.gradle/caches');
      expect(expandTargetPath(r'%LOCALAPPDATA%\pip\Cache', env, CleanerPlatform.windows), r'C:\Users\a\AppData\Local\pip\Cache');
      expect(expandTargetPath(r'~/.gradle/caches', {'USERPROFILE': r'C:\Users\a'}, CleanerPlatform.windows),
          r'C:\Users\a\.gradle\caches');
    });

    test('풀 수 없는 변수가 있으면 빈 문자열이다', () {
      expect(expandTargetPath(r'%TEMP%', const {}, CleanerPlatform.windows), '');
    });

    test('id 는 겹치지 않고 모든 항목이 한 OS 이상을 지원한다', () {
      expect(scanTargets.map((t) => t.id).toSet().length, scanTargets.length);
      expect(scanTargets.every((t) => t.paths.isNotEmpty), isTrue);
    });

    test('OS 별 목록은 그 OS 경로만 가진다', () {
      expect(targetsFor(CleanerPlatform.macos).any((t) => t.id.startsWith('win_')), isFalse);
      expect(targetsFor(CleanerPlatform.windows).any((t) => t.id == 'xcode_derived'), isFalse);
      expect(targetsFor(CleanerPlatform.windows).any((t) => t.id == 'win_temp'), isTrue);
    });

    test('브라우저 대상은 프로필 폴더 전체를 가리키지 않는다', () {
      for (final t in scanTargets.where((t) => t.group == TargetGroup.browser)) {
        for (final path in t.paths.values.expand((x) => x)) {
          expect(path, matches(RegExp(r'(Cache|GPUCache)$')));
        }
      }
    });
  });

  group('스캐너', () {
    ScanTarget target(String id, List<String> paths, {bool children = true, Safety safety = Safety.safe}) =>
        ScanTarget(id: id, group: TargetGroup.system, safety: safety, paths: {CleanerPlatform.macos: paths}, listChildren: children);

    JunkScanner scanner(List<ScanTarget> targets) =>
        JunkScanner(platform: CleanerPlatform.macos, env: macEnv(), sizer: _WalkSizer(), targetsOverride: targets);

    test('자식 폴더마다 한 행이고 큰 것부터, 빈 것과 숨김은 뺀다', () async {
      write('caches/big/a.bin', 5000);
      write('caches/small/a.bin', 100);
      write('caches/.hidden/a.bin', 9999);
      Directory('${home.path}/caches/empty').createSync();
      final result = (await scanner([target('c', ['~/caches'])]).scan().toList()).last;
      expect(result.items.map((i) => i.name), ['big', 'small']);
      expect(result.items.first.bytes, 5000);
    });

    test('listChildren 이 false 이면 폴더 전체가 한 행이다', () async {
      write('pip/x/a.bin', 300);
      write('pip/b.bin', 200);
      final result = (await scanner([target('pip', ['~/pip'], children: false)]).scan().toList()).last;
      expect(result.items.single.bytes, 500);
      expect(result.items.single.path, '${home.path}/pip');
    });

    test('전용 대상이 가진 경로는 넓은 대상의 자식으로 또 나오지 않는다', () async {
      write('caches/pip/a.bin', 400);
      write('caches/other/a.bin', 100);
      final result = (await scanner([
        target('all', ['~/caches']),
        target('pip', ['~/caches/pip'], children: false),
      ]).scan().toList())
          .last;
      final ids = {for (final i in result.items) i.path: i.target.id};
      expect(ids['${home.path}/caches/pip'], 'pip');
      expect(ids['${home.path}/caches/other'], 'all');
      expect(result.items.length, 2);
    });

    test('없는 폴더는 조용히 건너뛰고, 단계마다 결과를 내보낸다', () async {
      write('a/x/f', 10);
      final results = await scanner([target('missing', ['~/nope']), target('a', ['~/a'])]).scan().toList();
      expect(results.last.items.length, 1);
      expect(results.last.unreadable, isEmpty);
    });
  });

  group('삭제기', () {
    PermanentDeleter deleter() => PermanentDeleter(allowedRoots: ['${home.path}/caches'], env: macEnv());

    test('허용된 루트 안의 파일과 폴더를 영구 삭제한다', () async {
      write('caches/a/f.bin', 10);
      write('caches/b.bin', 10);
      final failed = await deleter().delete(['${home.path}/caches/a', '${home.path}/caches/b.bin']);
      expect(failed, isEmpty);
      expect(Directory('${home.path}/caches/a').existsSync(), isFalse);
      expect(File('${home.path}/caches/b.bin').existsSync(), isFalse);
    });

    test('루트 밖, 홈, 루트는 지우지 않고 실패로 돌려준다', () async {
      write('keep/important.txt', 10);
      final failed = await deleter().delete(['${home.path}/keep', home.path, '/']);
      expect(failed.length, 3);
      expect(File('${home.path}/keep/important.txt').existsSync(), isTrue);
    });

    test('이미 없는 경로는 성공이다', () async {
      expect(await deleter().delete(['${home.path}/caches/gone']), isEmpty);
    });

    test('.Trash 는 폴더를 지우지 않고 비운다', () async {
      write('caches/.Trash/old.txt', 10);
      write('caches/.Trash/dir/x.txt', 10);
      final failed = await deleter().delete(['${home.path}/caches/.Trash']);
      expect(failed, isEmpty);
      expect(Directory('${home.path}/caches/.Trash').existsSync(), isTrue);
      expect(Directory('${home.path}/caches/.Trash').listSync(), isEmpty);
    });

    test('심볼릭 링크는 링크만 지우고 가리키는 곳은 건드리지 않는다', () async {
      write('outside/data.txt', 10);
      Directory('${home.path}/caches').createSync();
      Link('${home.path}/caches/link').createSync('${home.path}/outside');
      final failed = await deleter().delete(['${home.path}/caches/link']);
      expect(failed, isEmpty);
      expect(File('${home.path}/outside/data.txt').existsSync(), isTrue);
    });
  });

  group('JunkController', () {
    test('스캔하면 안전한 것만 선택되고, 정리하면 선택한 것만 지워진다', () async {
      write('c/cache1/f', 1000);
      write('c/cache2/f', 2000);
      write('r/archive/f', 4000);
      final scanner = JunkScanner(
        platform: CleanerPlatform.macos,
        env: macEnv(),
        sizer: _WalkSizer(),
        targetsOverride: [
          ScanTarget(id: 'c', group: TargetGroup.system, safety: Safety.safe, paths: {CleanerPlatform.macos: ['~/c']}),
          ScanTarget(id: 'r', group: TargetGroup.developer, safety: Safety.review, paths: {CleanerPlatform.macos: ['~/r']}),
        ],
      );
      final c = JunkController(scanner: scanner);
      await c.scan();

      expect(c.items.length, 3);
      expect(c.selected, {'${home.path}/c/cache1', '${home.path}/c/cache2'});
      expect(c.selectedBytes, 3000);
      expect(c.selectedReviewItems, isEmpty);

      c.toggle('${home.path}/r/archive', true);
      expect(c.selectedReviewItems.single.name, 'archive');
      c.toggle('${home.path}/r/archive', false);

      final freed = await c.cleanSelected();
      expect(freed, 3000);
      expect(c.lastFreed, 3000);
      expect(c.failedCount, 0);
      expect(c.items.single.name, 'archive');
      expect(Directory('${home.path}/c/cache1').existsSync(), isFalse);
      expect(Directory('${home.path}/r/archive').existsSync(), isTrue);
    });

    test('대상 전체 선택·해제', () async {
      write('c/a/f', 10);
      write('c/b/f', 10);
      final scanner = JunkScanner(
        platform: CleanerPlatform.macos,
        env: macEnv(),
        sizer: _WalkSizer(),
        targetsOverride: [
          ScanTarget(id: 'c', group: TargetGroup.system, safety: Safety.safe, paths: {CleanerPlatform.macos: ['~/c']}),
        ],
      );
      final c = JunkController(scanner: scanner);
      await c.scan();
      final t = c.items.first.target;
      c.toggleTarget(t, false);
      expect(c.selected, isEmpty);
      c.toggleTarget(t, true);
      expect(c.selected.length, 2);
    });
  });

  test('formatBytes 는 1000 단위', () {
    expect(formatBytes(999), '999 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(2500000000), '2.5 GB');
  });
}
