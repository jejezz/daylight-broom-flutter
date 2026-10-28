import 'package:flutter/material.dart';

import '../app_identity.dart';
import '../cleaner/disk_info.dart';
import '../cleaner/junk_controller.dart';
import '../cleaner/scan_target.dart';
import '../cleaner/scanner.dart';
import '../diskusage/usage_cache.dart';
import '../diskusage/usage_controller.dart';
import '../engine/tidy_service.dart';
import '../uninstaller/app_scanner.dart';
import '../uninstaller/app_trasher.dart';
import '../uninstaller/apps_controller.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings_menus.dart';
import '../system/login_item.dart';
import '../theme/app_theme.dart';
import '../window/focus_tint.dart';
import 'apps_page.dart';
import 'broom/glass.dart';
import 'broom/nav_rail.dart';
import 'cleanup_options_button.dart';
import 'home_screen.dart';
import 'junk_page.dart';
import 'login_item_button.dart';
import 'overview_page.dart';
import 'storage_page.dart';

/// 앱의 뼈대: 왼쪽 NavRail + 오른쪽 페이지. 페이지는 목록(`_pages`)에서 고르므로
/// 정크·앱 제거 같은 새 기능은 항목 하나를 더하면 레일에 나타난다.
class BroomShell extends StatefulWidget {
  const BroomShell({super.key, required this.onAbout, required this.service, required this.loginItem, this.homeKey, this.junk, this.disk, this.apps, this.usage});

  final VoidCallback onAbout;
  final TidyService service;
  final LoginItemController loginItem;

  /// 트레이 메뉴의 "지금 정리"가 자동 정리 화면을 부르기 위한 키.
  final GlobalKey<HomeScreenState>? homeKey;

  /// 정크 정리 상태. null 이면 이 OS 용으로 만든다 (지원하지 않는 OS 면 정크 페이지가 없다).
  final JunkController? junk;

  /// 디스크 상태. null 이면 만들어 쓴다.
  final DiskController? disk;

  /// 앱 제거 상태. null 이면 이 OS 용으로 만든다 (지금은 macOS 만 지원).
  final AppsController? apps;

  /// 디스크 분석 상태. null 이면 만들어 쓴다.
  final UsageController? usage;

  @override
  State<BroomShell> createState() => _BroomShellState();
}

class _BroomShellState extends State<BroomShell> {
  int _index = 0;

  /// 앱 제거 화면은 처음 열 때에야 앱 목록을 읽는다 (시작할 때마다 /Applications 를 훑지 않도록).
  bool _appsVisited = false;
  late final DiskController _disk = widget.disk ?? DiskController(DiskInfo());
  late final bool _ownsDisk = widget.disk == null;
  late final JunkController? _junk = widget.junk ??
      (CleanerPlatform.current == null ? null : JunkController(scanner: JunkScanner(), onCleaned: _disk.refresh, onRecord: widget.service.recordActivity));
  late final bool _ownsJunk = widget.junk == null;
  late final AppsController? _apps = widget.apps ??
      (CleanerPlatform.current == CleanerPlatform.macos
          ? AppsController(
              scanner: AppScanner(ownBundleId: AppIdentity.bundleId),
              trasher: SystemAppTrasher(),
              onChanged: _disk.refresh,
              onRecord: widget.service.recordActivity,
            )
          : null);
  late final bool _ownsApps = widget.apps == null;
  late final UsageController _usage = widget.usage ?? UsageController(cache: UsageCache.standard(), onTrashed: _disk.refresh);
  late final bool _ownsUsage = widget.usage == null;

  @override
  void initState() {
    super.initState();
    _disk.refresh();
  }

  @override
  void dispose() {
    if (_ownsJunk) _junk?.dispose();
    if (_ownsApps) _apps?.dispose();
    if (_ownsUsage) _usage.dispose();
    if (_ownsDisk) _disk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final junk = _junk;
    final apps = _apps;
    if (apps != null && _index == (junk != null ? 3 : 2)) _appsVisited = true;
    final items = [
      NavItem(icon: Icons.donut_large_rounded, label: l10n.navOverview),
      NavItem(icon: Icons.auto_awesome_rounded, label: l10n.navTidy),
      if (junk != null) NavItem(icon: Icons.cleaning_services_rounded, label: l10n.navJunk),
      if (apps != null) NavItem(icon: Icons.apps_rounded, label: l10n.navApps),
      NavItem(icon: Icons.pie_chart_rounded, label: l10n.navStorage), // 맨 뒤: 앞 페이지들의 번호가 밀리지 않게
    ];
    final pages = [
      OverviewPage(
        disk: _disk,
        junk: junk,
        service: widget.service,
        onGoToJunk: () => setState(() => _index = 2),
        onGoToTidy: () => setState(() => _index = 1),
        onGoToStorage: () => setState(() => _index = items.length - 1),
      ),
      HomeScreen(key: widget.homeKey, service: widget.service),
      if (junk != null) JunkPage(controller: junk),
      if (apps != null) (_appsVisited ? AppsPage(controller: apps, disk: _disk.info) : const SizedBox.shrink()),
      StoragePage(disk: _disk, usage: _usage, active: _index == items.length - 1),
    ];
    // 레일이 창 높이 전체를 쓰고, 앱 바는 오른쪽 내용 위에만 둔다.
    return Material(
      color: Colors.transparent,
      child: BroomBackground(
        child: Row(children: [
          NavRail(
            index: _index,
            onChanged: (i) => setState(() => _index = i),
            items: items,
            footer: [NavItem(icon: Icons.info_outline_rounded, label: l10n.aboutTooltip)],
            footerActions: [widget.onAbout],
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                flexibleSpace: const FocusTint(),
                title: const Text(AppIdentity.displayName),
                actions: [
                  LoginItemMenuButton(controller: widget.loginItem),
                  const CleanupOptionsButton(),
                  const ThemeMenuButton(),
                  const LanguageMenuButton(),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              // 모두 마운트해 두어야 트레이의 "지금 정리"가 어느 탭에서든 자동 정리 화면에 닿는다.
              body: IndexedStack(index: _index, children: pages),
            ),
          ),
        ]),
      ),
    );
  }
}
