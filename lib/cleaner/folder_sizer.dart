import 'dart:io';
import 'dart:isolate';

/// 폴더 크기 측정 결과. [restricted]는 권한 때문에 읽지 못한 곳이라 크기가 실제보다 작다.
class SizeResult {
  const SizeResult(this.bytes, [this.restricted = const {}]);

  final Map<String, int> bytes;
  final Set<String> restricted;
}

abstract class FolderSizer {
  Future<SizeResult> measure(List<String> paths);

  static FolderSizer forPlatform() => Platform.isMacOS ? DuSizer() : const WalkSizer();
}

/// macOS: `du -sk`. ~/Library/Caches 한 곳에 파일이 50만 개 넘게 있을 수 있어서
/// Dart 로 일일이 stat 하는 것보다 5~10배 빠르다. `du`는 모든 macOS 에 있다.
class DuSizer implements FolderSizer {
  @override
  Future<SizeResult> measure(List<String> paths) async {
    if (paths.isEmpty) return const SizeResult({});
    final r = await Process.run('du', ['-sk', ...paths]);
    final restricted = <String>{};
    for (final line in (r.stderr as String).split('\n')) {
      // "du: /Users/x/Library/Caches/foo: Operation not permitted"
      final m = RegExp(r'^du: (.+): (?:Operation not permitted|Permission denied)$').firstMatch(line);
      if (m != null) restricted.add(m.group(1)!);
    }
    final bytes = <String, int>{for (final p in paths) p: 0};
    for (final line in (r.stdout as String).split('\n')) {
      final tab = line.indexOf('\t');
      if (tab < 0) continue;
      bytes[line.substring(tab + 1)] = (int.tryParse(line.substring(0, tab).trim()) ?? 0) * 1024;
    }
    return SizeResult(bytes, restricted);
  }
}

/// 그 밖의 OS(Windows): 별도 isolate 에서 직접 걷는다. 읽을 수 없는 폴더는 건너뛰고 표시만 한다.
class WalkSizer implements FolderSizer {
  const WalkSizer();

  @override
  Future<SizeResult> measure(List<String> paths) async {
    if (paths.isEmpty) return const SizeResult({});
    final (bytes, restricted) = await Isolate.run(() => walkSizes(paths));
    return SizeResult(bytes, restricted);
  }
}

/// isolate 에서 돌릴 수 있도록 최상위 함수로 둔다 (테스트도 직접 부른다).
(Map<String, int>, Set<String>) walkSizes(List<String> paths) {
  final bytes = <String, int>{};
  final restricted = <String>{};
  for (final root in paths) {
    var total = 0;
    final pending = <String>[root];
    while (pending.isNotEmpty) {
      final dir = pending.removeLast();
      try {
        for (final e in Directory(dir).listSync(followLinks: false)) {
          if (e is Directory) {
            pending.add(e.path);
          } else if (e is File) {
            try {
              total += e.lengthSync();
            } on FileSystemException {
              restricted.add(root);
            }
          }
        }
      } on FileSystemException {
        restricted.add(root);
      }
    }
    // 루트가 파일이면 그 크기.
    if (FileSystemEntity.typeSync(root, followLinks: false) == FileSystemEntityType.file) {
      total = File(root).lengthSync();
    }
    bytes[root] = total;
  }
  return (bytes, restricted);
}
