import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'file_category.dart';
import 'usage_model.dart';

/// 스캔에서 빼는 곳 (macOS). `/System/Volumes/Data`는 `/Users` 등과 같은 파일이라 두 번 세지 않는다.
const _macSkip = {'/volumes', '/system/volumes', '/dev', '/private/var/vm', '/.vol'};

const _topFilesPerCategory = 30;

/// 이보다 작은 폴더는 상위 폴더로 합쳐서 결과를 가볍게 한다.
const defaultMinDirBytes = 4 * 1000 * 1000;

class _Frame {
  _Frame(this.path, this.inApp);

  final String path;
  final bool inApp;
}

/// [root] 아래를 한 번 훑어 종류별·폴더별 크기를 모은다. 링크는 따라가지 않는다.
/// 취소되면 null. 폴더를 [concurrency]개까지 동시에 읽는다.
Future<DiskUsage?> runUsageScan(
  String root, {
  required bool windows,
  int minDirBytes = defaultMinDirBytes,
  int concurrency = 32,
  bool Function()? isCancelled,
  void Function(UsageProgress)? onProgress,
}) async {
  final sep = windows ? r'\' : '/';
  final dirs = [for (var i = 0; i < FileCategory.values.length; i++) <String, int>{}];
  final counts = List.filled(FileCategory.values.length, 0);
  final top = [for (var i = 0; i < FileCategory.values.length; i++) <UsageFile>[]];
  var unreadable = 0;
  var files = 0;
  var bytes = 0;

  final rootDir = Directory(root).path;
  final stack = <_Frame>[_Frame(rootDir, isApplicationRoot(rootDir, windows: windows))];
  final clock = Stopwatch()..start();
  var lastReport = 0;
  var active = 0;
  Completer<void>? wake;

  void add(FileCategory cat, String path, int len, List<int> local) {
    local[cat.index] += len;
    counts[cat.index]++;
    files++;
    bytes += len;
    final list = top[cat.index];
    if (list.length < _topFilesPerCategory || len > list.last.bytes) {
      list.add(UsageFile(path, len));
      list.sort((a, b) => b.bytes.compareTo(a.bytes));
      if (list.length > _topFilesPerCategory) list.removeLast();
    }
  }

  // 폴더 하나: 목록을 읽고, 파일 크기를 동시에 묻는다. 디스크가 한 번에 여러 요청을 받으면 훨씬 빠르다.
  Future<void> visit(_Frame frame) async {
    List<FileSystemEntity> entries;
    try {
      entries = await Directory(frame.path).list(followLinks: false).toList();
    } on FileSystemException {
      unreadable++;
      return;
    }
    final fileEntries = <File>[];
    for (final e in entries) {
      if (e is Directory) {
        final p = e.path;
        if (!windows && _macSkip.contains(p.toLowerCase())) continue;
        stack.add(_Frame(p, frame.inApp || isApplicationRoot(p, windows: windows)));
      } else if (e is File) {
        fileEntries.add(e);
      }
    }
    if (fileEntries.isEmpty) return;
    final lengths = await Future.wait([
      for (final f in fileEntries) f.length().then<int>((n) => n, onError: (Object _) => -1),
    ]);
    final local = List.filled(FileCategory.values.length, 0);
    for (var i = 0; i < fileEntries.length; i++) {
      final len = lengths[i];
      if (len < 0) {
        unreadable++;
        continue;
      }
      final path = fileEntries[i].path;
      add(frame.inApp ? FileCategory.applications : categoryOfFile(path), path, len, local);
    }
    for (var i = 0; i < local.length; i++) {
      if (local[i] > 0) dirs[i][frame.path] = (dirs[i][frame.path] ?? 0) + local[i];
    }
  }

  while (true) {
    if (isCancelled?.call() ?? false) break;
    while (active < concurrency && stack.isNotEmpty) {
      final frame = stack.removeLast();
      active++;
      visit(frame).whenComplete(() {
        active--;
        final now = clock.elapsedMilliseconds;
        if (now - lastReport >= 200) {
          lastReport = now;
          onProgress?.call(UsageProgress(files: files, bytes: bytes, currentDir: frame.path));
        }
        wake?.complete();
        wake = null;
      });
    }
    if (active == 0 && stack.isEmpty) break;
    wake = Completer<void>();
    await wake!.future;
  }
  // 취소했으면 진행 중이던 폴더가 끝나기를 기다릴 필요 없이 버린다.
  if (isCancelled?.call() ?? false) return null;

  for (final m in dirs) {
    rollUpSmallDirs(m, root: rootDir, separator: sep, min: minDirBytes);
  }
  onProgress?.call(UsageProgress(files: files, bytes: bytes, currentDir: rootDir));
  return DiskUsage(
    root: rootDir,
    separator: sep,
    scannedAt: DateTime.now(),
    fileCounts: counts,
    dirs: dirs,
    topFiles: top,
    unreadable: unreadable,
  );
}

/// 실행 중인 스캔 하나. [result] 는 취소되면 null.
class UsageScanHandle {
  UsageScanHandle._(this._isolate, this._commands, this.result);

  final Isolate _isolate;
  final SendPort _commands;
  final Future<DiskUsage?> result;

  void cancel() {
    _commands.send('cancel');
  }

  void kill() => _isolate.kill(priority: Isolate.immediate);
}

/// 별도 isolate 에서 스캔을 시작한다 (UI 가 멈추지 않게).
Future<UsageScanHandle> startUsageScan(
  String root, {
  bool? windows,
  int minDirBytes = defaultMinDirBytes,
  void Function(UsageProgress)? onProgress,
}) async {
  final ready = ReceivePort();
  final messages = ReceivePort();
  final done = Completer<DiskUsage?>();
  final isolate = await Isolate.spawn(
    _scanWorker,
    [ready.sendPort, messages.sendPort, root, windows ?? Platform.isWindows, minDirBytes],
    onError: messages.sendPort,
    onExit: messages.sendPort,
  );
  final commands = await ready.first as SendPort;
  ready.close();
  messages.listen((m) {
    if (m is UsageProgress) {
      onProgress?.call(m);
    } else if (m is DiskUsage) {
      if (!done.isCompleted) done.complete(m);
      messages.close();
    } else if (m == null || m is List) {
      // onExit(null) 이거나 onError([error, stack]). 결과 없이 끝났다.
      if (!done.isCompleted) done.complete(null);
      messages.close();
    } else if (m == 'cancelled') {
      if (!done.isCompleted) done.complete(null);
      messages.close();
    }
  });
  return UsageScanHandle._(isolate, commands, done.future);
}

Future<void> _scanWorker(List<Object> args) async {
  final ready = args[0] as SendPort;
  final out = args[1] as SendPort;
  final commands = ReceivePort();
  var cancelled = false;
  commands.listen((m) {
    if (m == 'cancel') cancelled = true;
  });
  ready.send(commands.sendPort);
  final result = await runUsageScan(
    args[2] as String,
    windows: args[3] as bool,
    minDirBytes: args[4] as int,
    isCancelled: () => cancelled,
    onProgress: out.send,
  );
  commands.close();
  out.send(result ?? 'cancelled');
}
