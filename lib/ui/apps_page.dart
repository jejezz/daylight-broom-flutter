import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../cleaner/disk_info.dart';
import '../cleaner/format.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/broom_style.dart';
import '../uninstaller/apps_controller.dart';
import '../uninstaller/installed_app.dart';
import 'broom/buttons.dart';
import 'broom/glass.dart';

/// 앱 제거: 왼쪽에 앱 목록, 오른쪽에 고른 앱의 남은 파일. 제거는 휴지통으로 보낸다 (되돌릴 수 있다).
class AppsPage extends StatefulWidget {
  const AppsPage({super.key, required this.controller, required this.disk});

  final AppsController controller;
  final DiskInfo disk;

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  String _filter = '';

  @override
  void initState() {
    super.initState();
    // 처음 열 때 한 번 읽는다. 빌드 중에 알리지 않도록 미룬다.
    if (!widget.controller.loaded) Future.microtask(widget.controller.load);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final b = context.broom;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final shown = c.apps.where((a) => a.name.toLowerCase().contains(_filter.toLowerCase())).toList();
        return Row(children: [
          SizedBox(
            width: 260,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.md, AppSpacing.md),
                child: Row(children: [
                  Expanded(child: Text(l10n.appsTitle, style: theme.textTheme.titleMedium)),
                  Text('${c.apps.length}', style: theme.textTheme.bodySmall),
                  IconButton(
                    tooltip: l10n.appsRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: c.loading ? null : c.load,
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.md, AppSpacing.sm),
                child: TextField(
                  onChanged: (v) => setState(() => _filter = v),
                  decoration: InputDecoration(
                    hintText: l10n.appsSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: c.loading && c.apps.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                    : shown.isEmpty && c.loaded
                        ? Center(child: Text(l10n.appsEmpty, style: theme.textTheme.bodySmall))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.md),
                            itemCount: shown.length,
                            itemBuilder: (_, i) => _AppRow(
                              app: shown[i],
                              selected: shown[i].path == c.selected?.path,
                              onTap: () => c.select(shown[i]),
                            ),
                          ),
              ),
            ]),
          ),
          Container(width: 1, color: b.border),
          Expanded(child: c.selected == null ? _Empty(text: l10n.appsSelectHint) : _Detail(controller: c, disk: widget.disk)),
        ]);
      },
    );
  }
}

class _AppRow extends StatefulWidget {
  const _AppRow({required this.app, required this.selected, required this.onTap});

  final InstalledApp app;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<_AppRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = context.broom;
    final sel = widget.selected;
    final fg = sel ? Colors.white : theme.colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: sel,
      label: widget.app.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: sel ? BroomAccent.accent : null,
              color: sel ? null : (_hover ? b.glassHover : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              boxShadow: sel ? b.glow(BroomAccent.violet, blur: 16, alpha: 0.45) : null,
            ),
            child: Row(children: [
              Expanded(
                child: Text(widget.app.name,
                    style: AppFonts.userContent.copyWith(fontSize: 13, color: fg), overflow: TextOverflow.ellipsis),
              ),
              Text(formatBytes(widget.app.bytes),
                  style: TextStyle(fontSize: 11, color: sel ? Colors.white70 : theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.apps_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: AppSpacing.md),
        Text(text, style: theme.textTheme.bodySmall),
      ]),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.controller, required this.disk});

  final AppsController controller;
  final DiskInfo disk;

  static String get _home => Platform.environment['HOME'] ?? '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    final app = c.selected!;
    final error = theme.colorScheme.error;
    final hasNameMatches = c.leftovers.any((l) => l.match == LeftoverMatch.name);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: BroomAccent.cool,
              borderRadius: BorderRadius.circular(14),
              boxShadow: context.broom.glow(BroomAccent.cyan, blur: 18),
            ),
            child: const Icon(Icons.apps_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.name, style: AppFonts.userContent.copyWith(fontSize: 20, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                '${app.bundleId ?? l10n.appsNoBundleId}${app.version == null ? '' : '  ·  ${l10n.appsVersion(app.version!)}'}',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ]),
      ),
      if (c.failedCount > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
          child: Text(l10n.appsFailed(c.failedCount, c.failedReason ?? ''), style: theme.textTheme.bodySmall?.copyWith(color: error)),
        ),
      if (c.lastMoved != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
          child: GradientText(l10n.appsMoved(formatBytes(c.lastMoved!)),
              style: theme.textTheme.titleSmall!, gradient: BroomAccent.success),
        ),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.md), children: [
          GlassCard(
            padding: EdgeInsets.zero,
            radius: 12,
            child: _Row(
              checked: c.removeBundle,
              onChanged: c.setRemoveBundle,
              title: p.basename(app.path),
              subtitle: p.dirname(app.path),
              bytes: app.bytes,
              path: app.path,
              disk: disk,
              bold: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.lg, AppSpacing.xs, AppSpacing.sm),
            child: Text(l10n.appsLeftoversTitle(c.leftovers.length), style: theme.textTheme.labelMedium),
          ),
          if (c.findingLeftovers)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppSpacing.md),
                Text(l10n.appsFinding, style: theme.textTheme.bodySmall),
              ]),
            )
          else if (c.leftovers.isEmpty)
            Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Text(l10n.appsLeftoversNone, style: theme.textTheme.bodySmall))
          else ...[
            GlassCard(
              padding: EdgeInsets.zero,
              radius: 12,
              child: Column(children: [
                for (var i = 0; i < c.leftovers.length; i++) ...[
                  if (i > 0) Divider(color: context.broom.border),
                  _Row(
                    checked: c.selectedLeftovers.contains(c.leftovers[i].path),
                    onChanged: (v) => c.toggleLeftover(c.leftovers[i].path, v),
                    title: p.basename(c.leftovers[i].path),
                    subtitle: p.dirname(c.leftovers[i].path).replaceFirst(_home, '~'),
                    bytes: c.leftovers[i].bytes,
                    path: c.leftovers[i].path,
                    disk: disk,
                    badge: c.leftovers[i].match == LeftoverMatch.name ? l10n.appsMatchName : null,
                  ),
                ],
              ]),
            ),
            if (hasNameMatches)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.md, AppSpacing.xs, 0),
                child: Text(l10n.appsLeftoversNameHint, style: theme.textTheme.bodySmall),
              ),
          ],
        ]),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.broom.border))),
        child: Row(children: [
          Expanded(child: Text(l10n.appsToRemove(formatBytes(c.uninstallBytes)), style: theme.textTheme.titleSmall)),
          GradientButton(
            label: c.uninstalling ? l10n.appsUninstalling : l10n.appsUninstall,
            icon: Icons.delete_outline_rounded,
            gradient: BroomAccent.danger,
            large: true,
            onPressed: c.uninstalling || c.uninstallCount == 0 ? null : () => _confirm(context),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appsConfirmTitle(controller.selected!.name)),
        content: Text(l10n.appsConfirmBody(controller.uninstallCount, formatBytes(controller.uninstallBytes))),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.appsConfirmAction),
          ),
        ],
      ),
    );
    if (ok == true) await controller.uninstall();
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.checked,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.bytes,
    required this.path,
    required this.disk,
    this.bold = false,
    this.badge,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;
  final int bytes;
  final String path;
  final DiskInfo disk;
  final bool bold;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Row(children: [
        BroomCheckbox(value: checked, onChanged: onChanged),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(title,
                    style: AppFonts.userContent.copyWith(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              if (badge != null) ...[const SizedBox(width: AppSpacing.sm), Pill(badge!, color: Theme.of(context).brightness == Brightness.light ? AppColors.warningTextLight : BroomAccent.amber)],
            ]),
            Text(subtitle, style: AppFonts.userContent.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
          ]),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).appsReveal,
          icon: const Icon(Icons.folder_open_rounded, size: 16),
          onPressed: () => disk.revealInFinder(path),
        ),
        SizedBox(width: 72, child: Text(formatBytes(bytes), style: theme.textTheme.bodySmall, textAlign: TextAlign.right)),
      ]),
    );
  }
}
