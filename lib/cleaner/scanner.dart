import 'dart:io';

import 'package:path/path.dart' as p;

import 'folder_sizer.dart';
import 'scan_target.dart';

/// 정크 목록의 선택 가능한 한 행: 크기를 잰 경로 하나.
class JunkItem {
  const JunkItem({required this.target, required this.path, required this.bytes});

  final ScanTarget target;
  final String path;
  final int bytes;

  String get name => p.basename(path);
}

/// 한 번의 스캔 결과.
class ScanResult {
  const ScanResult({this.items = const [], this.unreadable = const [], this.restricted = const {}});

  /// 큰 것부터.
  final List<JunkItem> items;

  /// 있지만 읽을 수 없던 스캔 루트 (권한 없음, iCloud 미사용…). 조용히 비우지 않고 화면에 알린다.
  final List<String> unreadable;

  /// 크기를 재는 중 권한이 막은 곳. 실제보다 작게 집계되고 지우기도 실패할 가능성이 높다.
  final Set<String> restricted;
}

class JunkScanner {
  JunkScanner({CleanerPlatform? platform, Map<String, String>? env, FolderSizer? sizer, this.targetsOverride})
      : platform = platform ?? CleanerPlatform.current ?? CleanerPlatform.macos,
        env = env ?? Platform.environment,
        _sizer = sizer ?? FolderSizer.forPlatform();

  final CleanerPlatform platform;
  final Map<String, String> env;
  final FolderSizer _sizer;

  /// 테스트에서 목록을 바꿔 끼운다. null 이면 이 OS 의 기본 목록.
  final List<ScanTarget>? targetsOverride;

  List<ScanTarget> get targets => targetsOverride ?? targetsFor(platform);

  /// 스캔이 허용하는 루트들. 삭제기가 이 밖의 경로를 거부하는 데 쓴다.
  List<String> get roots => [
        for (final t in targets) ...t.resolvedPaths(platform, env).where((r) => r.isNotEmpty),
      ];

  /// 대상을 하나 끝낼 때마다 그때까지의 결과를 내보낸다.
  Stream<ScanResult> scan() async* {
    // 전용 대상이 가진 경로는 더 넓은 대상의 자식으로 또 나오면 안 된다
    // (~/Library/Caches/pip 은 "pip 캐시"이지 "사용자 캐시"의 자식이 아니다).
    final claimed = {for (final t in targets) ...t.resolvedPaths(platform, env)};
    final items = <JunkItem>[];
    final unreadable = <String>[];
    final restricted = <String>{};

    for (final target in targets) {
      final paths = <String>[];
      for (final root in target.resolvedPaths(platform, env)) {
        if (root.isEmpty || !Directory(root).existsSync()) continue;
        try {
          final children = Directory(root).listSync(followLinks: false);
          if (!target.listChildren) {
            // 위에서 먼저 읽어 봤다: 못 읽는 루트는 0바이트로 재져서 이유 없이 사라진다.
            paths.add(root);
          } else {
            for (final child in children) {
              if (claimed.contains(child.path)) continue;
              if (p.basename(child.path).startsWith('.')) continue;
              paths.add(child.path);
            }
          }
        } on FileSystemException {
          unreadable.add(root);
        }
      }
      if (paths.isEmpty) continue;

      final sizes = await _sizer.measure(paths);
      restricted.addAll(sizes.restricted);
      items
        ..addAll([
          for (final e in sizes.bytes.entries)
            if (e.value > 0) JunkItem(target: target, path: e.key, bytes: e.value),
        ])
        ..sort((a, b) => b.bytes.compareTo(a.bytes));
      yield ScanResult(items: List.unmodifiable(items), unreadable: List.of(unreadable), restricted: Set.of(restricted));
    }
    // 항목이 하나도 없거나 마지막 대상이 비었어도 끝 상태를 알린다.
    yield ScanResult(items: List.unmodifiable(items), unreadable: List.of(unreadable), restricted: Set.of(restricted));
  }
}
