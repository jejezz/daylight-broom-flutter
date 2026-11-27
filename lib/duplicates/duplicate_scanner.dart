import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// 앞부분만 먼저 비교하는 크기. 크기가 같아도 앞부분이 다르면 전체를 읽지 않는다.
const _headBytes = 64 * 1024;

/// 다운로드 중인 임시 파일 (CLAUDE.md: 건드리지 않는다).
const _partialExtensions = {'.crdownload', '.download', '.part'};

/// 내용이 같아도 의미 없는 시스템 파일.
const _ignoredNames = {'.ds_store', 'thumbs.db', 'desktop.ini', 'icon\r'};

/// 안을 들여다보지 않는 패키지 폴더 (macOS 에선 파일 하나처럼 보이고, 안의 파일을 지우면 망가진다).
const _packageExtensions = {
  '.app', '.bundle', '.framework', '.plugin', '.kext', '.photoslibrary', '.musiclibrary', '.tvlibrary',
  '.fcpbundle', '.logicx', '.band', '.xcodeproj', '.xcworkspace', '.xcassets', '.pkg', '.lproj',
};

class DuplicateFile {
  const DuplicateFile({required this.path, required this.bytes, required this.modified});

  final String path;
  final int bytes;
  final DateTime modified;
}

/// 내용이 똑같은 파일 묶음. [files]는 오래된 것부터.
class DuplicateGroup {
  DuplicateGroup({required this.hash, required this.bytes, required this.files});

  final String hash;

  /// 파일 하나의 크기.
  final int bytes;
  final List<DuplicateFile> files;

  /// 하나만 남기면 확보되는 용량.
  int get wastedBytes => bytes * (files.length - 1);
}

enum DuplicatePhase { listing, hashing }

class DuplicateProgress {
  const DuplicateProgress({required this.phase, required this.files, this.done = 0, this.total = 0, this.current = ''});

  final DuplicatePhase phase;

  /// 지금 읽는 폴더(훑기) 또는 파일(비교).
  final String current;

  /// 지금까지 찾은 파일 수.
  final int files;

  /// 비교 단계에서 읽은 바이트와 읽어야 할 바이트.
  final int done;
  final int total;
}

class DuplicateScanResult {
  const DuplicateScanResult({required this.root, required this.groups, required this.scannedFiles, required this.unreadable});

  final String root;

  /// 확보할 수 있는 용량이 큰 것부터.
  final List<DuplicateGroup> groups;
  final int scannedFiles;
  final int unreadable;

  int get wastedBytes => groups.fold(0, (s, g) => s + g.wastedBytes);
  int get duplicateFiles => groups.fold(0, (s, g) => s + g.files.length);
}

bool _skipFile(String path) {
  final name = p.basename(path).toLowerCase();
  if (_ignoredNames.contains(name)) return true;
  return _partialExtensions.contains(p.extension(name));
}

bool _skipDir(String path) {
  final name = p.basename(path);
  if (name.startsWith('.')) return true; // .git, .Trash 등 숨김 폴더
  return _packageExtensions.contains(p.extension(name).toLowerCase());
}

/// [root] 아래의 파일을 내용으로 비교해 똑같은 것끼리 묶는다. 링크는 따라가지 않는다.
/// 크기 → 앞부분 해시 → 전체 해시(SHA-256) 순으로 좁혀서, 크기가 유일한 파일은 읽지 않는다.
/// [minBytes]보다 작은 파일은 보지 않는다 (빈 파일은 모두 "같아서" 의미가 없다).
/// 묶음을 찾을 때마다 [onGroup]으로 바로 알린다 (끝나기 전에도 목록을 보여 줄 수 있게). 취소되면 null.
Future<DuplicateScanResult?> runDuplicateScan(
  String root, {
  int minBytes = 1,
  bool Function()? isCancelled,
  void Function(DuplicateProgress)? onProgress,
  void Function(DuplicateGroup)? onGroup,
}) async {
  bool cancelled() => isCancelled?.call() ?? false;
  final clock = Stopwatch()..start();
  var lastReport = -1000;
  void report(DuplicateProgress Function() make, {bool force = false}) {
    final now = clock.elapsedMilliseconds;
    if (!force && now - lastReport < 150) return;
    lastReport = now;
    onProgress?.call(make());
  }

  // 1. 훑기: 크기별로 모은다.
  final bySize = <int, List<DuplicateFile>>{};
  var files = 0;
  var unreadable = 0;
  final stack = [Directory(root).path];
  while (stack.isNotEmpty) {
    if (cancelled()) return null;
    final dir = stack.removeLast();
    List<FileSystemEntity> entries;
    try {
      entries = await Directory(dir).list(followLinks: false).toList();
    } on FileSystemException {
      unreadable++;
      continue;
    }
    for (final e in entries) {
      if (e is Directory) {
        if (!_skipDir(e.path)) stack.add(e.path);
      } else if (e is File && !_skipFile(e.path)) {
        try {
          final stat = await e.stat();
          files++;
          if (stat.size < minBytes) continue;
          bySize.putIfAbsent(stat.size, () => []).add(DuplicateFile(path: e.path, bytes: stat.size, modified: stat.modified));
        } on FileSystemException {
          unreadable++;
        }
      }
    }
    report(() => DuplicateProgress(phase: DuplicatePhase.listing, files: files, current: dir));
  }

  final candidates = [for (final g in bySize.values) if (g.length > 1) g];
  final total = candidates.fold<int>(0, (s, g) => s + g.fold<int>(0, (t, f) => t + f.bytes));
  var done = 0;
  var current = '';
  void progressHash() =>
      report(() => DuplicateProgress(phase: DuplicatePhase.hashing, files: files, done: done, total: total, current: current));
  report(() => DuplicateProgress(phase: DuplicatePhase.hashing, files: files, total: total), force: true);

  // 2. 크기가 같은 묶음 안에서 앞부분 → 전체 해시로 가른다.
  final groups = <DuplicateGroup>[];
  for (final sameSize in candidates) {
    if (cancelled()) return null;
    final size = sameSize.first.bytes;
    final byHead = <String, List<DuplicateFile>>{};
    for (final f in sameSize) {
      if (cancelled()) return null;
      current = f.path;
      final h = await _hash(f.path, limit: _headBytes);
      done += size <= _headBytes ? size : _headBytes;
      if (h == null) {
        unreadable++;
        continue;
      }
      byHead.putIfAbsent(h, () => []).add(f);
      progressHash();
    }
    for (final entry in byHead.entries) {
      final same = entry.value;
      if (same.length < 2) {
        done += same.fold<int>(0, (s, f) => s + (size - (size <= _headBytes ? size : _headBytes)));
        continue;
      }
      // 앞부분이 곧 전체면 다시 읽을 필요가 없다.
      final byFull = <String, List<DuplicateFile>>{};
      if (size <= _headBytes) {
        byFull[entry.key] = same;
      } else {
        for (final f in same) {
          if (cancelled()) return null;
          current = f.path;
          final h = await _hash(f.path, skip: _headBytes, onBytes: (n) {
            done += n;
            progressHash();
          });
          if (h == null) {
            unreadable++;
            continue;
          }
          byFull.putIfAbsent('${entry.key}:$h', () => []).add(f);
        }
      }
      for (final full in byFull.entries) {
        if (full.value.length < 2) continue;
        final list = [...full.value]..sort((a, b) {
            final c = a.modified.compareTo(b.modified);
            return c != 0 ? c : a.path.compareTo(b.path);
          });
        final group = DuplicateGroup(hash: full.key, bytes: size, files: list);
        groups.add(group);
        onGroup?.call(group);
      }
    }
  }
  if (cancelled()) return null;
  groups.sort((a, b) {
    final c = b.wastedBytes.compareTo(a.wastedBytes);
    return c != 0 ? c : a.files.first.path.compareTo(b.files.first.path);
  });
  report(() => DuplicateProgress(phase: DuplicatePhase.hashing, files: files, done: total, total: total), force: true);
  return DuplicateScanResult(root: Directory(root).path, groups: groups, scannedFiles: files, unreadable: unreadable);
}

/// [path]의 [skip]부터 [limit]바이트(없으면 끝까지)의 SHA-256. 읽지 못하면 null.
Future<String?> _hash(String path, {int skip = 0, int? limit, void Function(int bytes)? onBytes}) async {
  try {
    final stream = File(path).openRead(skip, limit == null ? null : skip + limit);
    final digest = await sha256.bind(onBytes == null ? stream : stream.map((chunk) {
      onBytes(chunk.length);
      return chunk;
    })).first;
    return digest.toString();
  } on FileSystemException {
    return null;
  }
}

/// 실행 중인 찾기 하나. [result]는 취소되거나 실패하면 null.
class DuplicateScanHandle {
  DuplicateScanHandle(this.result, {required this.onCancel, this.onKill});

  final Future<DuplicateScanResult?> result;
  final void Function() onCancel;
  final void Function()? onKill;

  void cancel() => onCancel();
  void kill() => onKill?.call();
}

/// 별도 isolate 에서 찾는다 (큰 파일을 읽는 동안 UI 가 멈추지 않게).
Future<DuplicateScanHandle> startDuplicateScan(
  String root, {
  void Function(DuplicateProgress)? onProgress,
  void Function(DuplicateGroup)? onGroup,
}) async {
  final ready = ReceivePort();
  final messages = ReceivePort();
  final done = Completer<DuplicateScanResult?>();
  final isolate = await Isolate.spawn(
    _worker,
    [ready.sendPort, messages.sendPort, root],
    onError: messages.sendPort,
    onExit: messages.sendPort,
  );
  final commands = await ready.first as SendPort;
  ready.close();
  messages.listen((m) {
    if (m is DuplicateProgress) {
      onProgress?.call(m);
      return;
    }
    if (m is DuplicateGroup) {
      onGroup?.call(m);
      return;
    }
    // 결과, 'cancelled', onExit(null), onError([error, stack]) — 어느 것이든 끝이다.
    if (!done.isCompleted) done.complete(m is DuplicateScanResult ? m : null);
    messages.close();
  });
  return DuplicateScanHandle(
    done.future,
    onCancel: () => commands.send('cancel'),
    onKill: () => isolate.kill(priority: Isolate.immediate),
  );
}

Future<void> _worker(List<Object> args) async {
  final ready = args[0] as SendPort;
  final out = args[1] as SendPort;
  final commands = ReceivePort();
  var cancelled = false;
  commands.listen((m) {
    if (m == 'cancel') cancelled = true;
  });
  ready.send(commands.sendPort);
  final result =
      await runDuplicateScan(args[2] as String, isCancelled: () => cancelled, onProgress: out.send, onGroup: out.send);
  commands.close();
  out.send(result ?? 'cancelled');
}
