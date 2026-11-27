import 'dart:io';

import 'package:flutter/foundation.dart';

import '../engine/batch_trash.dart';
import '../engine/file_ops.dart';
import '../engine/history.dart';
import 'duplicate_scanner.dart';

enum DuplicateStatus { idle, scanning, done, cancelled, failed }

typedef DuplicateScanStarter = Future<DuplicateScanHandle> Function(
    String root, void Function(DuplicateProgress) onProgress, void Function(DuplicateGroup) onGroup);

/// 중복 파일 화면의 상태: 고른 폴더, 찾기 진행, 찾은 묶음과 선택, 휴지통으로 보내기.
/// 찾기는 별도 isolate 에서 돌고, 묶음은 찾는 대로 [groups]에 붙는다. 멈추면 그때까지 찾은 것을 남긴다.
/// 묶음마다 적어도 하나는 남도록 선택을 막는다 (원본까지 지우는 일이 없게).
class DuplicateController extends ChangeNotifier {
  /// [trasher]가 없고 [ops]가 있으면 그것으로 하나씩 보낸다 (테스트). 둘 다 없으면 OS 기본.
  DuplicateController({DuplicateScanStarter? starter, FileOps? ops, BatchTrasher? trasher, this.onChanged, this.onRecord})
      : _starter = starter ??
            ((root, onProgress, onGroup) => startDuplicateScan(root, onProgress: onProgress, onGroup: onGroup)),
        _trasher = trasher ?? (ops != null ? FileOpsBatchTrasher(ops) : SystemBatchTrasher());

  final DuplicateScanStarter _starter;
  final BatchTrasher _trasher;

  /// 휴지통으로 보낸 뒤 (디스크 여유 용량을 다시 읽는 데 쓴다).
  final VoidCallback? onChanged;

  /// 정리한 결과를 이력에 남기는 쪽. 옮긴 것이 없으면 부르지 않는다.
  final void Function(HistoryEntry entry)? onRecord;

  String? folder;
  DuplicateStatus status = DuplicateStatus.idle;
  DuplicateProgress? progress;
  Object? error;

  /// 찾은 묶음. 찾는 중에는 찾은 순서, 끝나면 확보할 수 있는 용량이 큰 순서.
  List<DuplicateGroup> groups = [];
  int scannedFiles = 0;
  int unreadable = 0;
  final Set<String> selected = {};

  bool trashing = false;

  /// 휴지통으로 보내는 중의 진행: 끝낸 수 / 전체 수, 방금 끝낸 파일.
  int trashDone = 0;
  int trashTotal = 0;
  String? trashCurrent;

  /// 휴지통 보내기를 사용자가 멈췄다 (남은 것은 선택된 채로 남는다).
  bool trashStopped = false;
  bool _stopTrash = false;

  int? lastMoved;
  int failedCount = 0;
  String? failedReason;

  DuplicateScanHandle? _handle;
  int _generation = 0;

  bool get scanning => status == DuplicateStatus.scanning;
  int get wastedBytes => groups.fold(0, (s, g) => s + g.wastedBytes);
  int get duplicateFiles => groups.fold(0, (s, g) => s + g.files.length);

  int get selectedBytes {
    var sum = 0;
    for (final g in groups) {
      for (final f in g.files) {
        if (selected.contains(f.path)) sum += f.bytes;
      }
    }
    return sum;
  }

  /// [path]를 더 고를 수 있는지: 같은 묶음에서 고르지 않은 것이 하나는 남아야 한다.
  bool canSelect(DuplicateGroup group, String path) {
    if (selected.contains(path)) return true;
    return group.files.where((f) => !selected.contains(f.path)).length > 1;
  }

  Future<void> scan([String? root]) async {
    final target = root ?? folder;
    if (target == null || scanning || trashing) return;
    final gen = ++_generation;
    folder = target;
    status = DuplicateStatus.scanning;
    progress = null;
    error = null;
    groups = [];
    scannedFiles = 0;
    unreadable = 0;
    selected.clear();
    _clearNotices();
    notifyListeners();
    try {
      final handle = await _starter(target, (p) {
        if (gen != _generation) return;
        progress = p;
        scannedFiles = p.files;
        notifyListeners();
      }, (g) {
        if (gen != _generation) return;
        groups = [...groups, g];
        notifyListeners();
      });
      _handle = handle;
      final r = await handle.result;
      if (gen != _generation) return;
      if (r == null) {
        // 멈췄다: 그때까지 찾은 묶음은 그대로 보여 준다.
        status = DuplicateStatus.cancelled;
      } else {
        // 찾는 대로 받아 둔 묶음이 곧 결과다 (찾는 중에 휴지통으로 보낸 파일이 되살아나지 않게 r.groups 로 바꾸지 않는다).
        scannedFiles = r.scannedFiles;
        unreadable = r.unreadable;
        status = DuplicateStatus.done;
      }
    } on Object catch (e) {
      error = e;
      status = DuplicateStatus.failed;
    } finally {
      if (gen == _generation) {
        _handle = null;
        if (status == DuplicateStatus.scanning) status = DuplicateStatus.cancelled;
        _sort();
        notifyListeners();
      }
    }
  }

  /// 찾기를 멈춘다. 지금까지 찾은 묶음은 남는다.
  void cancel() => _handle?.cancel();

  void toggle(DuplicateGroup group, String path, bool on) {
    if (on) {
      if (!canSelect(group, path)) return;
      selected.add(path);
    } else {
      selected.remove(path);
    }
    notifyListeners();
  }

  /// 묶음마다 가장 오래된 하나만 남기고 나머지를 고른다.
  void selectAllButOldest() {
    selected.clear();
    for (final g in groups) {
      selected.addAll(g.files.skip(1).map((f) => f.path));
    }
    notifyListeners();
  }

  void clearSelection() {
    selected.clear();
    notifyListeners();
  }

  void dismissNotices() {
    _clearNotices();
    notifyListeners();
  }

  void _clearNotices() {
    lastMoved = null;
    failedCount = 0;
    failedReason = null;
    trashStopped = false;
  }

  /// 휴지통 보내기를 멈춘다. 지금 옮기는 파일까지만 끝나고, 남은 것은 선택된 채로 둔다.
  void stopTrash() {
    if (trashing) _stopTrash = true;
  }

  /// 파일 하나를 바로 휴지통으로 보낸다 (휴지통에서 되돌릴 수 있다).
  Future<void> trashOne(String path) => _trash({path});

  /// 고른 파일을 휴지통으로 보낸다.
  Future<void> trashSelected() => _trash({...selected});

  Future<void> _trash(Set<String> paths) async {
    if (trashing || paths.isEmpty) return;
    // 찾는 중에도 지울 수 있으므로 지금 보이는 묶음을 기준으로 한다.
    final bytesOf = <String, int>{};
    for (final g in groups) {
      final picks = g.files.where((f) => paths.contains(f.path)).toList();
      // 묶음이 통째로 골라졌으면 가장 오래된 것은 남긴다.
      if (picks.length == g.files.length) picks.removeAt(0);
      for (final f in picks) {
        bytesOf[f.path] = f.bytes;
      }
    }
    if (bytesOf.isEmpty) return;

    trashing = true;
    _stopTrash = false;
    trashDone = 0;
    trashTotal = bytesOf.length;
    trashCurrent = null;
    _clearNotices();
    notifyListeners();

    final failed = <String, String>{};
    final moved = <String>{};
    var movedBytes = 0;
    try {
      await for (final r in _trasher.trashAll(bytesOf.keys.toList())) {
        if (r.ok) {
          moved.add(r.path);
          movedBytes += bytesOf[r.path] ?? 0;
        } else {
          failed[r.path] = r.error!;
        }
        trashDone++;
        trashCurrent = r.path;
        notifyListeners();
        if (_stopTrash) break; // 구독을 끊으면 남은 파일은 보내지 않는다
      }
    } on Object catch (e) {
      // 남은 것을 모두 실패로 센다.
      for (final p in bytesOf.keys) {
        if (!moved.contains(p)) failed.putIfAbsent(p, () => '$e');
      }
    }
    // 멈춘 순간 옮기던 파일은 결과를 받기 전에 휴지통으로 갔을 수 있다: 없어졌으면 옮긴 것으로 센다.
    for (final p in bytesOf.keys) {
      if (moved.contains(p) || failed.containsKey(p)) continue;
      if (FileSystemEntity.typeSync(p, followLinks: false) == FileSystemEntityType.notFound) {
        moved.add(p);
        movedBytes += bytesOf[p]!;
      }
    }
    trashStopped = _stopTrash && moved.length + failed.length < trashTotal;
    _stopTrash = false;
    trashCurrent = null;

    groups = [
      for (final g in groups)
        if (g.files.where((f) => !moved.contains(f.path)).length > 1)
          DuplicateGroup(hash: g.hash, bytes: g.bytes, files: [for (final f in g.files) if (!moved.contains(f.path)) f]),
    ];
    selected.removeAll(moved);
    failedCount = failed.length;
    failedReason = failed.values.isEmpty ? null : failed.values.first;
    lastMoved = movedBytes > 0 ? movedBytes : null;
    trashing = false;

    if (moved.isNotEmpty) {
      final now = DateTime.now();
      final root = folder ?? '';
      onRecord?.call(HistoryEntry(
        id: '${now.microsecondsSinceEpoch}-duplicates',
        time: now,
        ruleId: 'duplicates',
        ruleName: root,
        kind: HistoryKind.duplicates,
        fileName: root,
        sourcePath: root,
        bytes: movedBytes,
        count: moved.length,
      ));
    }
    notifyListeners();
    if (moved.isNotEmpty) onChanged?.call();
  }

  void _sort() {
    if (scanning) return;
    groups.sort((a, b) {
      final c = b.wastedBytes.compareTo(a.wastedBytes);
      return c != 0 ? c : a.files.first.path.compareTo(b.files.first.path);
    });
  }

  @override
  void dispose() {
    _generation++;
    _handle?.kill();
    super.dispose();
  }
}
