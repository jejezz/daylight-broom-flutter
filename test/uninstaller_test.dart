import 'dart:io';

import 'package:daylight_broom/cleaner/folder_sizer.dart';
import 'package:daylight_broom/engine/file_ops.dart';
import 'package:daylight_broom/uninstaller/app_scanner.dart';
import 'package:daylight_broom/uninstaller/app_trasher.dart';
import 'package:daylight_broom/uninstaller/apps_controller.dart';
import 'package:daylight_broom/uninstaller/installed_app.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_test/flutter_test.dart';

class _WalkSizer implements FolderSizer {
  @override
  Future<SizeResult> measure(List<String> paths) async {
    final (bytes, restricted) = walkSizes(paths);
    return SizeResult(bytes, restricted);
  }
}

/// 디스크의 Info.plist 대신 앱 폴더 이름으로 정체를 정한다.
class _FakeReader implements AppInfoReader {
  _FakeReader(this.table);

  final Map<String, ({String? bundleId, String? name, String? version})?> table;

  @override
  Future<({String? bundleId, String? name, String? version})?> read(String appPath) async => table[appPath.split('/').last];
}

class _FakeTrash implements AppTrasher {
  _FakeTrash({this.failing = const {}});

  final Set<String> failing;
  final List<String> trashed = [];

  @override
  Future<Map<String, String>> trash(List<String> paths) async {
    final failed = <String, String>{};
    for (final p in paths) {
      if (failing.contains(p)) {
        failed[p] = 'permission denied';
      } else {
        trashed.add(p);
      }
    }
    return failed;
  }
}

void main() {
  late Directory home;
  late String apps;

  setUp(() {
    home = Directory.systemTemp.createTempSync('daylight_broom_apps_');
    apps = '${home.path}/Applications';
    Directory(apps).createSync();
  });
  tearDown(() => home.deleteSync(recursive: true));

  void file(String rel, [int bytes = 100]) => File('${home.path}/$rel')
    ..createSync(recursive: true)
    ..writeAsBytesSync(List.filled(bytes, 1));

  void app(String name, [int bytes = 1000]) => file('Applications/$name.app/Contents/MacOS/x', bytes);

  AppScanner scanner({Map<String, ({String? bundleId, String? name, String? version})?>? table, String? own}) => AppScanner(
        reader: _FakeReader(table ??
            {
              'Spotify.app': (bundleId: 'com.spotify.client', name: 'Spotify', version: '1.2'),
              'Notes.app': (bundleId: 'com.example.notes', name: 'Notes', version: '3'),
              'Daylight Broom.app': (bundleId: 'art.zoomon.daylightbroom', name: 'Daylight Broom', version: '1'),
            }),
        sizer: _WalkSizer(),
        env: {'HOME': home.path},
        appDirsOverride: [apps],
        ownBundleId: own,
      );

  group('AppScanner.listApps', () {
    test('앱을 이름순으로 모으고 크기를 잰다. 읽을 수 없는 번들은 뺀다', () async {
      app('Spotify', 5000);
      app('Notes', 300);
      app('Broken');
      Directory('$apps/NotAnApp').createSync();
      final list = await scanner().listApps();
      expect(list.map((a) => a.name), ['Notes', 'Spotify']);
      expect(list.last.bytes, 5000);
      expect(list.last.bundleId, 'com.spotify.client');
    });

    test('이 앱 자신은 목록에서 뺀다', () async {
      app('Spotify');
      app('Daylight Broom');
      final list = await scanner(own: 'art.zoomon.daylightbroom').listApps();
      expect(list.map((a) => a.name), ['Spotify']);
    });
  });

  group('AppScanner.findLeftovers', () {
    InstalledApp spotify() => InstalledApp(path: '$apps/Spotify.app', bytes: 1, bundleId: 'com.spotify.client', displayName: 'Spotify');

    test('번들 id 로 찾은 것과 이름으로 찾은 것을 구분하고, 번들 id 쪽이 앞에 온다', () async {
      file('Library/Caches/com.spotify.client/a', 700);
      file('Library/Preferences/com.spotify.client.plist', 50);
      file('Library/Application Support/Spotify/data', 900);
      file('Library/Caches/Other/x');
      final found = await scanner().findLeftovers(spotify());
      final byPath = {for (final l in found) l.path.replaceFirst('${home.path}/', ''): l};
      expect(byPath.keys, containsAll(['Library/Caches/com.spotify.client', 'Library/Preferences/com.spotify.client.plist', 'Library/Application Support/Spotify']));
      expect(byPath.containsKey('Library/Caches/Other'), isFalse);
      expect(byPath['Library/Caches/com.spotify.client']!.match, LeftoverMatch.bundleId);
      expect(byPath['Library/Application Support/Spotify']!.match, LeftoverMatch.name);
      expect(found.first.match, LeftoverMatch.bundleId);
      expect(byPath['Library/Caches/com.spotify.client']!.bytes, 700);
    });

    test('이름이 다른 이름의 앞부분일 때(notes ↔ notes2hub)는 잡지 않는다', () async {
      file('Library/Application Support/notes2hub/x');
      file('Library/Application Support/Notes/x');
      file('Library/Application Support/Notes Backup/x'); // 이름 뒤가 공백이면 같은 앱으로 본다
      final notes = InstalledApp(path: '$apps/Notes.app', bytes: 1, bundleId: 'com.example.notes', displayName: 'Notes');
      final found = (await scanner().findLeftovers(notes)).map((l) => l.path.split('/').last).toSet();
      expect(found, {'Notes', 'Notes Backup'});
    });

    test('제작사 폴더 안의 제품 폴더를 찾는다 (Google/Chrome)', () async {
      file('Library/Application Support/Google/Chrome/p');
      file('Library/Application Support/Google/Drive/p');
      final chrome = InstalledApp(path: '$apps/Google Chrome.app', bytes: 1, bundleId: 'com.google.Chrome', displayName: 'Google Chrome');
      final found = (await scanner().findLeftovers(chrome)).map((l) => l.path).toList();
      expect(found.any((p) => p.endsWith('Google/Chrome')), isTrue);
      expect(found.any((p) => p.endsWith('Google/Drive')), isFalse);
    });

    test('번들 id 가 없는 앱은 이름으로만 찾고 아무것도 없어도 실패하지 않는다', () async {
      final noId = InstalledApp(path: '$apps/Mystery.app', bytes: 1, displayName: 'Mystery');
      expect(await scanner().findLeftovers(noId), isEmpty);
    });
  });

  group('SystemAppTrasher', () {
    test('우리가 휴지통에 넣을 수 있으면 Finder 는 부르지 않는다', () async {
      final calls = <String>[];
      final t = SystemAppTrasher(ops: _FakeOps(), run: (e, a) async {
        calls.add(e);
        return ProcessResult(0, 0, '', '');
      });
      expect(await t.trash(['/x/a']), isEmpty);
      expect(calls, isEmpty);
    });

    test('실패하면 Finder 로 다시 시도하고, 경로는 인자로 넘기며 파일이 사라졌을 때만 성공으로 센다', () async {
      List<String>? args;
      var gone = false;
      final t = SystemAppTrasher(
        ops: _FakeOps(failing: {'/Applications/My "App".app'}),
        run: (e, a) async {
          args = a;
          gone = true;
          return ProcessResult(0, 0, '', '');
        },
        exists: (p) => !gone,
      );
      expect(await t.trash([r'/Applications/My "App".app']), isEmpty);
      expect(args!.last, r'/Applications/My "App".app');
      expect(args!.where((a) => a.contains('My "App"')).length, 1); // 스크립트 문자열에는 끼워 넣지 않는다
    });

    test('인증을 취소하면(종료 코드 0이어도 파일이 남음) 실패로 돌려준다', () async {
      final t = SystemAppTrasher(
        ops: _FakeOps(failing: {'/Applications/X.app'}),
        run: (e, a) async => ProcessResult(0, 0, '', ''),
        exists: (p) => true,
      );
      expect((await t.trash(['/Applications/X.app'])).keys, ['/Applications/X.app']);
    });
  });

  group('AppsController', () {
    Future<AppsController> make({_FakeTrash? trash, VoidCallback? onChanged}) async {
      app('Spotify', 5000);
      app('Notes', 300);
      file('Library/Caches/com.spotify.client/a', 700);
      file('Library/Application Support/Spotify/data', 900);
      final c = AppsController(scanner: scanner(), trasher: trash ?? _FakeTrash(), onChanged: onChanged);
      await c.load();
      return c;
    }

    test('앱을 고르면 번들 id 로 찾은 남은 파일만 미리 선택된다', () async {
      final c = await make();
      await c.select(c.apps.firstWhere((a) => a.name == 'Spotify'));
      expect(c.leftovers.length, 2);
      expect(c.selectedLeftovers.map((p) => p.split('/').last), ['com.spotify.client']);
      expect(c.uninstallBytes, 5000 + 700);
      expect(c.uninstallCount, 2);
    });

    test('제거하면 남은 파일 → 앱 번들 순으로 휴지통에 보내고 앱을 목록과 선택에서 뺀다', () async {
      final trash = _FakeTrash();
      var changed = 0;
      final c = await make(trash: trash, onChanged: () => changed++);
      final spotify = c.apps.firstWhere((a) => a.name == 'Spotify');
      await c.select(spotify);
      await c.uninstall();
      expect(trash.trashed.last, spotify.path);
      expect(trash.trashed.length, 2);
      expect(c.lastMoved, 5700);
      expect(c.apps.map((a) => a.name), ['Notes']);
      expect(c.selected, isNull);
      expect(changed, 1);
    });

    test('일부가 실패하면 실패 수와 이유를 알리고 실패한 것은 남겨 다시 시도할 수 있다', () async {
      final spotifyPath = '$apps/Spotify.app';
      final c = await make(trash: _FakeTrash(failing: {spotifyPath}));
      await c.select(c.apps.firstWhere((a) => a.name == 'Spotify'));
      await c.uninstall();
      expect(c.failedCount, 1);
      expect(c.failedReason, 'permission denied');
      expect(c.lastMoved, 700);
      expect(c.selected?.name, 'Spotify'); // 앱이 아직 있다
      expect(c.apps.length, 2);
      expect(c.selectedLeftovers, isEmpty);
    });

    test('앱 번들을 체크 해제하면 남은 파일만 보낸다', () async {
      final trash = _FakeTrash();
      final c = await make(trash: trash);
      await c.select(c.apps.firstWhere((a) => a.name == 'Spotify'));
      c.setRemoveBundle(false);
      expect(c.uninstallBytes, 700);
      await c.uninstall();
      expect(trash.trashed.any((p) => p.endsWith('.app')), isFalse);
      expect(c.selected?.name, 'Spotify');
    });

    test('찾는 도중 다른 앱을 고르면 앞의 결과는 버린다', () async {
      final c = await make();
      final spotify = c.apps.firstWhere((a) => a.name == 'Spotify');
      final notes = c.apps.firstWhere((a) => a.name == 'Notes');
      final first = c.select(spotify);
      await c.select(notes);
      await first;
      expect(c.selected?.name, 'Notes');
      expect(c.leftovers.every((l) => !l.path.contains('spotify')), isTrue);
    });
  });
}

class _FakeOps implements FileOps {
  _FakeOps({this.failing = const {}});

  final Set<String> failing;

  @override
  Future<String?> trash(String path) async {
    if (failing.contains(path)) throw const FileSystemException('denied');
    return null;
  }

  @override
  Future<String> move(String src, String destDir, {String? asName}) => throw UnimplementedError();
}
