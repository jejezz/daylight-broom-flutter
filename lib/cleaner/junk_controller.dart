import 'package:flutter/foundation.dart';

import 'deleter.dart';
import 'scan_target.dart';
import 'scanner.dart';

/// 정크 화면의 상태: 스캔 결과, 선택, 정리 진행. 화면은 이것을 읽고 메서드를 부른다.
class JunkController extends ChangeNotifier {
  JunkController({required JunkScanner scanner, PermanentDeleter? deleter, this.onCleaned})
      : _scanner = scanner,
        _deleter = deleter ?? PermanentDeleter(allowedRoots: scanner.roots);

  final JunkScanner _scanner;
  final PermanentDeleter _deleter;

  /// 정리가 끝날 때마다 부른다 (개요의 디스크 용량을 다시 읽는 데 쓴다).
  final VoidCallback? onCleaned;

  bool scanning = false;
  bool scanned = false;
  List<JunkItem> items = const [];
  final Set<String> selected = {};
  List<String> unreadable = const [];
  Set<String> restricted = const {};
  Object? scanError;

  bool cleaning = false;
  int cleanDone = 0;
  int cleanTotal = 0;
  int cleanFreedBytes = 0;

  /// 방금 정리로 확보한 용량. 화면이 알려 준 뒤 [dismissFreed]로 지운다.
  int? lastFreed;

  /// 지우지 못한 항목 수와 첫 이유.
  int failedCount = 0;
  String? failedReason;

  int get selectedBytes => items.where((i) => selected.contains(i.path)).fold(0, (s, i) => s + i.bytes);
  int get totalBytes => items.fold(0, (s, i) => s + i.bytes);

  /// 선택된 것 중 확인이 필요한 항목 (영구 삭제 전 경고에 쓴다).
  List<JunkItem> get selectedReviewItems =>
      [for (final i in items) if (selected.contains(i.path) && i.target.safety == Safety.review) i];

  Future<void> scan() async {
    if (scanning || cleaning) return;
    scanning = true;
    items = const [];
    selected.clear();
    scanError = null;
    lastFreed = null;
    failedCount = 0;
    failedReason = null;
    notifyListeners();
    try {
      await for (final r in _scanner.scan()) {
        items = r.items;
        unreadable = r.unreadable;
        restricted = r.restricted;
        // 안전한 것만 미리 선택하고, 확인이 필요한 것은 비워 둔다.
        selected
          ..clear()
          ..addAll([for (final i in r.items) if (i.target.safety != Safety.review) i.path]);
        notifyListeners();
      }
    } on Object catch (e) {
      scanError = e;
    } finally {
      scanning = false;
      scanned = true;
      notifyListeners();
    }
  }

  void toggle(String path, bool on) {
    on ? selected.add(path) : selected.remove(path);
    notifyListeners();
  }

  void toggleTarget(ScanTarget target, bool on) {
    for (final i in items.where((i) => i.target.id == target.id)) {
      on ? selected.add(i.path) : selected.remove(i.path);
    }
    notifyListeners();
  }

  void dismissFreed() {
    lastFreed = null;
    notifyListeners();
  }

  /// 선택한 항목을 영구 삭제한다. 확보한 바이트를 돌려준다.
  Future<int> cleanSelected() async {
    if (cleaning || selected.isEmpty) return 0;
    final chosen = [for (final i in items) if (selected.contains(i.path)) i];
    cleaning = true;
    cleanDone = 0;
    cleanTotal = chosen.length;
    cleanFreedBytes = 0;
    failedCount = 0;
    failedReason = null;
    notifyListeners();

    final failed = <String, String>{};
    // 항목 하나씩 불러서 화면이 진행률을 그릴 수 있게 한다.
    for (final item in chosen) {
      failed.addAll(await _deleter.delete([item.path]));
      cleanDone++;
      if (!failed.containsKey(item.path)) cleanFreedBytes += item.bytes;
      notifyListeners();
    }

    items = [for (final i in items) if (!selected.contains(i.path) || failed.containsKey(i.path)) i];
    selected.retainAll(failed.keys);
    failedCount = failed.length;
    failedReason = failed.values.isEmpty ? null : failed.values.first;
    cleaning = false;
    lastFreed = cleanFreedBytes;
    notifyListeners();
    onCleaned?.call();
    return cleanFreedBytes;
  }
}
