import 'package:flutter/foundation.dart';

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
  UsageController({Future<UsageScanHandle> Function(String root, void Function(UsageProgress) onProgress)? starter})
      : _starter = starter ?? ((root, onProgress) => startUsageScan(root, onProgress: onProgress));

  final Future<UsageScanHandle> Function(String root, void Function(UsageProgress) onProgress) _starter;
  final Map<String, VolumeUsage> _volumes = {};
  String? _activeRoot;
  UsageScanHandle? _handle;

  VolumeUsage of(String root) => _volumes.putIfAbsent(root, VolumeUsage.new);

  /// 지금 훑는 디스크가 있으면 그 경로.
  String? get scanning => _activeRoot;

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

  @override
  void dispose() {
    _handle?.kill();
    super.dispose();
  }
}
