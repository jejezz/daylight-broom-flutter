import 'package:flutter/foundation.dart';

import '../engine/history.dart';

import 'app_scanner.dart';
import 'app_trasher.dart';
import 'installed_app.dart';

/// 앱 제거 화면의 상태: 앱 목록, 선택한 앱과 남은 파일, 제거 진행.
class AppsController extends ChangeNotifier {
  AppsController({required this.scanner, required this.trasher, this.onChanged, this.onRecord});

  final AppScanner scanner;
  final AppTrasher trasher;

  /// 앱을 제거해 디스크 상태가 바뀔 때 부른다.
  final VoidCallback? onChanged;

  /// 제거한 결과를 이력에 남기는 쪽. 옮긴 것이 하나도 없으면 부르지 않는다.
  final void Function(HistoryEntry entry)? onRecord;

  bool loading = false;
  bool loaded = false;
  List<InstalledApp> apps = const [];

  InstalledApp? selected;
  bool findingLeftovers = false;
  List<Leftover> leftovers = const [];
  final Set<String> selectedLeftovers = {};
  bool removeBundle = true;

  bool uninstalling = false;

  /// 방금 제거로 휴지통에 옮긴 용량 (화면이 알려 준 뒤 [dismissMoved]로 지운다).
  int? lastMoved;
  int failedCount = 0;
  String? failedReason;

  int get uninstallBytes =>
      (removeBundle ? selected?.bytes ?? 0 : 0) +
      leftovers.where((l) => selectedLeftovers.contains(l.path)).fold(0, (s, l) => s + l.bytes);

  int get uninstallCount => (removeBundle && selected != null ? 1 : 0) + selectedLeftovers.length;

  Future<void> load() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      apps = await scanner.listApps();
    } finally {
      loading = false;
      loaded = true;
    }
    // 새로 읽은 목록에서 선택을 다시 잡는다 (없어졌으면 해제).
    final sel = selected;
    if (sel != null) {
      final i = apps.indexWhere((a) => a.path == sel.path);
      if (i < 0) {
        _clearSelection();
      } else {
        selected = apps[i];
      }
    }
    notifyListeners();
  }

  void _clearSelection() {
    selected = null;
    leftovers = const [];
    selectedLeftovers.clear();
    removeBundle = true;
  }

  Future<void> select(InstalledApp? app) async {
    _clearSelection();
    selected = app;
    lastMoved = null;
    failedCount = 0;
    failedReason = null;
    if (app == null) {
      notifyListeners();
      return;
    }
    findingLeftovers = true;
    notifyListeners();
    final found = await scanner.findLeftovers(app);
    // 찾는 사이에 다른 앱을 골랐으면 이 결과는 버린다.
    if (selected?.path != app.path) return;
    leftovers = found;
    // 번들 id 로 찾은 것만 미리 선택한다. 이름으로 찾은 것은 직접 고르게 한다.
    selectedLeftovers.addAll([for (final l in found) if (l.match == LeftoverMatch.bundleId) l.path]);
    findingLeftovers = false;
    notifyListeners();
  }

  void toggleLeftover(String path, bool on) {
    on ? selectedLeftovers.add(path) : selectedLeftovers.remove(path);
    notifyListeners();
  }

  void setRemoveBundle(bool on) {
    removeBundle = on;
    notifyListeners();
  }

  void dismissMoved() {
    lastMoved = null;
    notifyListeners();
  }

  /// 선택한 앱과 남은 파일을 휴지통으로 옮긴다.
  Future<void> uninstall() async {
    final app = selected;
    if (app == null || uninstalling || uninstallCount == 0) return;
    uninstalling = true;
    failedCount = 0;
    failedReason = null;
    notifyListeners();

    final bytesByPath = {for (final l in leftovers) l.path: l.bytes, app.path: app.bytes};
    // 남은 파일을 먼저, 앱 번들을 마지막에: 중간에 실패해도 앱이 남아 다시 시도할 수 있다.
    final paths = [...selectedLeftovers, if (removeBundle) app.path];
    final failed = await trasher.trash(paths);

    final moved = paths.where((x) => !failed.containsKey(x)).fold<int>(0, (s, x) => s + (bytesByPath[x] ?? 0));
    failedCount = failed.length;
    failedReason = failed.values.isEmpty ? null : failed.values.first;
    lastMoved = moved > 0 ? moved : null;
    final movedCount = paths.length - failed.length;
    if (movedCount > 0) {
      final now = DateTime.now();
      onRecord?.call(HistoryEntry(
        id: '${now.microsecondsSinceEpoch}-uninstall',
        time: now,
        ruleId: 'uninstall',
        ruleName: app.name,
        kind: HistoryKind.uninstall,
        fileName: app.name,
        sourcePath: app.path,
        bytes: moved,
        count: movedCount,
      ));
    }

    if (removeBundle && !failed.containsKey(app.path)) {
      apps = [for (final a in apps) if (a.path != app.path) a];
      _clearSelection();
    } else {
      leftovers = [for (final l in leftovers) if (failed.containsKey(l.path) || !selectedLeftovers.contains(l.path)) l];
      selectedLeftovers.retainAll(failed.keys);
    }
    uninstalling = false;
    notifyListeners();
    onChanged?.call();
  }
}
