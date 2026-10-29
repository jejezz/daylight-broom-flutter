import 'file_category.dart';

/// 스캔 중에 isolate 에서 보내오는 진행 상황.
class UsageProgress {
  const UsageProgress({required this.files, required this.bytes, required this.currentDir});

  final int files;
  final int bytes;
  final String currentDir;
}

class UsageFile {
  const UsageFile(this.path, this.bytes);

  final String path;
  final int bytes;
}

/// 폴더 하나와 그 아래(하위 폴더 포함)에서 한 종류가 차지하는 크기.
class DirUsage {
  const DirUsage(this.path, this.bytes);

  final String path;
  final int bytes;
}

/// 디스크 하나를 훑은 결과. 종류별로 "폴더 → 그 폴더에 직접 들어 있는 파일의 합"을 가진다.
/// 작은 폴더는 상위 폴더로 합쳐 두어서(roll-up) 항목 수가 파일 수만큼 늘지 않는다.
class DiskUsage {
  DiskUsage({
    required this.root,
    required this.separator,
    required this.scannedAt,
    required this.fileCounts,
    required this.dirs,
    required this.topFiles,
    required this.unreadable,
    this.countsStale = false,
  });

  final String root;
  final String separator;
  final DateTime scannedAt;

  /// 종류별(인덱스 = [FileCategory.index]) 파일 수.
  final List<int> fileCounts;

  /// 종류별 "폴더 → 직접 들어 있는 파일의 합".
  final List<Map<String, int>> dirs;

  /// 종류별로 가장 큰 파일들 (큰 것부터).
  final List<List<UsageFile>> topFiles;

  /// 권한 등으로 읽지 못한 폴더·파일 수. 있으면 합계가 실제보다 작다.
  final int unreadable;

  /// 폴더를 지운 뒤에는 종류별 파일 수를 정확히 알 수 없다 (다시 분석하면 바로잡힌다).
  bool countsStale;

  static const _formatVersion = 1;

  Map<String, Object?> toJson() => {
        'v': _formatVersion,
        'root': root,
        'sep': separator,
        'at': scannedAt.millisecondsSinceEpoch,
        'counts': fileCounts,
        'unreadable': unreadable,
        'stale': countsStale,
        'dirs': dirs,
        'top': [
          for (final list in topFiles) [for (final f in list) [f.path, f.bytes]],
        ],
      };

  /// 형식이 맞지 않으면 [FormatException]. 버전이 다르면 옛 캐시이므로 같은 예외로 버린다.
  factory DiskUsage.fromJson(Map<String, Object?> j) {
    try {
      if (j['v'] != _formatVersion) throw const FormatException('version');
      final n = FileCategory.values.length;
      final dirs = [
        for (final m in j['dirs']! as List)
          {for (final e in (m as Map).entries) e.key as String: e.value as int},
      ];
      final top = [
        for (final l in j['top']! as List)
          [for (final f in l as List) UsageFile((f as List)[0] as String, f[1] as int)],
      ];
      final counts = [for (final c in j['counts']! as List) c as int];
      if (dirs.length != n || top.length != n || counts.length != n) throw const FormatException('shape');
      return DiskUsage(
        root: j['root']! as String,
        separator: j['sep']! as String,
        scannedAt: DateTime.fromMillisecondsSinceEpoch(j['at']! as int),
        fileCounts: counts,
        dirs: dirs,
        topFiles: top,
        unreadable: j['unreadable']! as int,
        countsStale: j['stale'] == true,
      );
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('$e');
    }
  }

  int bytesOf(FileCategory c) => dirs[c.index].values.fold(0, (a, b) => a + b);

  int get totalBytes => FileCategory.values.fold(0, (a, c) => a + bytesOf(c));

  /// [dir] 바로 아래 폴더들의 크기(하위 포함), 큰 것부터. [dir] 에 직접 있는 파일은 [directBytes].
  List<DirUsage> childrenOf(FileCategory c, String dir) {
    final prefix = dir.endsWith(separator) ? dir : '$dir$separator';
    final acc = <String, int>{};
    for (final e in dirs[c.index].entries) {
      final key = e.key;
      if (key == dir || !key.startsWith(prefix)) continue;
      final cut = key.indexOf(separator, prefix.length);
      final child = cut < 0 ? key : key.substring(0, cut);
      acc[child] = (acc[child] ?? 0) + e.value;
    }
    return [for (final e in acc.entries) DirUsage(e.key, e.value)]..sort((a, b) => b.bytes.compareTo(a.bytes));
  }

  /// [dir] 에 직접 들어 있는 (하위 폴더 제외) 파일의 합. 합쳐진 작은 하위 폴더는 여기에 들어 있다.
  int directBytes(FileCategory c, String dir) => dirs[c.index][dir] ?? 0;

  /// [dir] 아래 전체(하위 포함), 모든 종류를 합쳐서. 폴더를 통째로 지울 때 실제로 사라지는 양이다.
  int bytesUnderAll(String dir) => FileCategory.values.fold(0, (a, c) => a + bytesUnder(c, dir));

  /// 휴지통으로 보낸 폴더를 결과에서 뺀다 (모든 종류, 하위 포함, 가장 큰 파일 목록도).
  void removeDirectory(String dir) {
    final prefix = dir.endsWith(separator) ? dir : '$dir$separator';
    for (final m in dirs) {
      m.removeWhere((k, _) => k == dir || k.startsWith(prefix));
    }
    for (final l in topFiles) {
      l.removeWhere((f) => f.path.startsWith(prefix));
    }
    countsStale = true;
  }

  /// 휴지통으로 보낸 파일 하나를 [c] 종류에서 뺀다. 작은 폴더로 합쳐져 있으면 가장 가까운 상위 폴더에서 뺀다.
  void removeFile(FileCategory c, String path, int bytes) {
    final m = dirs[c.index];
    var cut = path.lastIndexOf(separator);
    while (cut >= 0) {
      final dir = path.substring(0, cut);
      final key = m.containsKey(dir) ? dir : (m.containsKey('$dir$separator') ? '$dir$separator' : null); // "C:" -> "C:\", "" -> "/"
      if (key != null) {
        final left = m[key]! - bytes;
        if (left > 0) {
          m[key] = left;
        } else {
          m.remove(key);
        }
        break;
      }
      cut = dir.lastIndexOf(separator);
    }
    topFiles[c.index].removeWhere((f) => f.path == path);
    if (fileCounts[c.index] > 0) fileCounts[c.index]--;
  }

  /// [dir] 아래 전체(하위 포함).
  int bytesUnder(FileCategory c, String dir) {
    final prefix = dir.endsWith(separator) ? dir : '$dir$separator';
    var sum = 0;
    for (final e in dirs[c.index].entries) {
      if (e.key == dir || e.key.startsWith(prefix)) sum += e.value;
    }
    return sum;
  }
}

/// [min] 바이트보다 작은 폴더를 상위 폴더로 합친다. 깊은 폴더부터 처리해서, 합쳐진 결과도 다시 작으면 더 위로 올라간다.
/// 스캔 루트는 합치지 않는다.
void rollUpSmallDirs(Map<String, int> dirs, {required String root, required String separator, required int min}) {
  if (min <= 0 || dirs.isEmpty) return;
  int depth(String p) => separator.allMatches(p).length;
  final byDepth = <int, List<String>>{};
  var deepest = 0;
  for (final k in dirs.keys) {
    final d = depth(k);
    byDepth.putIfAbsent(d, () => []).add(k);
    if (d > deepest) deepest = d;
  }
  for (var d = deepest; d >= 0; d--) {
    for (final key in byDepth[d] ?? const <String>[]) {
      final bytes = dirs[key];
      if (bytes == null || bytes >= min || key == root) continue;
      final cut = key.lastIndexOf(separator);
      var parent = cut < 0 ? root : key.substring(0, cut);
      if (parent.length < root.length) parent = root; // "C:" -> "C:\", "" -> "/"
      dirs.remove(key);
      dirs[parent] = (dirs[parent] ?? 0) + bytes;
      if (parent != root) byDepth.putIfAbsent(depth(parent), () => []).add(parent);
    }
  }
}
