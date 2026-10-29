import 'package:flutter/foundation.dart';

import '../engine/file_ops.dart';
import 'file_category.dart';
import 'usage_cache.dart';
import 'usage_model.dart';
import 'usage_scanner.dart';

enum UsageStatus { idle, scanning, done, cancelled, failed }

/// 디스크 하나의 분석 상태.
class VolumeUsage {
  UsageStatus status = UsageStatus.idle;
  UsageProgress? progress;
  DiskUsage? result;
}

/// 디스크별 상세 분석. 한 번에 하나만 훑는다 (디스크를 동시에 읽으면 서로 느려진다).
class UsageController extends ChangeNotifier {
  UsageController({
    Future<UsageScanHandle> Function(String root, void Function(UsageProgress) onProgress)? starter,
    this.cache,
    FileOps? ops,
    this.onTrashed,
  })  : _ops = ops ?? SystemFileOps(),
        _starter = starter ?? ((root, onProgress) => startUsageScan(root, onProgress: onProgress));

  final Future<UsageScanHandle> Function(String root, void Function(UsageProgress) onProgress) _starter;

  /// 지난 분석 결과를 저장해 두는 곳. null 이면 저장하지 않는다.
  final UsageCache? cache;
  final FileOps _ops;

  /// 휴지통으로 보낸 뒤 (디스크 여유 용량을 다시 읽는 데 쓴다).
  final VoidCallback? onTrashed;
  final Map<String, VolumeUsage> _volumes = {};
  final Set<String> _restored = {};
  String? _activeRoot;
  UsageScanHandle? _handle;

  VolumeUsage of(String root) => _volumes.putIfAbsent(root, VolumeUsage.new);

  /// 지금 훑는 디스크가 있으면 그 경로.
  String? get scanning => _activeRoot;

  /// 저장해 둔 지난 결과가 있고 아직 이번 실행에서 분석하지 않았으면 불러온다 (디스크마다 한 번만).
  Future<void> restore(String root) async {
    final c = cache;
    if (c == null || !_restored.add(root)) return;
    final v = of(root);
    if (v.result != null || v.status == UsageStatus.scanning) return;
    final saved = await c.load(root);
    // 읽는 동안 분석이 시작됐거나 끝났다면 그 결과가 더 새롭다.
    if (saved == null || v.result != null || v.status == UsageStatus.scanning) return;
    v.result = saved;
    v.status = UsageStatus.done;
    notifyListeners();
  }

  Future<void> scan(String root) async {
    if (_activeRoot != null) return;
    final v = of(root);
    v.status = UsageStatus.scanning;
    v.progress = null;
    _activeRoot = root;
    notifyListeners();
    try {
      final handle = await _starter(root, (p) {
        v.progress = p;
        notifyListeners();
      });
      _handle = handle;
      final result = await handle.result;
      if (result == null) {
        v.status = UsageStatus.cancelled;
      } else {
        v.result = result;
        v.status = UsageStatus.done;
        try {
          await cache?.save(result);
        } on Object {
          // 저장하지 못해도 화면의 결과는 그대로 쓴다.
        }
      }
    } on Object {
      v.status = UsageStatus.failed;
    } finally {
      _handle = null;
      _activeRoot = null;
      notifyListeners();
    }
  }

  void cancel() => _handle?.cancel();

  /// [path]를 휴지통으로 보내고 분석 결과에서 뺀다. 실패하면 이유를, 성공하면 null.
  /// 파일이면 [category]와 [bytes]를 줘야 그 종류에서 정확히 뺄 수 있다.
  Future<String?> trash(String root, String path, {required bool isDirectory, FileCategory? category, int bytes = 0}) async {
    final usage = of(root).result;
    if (usage == null) return null;
    try {
      await _ops.trash(path);
    } on Object catch (e) {
      return '$e';
    }
    if (isDirectory) {
      usage.removeDirectory(path);
    } else if (category != null) {
      usage.removeFile(category, path, bytes);
    }
    notifyListeners();
    onTrashed?.call();
    try {
      await cache?.save(usage);
    } on Object {
      // 저장하지 못해도 화면은 그대로 쓴다.
    }
    return null;
  }

  @override
  void dispose() {
    _handle?.kill();
    super.dispose();
  }
}
