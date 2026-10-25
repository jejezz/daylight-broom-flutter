import 'package:flutter/material.dart';

import '../cleaner/format.dart';
import '../cleaner/junk_controller.dart';
import '../cleaner/scan_target.dart';
import '../cleaner/scanner.dart';
import '../cleaner/target_labels.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/broom_style.dart';
import 'broom/buttons.dart';
import 'broom/glass.dart';
import 'broom/safety_badge.dart';

/// 정크 정리 화면: 스캔 → 항목 고르기 → 영구 삭제 확인 → 정리.
class JunkPage extends StatelessWidget {
  const JunkPage({super.key, required this.controller});

  final JunkController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(controller: controller),
            const SizedBox(height: AppSpacing.lg),
            ..._notices(context),
            Expanded(child: _body(context)),
            if (controller.items.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), _Footer(controller: controller)],
          ],
        ),
      ),
    );
  }

  List<Widget> _notices(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = controller;
    final error = Theme.of(context).colorScheme.error;
    Widget notice(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(text, style: AppFonts.userContent.copyWith(fontSize: 12))),
            ]),
          ),
        );
    return [
      if (c.scanError != null) notice(Icons.error_outline_rounded, l10n.junkScanFailed('${c.scanError}'), color: error),
      if (c.failedCount > 0)
        notice(Icons.error_outline_rounded, l10n.junkFailed(c.failedCount, c.failedReason ?? ''), color: error),
      if (c.unreadable.isNotEmpty) notice(Icons.lock_outline_rounded, l10n.junkUnreadable(c.unreadable.join(', '))),
      if (c.restricted.isNotEmpty) notice(Icons.lock_outline_rounded, l10n.junkRestricted),
    ];
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    if (c.items.isEmpty) {
      if (c.scanning) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.junkScanning, style: theme.textTheme.bodySmall),
        ]));
      }
      if (c.lastFreed != null && c.lastFreed! > 0) return _freed(context);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(c.scanned ? Icons.check_circle_outline_rounded : Icons.cleaning_services_rounded,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(c.scanned ? l10n.junkEmptyScanned : l10n.junkIntro, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ]),
        ),
      );
    }
    return Column(children: [
      if (c.lastFreed != null && c.lastFreed! > 0) ...[_freedBanner(context), const SizedBox(height: AppSpacing.md)],
      Expanded(child: _list(context)),
    ]);
  }

  Widget _freed(BuildContext context) => Center(child: _freedBanner(context));

  Widget _freedBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      glowColor: BroomAccent.mint,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, color: BroomAccent.mint),
        const SizedBox(width: AppSpacing.md),
        GradientText(l10n.junkFreed(formatBytes(controller.lastFreed!)),
            style: Theme.of(context).textTheme.titleMedium!, gradient: BroomAccent.success),
      ]),
    );
  }

  Widget _list(BuildContext context) {
    final theme = Theme.of(context);
    final byTarget = <ScanTarget, List<JunkItem>>{};
    for (final i in controller.items) {
      byTarget.putIfAbsent(i.target, () => []).add(i);
    }
    final children = <Widget>[];
    for (final group in TargetGroup.values) {
      final targets = [for (final t in byTarget.keys) if (t.group == group) t];
      if (targets.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.md, 0, AppSpacing.sm),
        child: Text(_groupLabel(AppLocalizations.of(context), group), style: theme.textTheme.titleSmall),
      ));
      children.add(GlassCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(children: [
          for (final t in targets) _TargetBlock(controller: controller, target: t, items: byTarget[t]!),
        ]),
      ));
    }
    return ListView(children: children);
  }

  static String _groupLabel(AppLocalizations l10n, TargetGroup g) => switch (g) {
        TargetGroup.system => l10n.groupSystem,
        TargetGroup.developer => l10n.groupDeveloper,
        TargetGroup.browser => l10n.groupBrowser,
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final JunkController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    final busy = c.scanning || c.cleaning;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.junkTitle, style: theme.textTheme.titleMedium),
          if (c.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.junkTotalFound(formatBytes(c.totalBytes)), style: theme.textTheme.bodySmall),
          ],
        ]),
      ),
      if (c.items.isEmpty && !c.scanned)
        GradientButton(onPressed: busy ? null : c.scan, icon: Icons.search_rounded, label: l10n.junkScan)
      else
        GhostButton(onPressed: busy ? null : c.scan, icon: Icons.refresh_rounded, label: l10n.junkRescan),
    ]);
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final JunkController controller;

  Future<void> _clean(BuildContext context) async {
    final c = controller;
    final ok = await showJunkConfirm(context, controller: c);
    if (ok == true) await c.cleanSelected();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (c.cleaning) ...[
          LinearProgressIndicator(value: c.cleanTotal == 0 ? null : c.cleanDone / c.cleanTotal),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(children: [
          Expanded(
            child: Text(
              c.cleaning
                  ? l10n.junkCleaning(c.cleanDone, c.cleanTotal)
                  : l10n.junkSelectedSummary(c.selected.length, formatBytes(c.selectedBytes)),
              style: theme.textTheme.titleSmall,
            ),
          ),
          GradientButton(
            onPressed: c.cleaning || c.scanning || c.selected.isEmpty ? null : () => _clean(context),
            icon: Icons.delete_sweep_rounded,
            label: l10n.junkClean,
            gradient: BroomAccent.danger,
            large: true,
          ),
        ]),
      ]),
    );
  }
}

class _TargetBlock extends StatelessWidget {
  const _TargetBlock({required this.controller, required this.target, required this.items});

  final JunkController controller;
  final ScanTarget target;
  final List<JunkItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = targetLabels(AppLocalizations.of(context), target.id);
    final picked = items.where((i) => controller.selected.contains(i.path)).length;
    final bool? all = picked == 0 ? false : (picked == items.length ? true : null);
    final bytes = items.fold(0, (s, i) => s + i.bytes);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          BroomCheckbox(value: all, onChanged: (on) => controller.toggleTarget(target, on)),
          const SizedBox(width: AppSpacing.md),
          Flexible(child: Text(labels.title, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.sm),
          SafetyBadge(target.safety),
          const Spacer(),
          Text(formatBytes(bytes), style: theme.textTheme.titleSmall),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 2),
          child: Text(labels.description, style: theme.textTheme.bodySmall),
        ),
        if (target.listChildren && items.length > 1)
          for (final i in items.take(30))
            Padding(
              padding: const EdgeInsets.only(left: 30, top: AppSpacing.sm),
              child: Row(children: [
                BroomCheckbox(
                    value: controller.selected.contains(i.path), onChanged: (on) => controller.toggle(i.path, on)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(i.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.userContent.copyWith(fontSize: 12))),
                Text(formatBytes(i.bytes), style: theme.textTheme.bodySmall),
              ]),
            ),
        if (target.listChildren && items.length > 30)
          Padding(
            padding: const EdgeInsets.only(left: 30, top: AppSpacing.sm),
            child: Text('+${items.length - 30}', style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: AppSpacing.xs),
      ]),
    );
  }
}

/// 영구 삭제 확인. 휴지통을 거치지 않는다는 것과, 확인이 필요한 항목이 섞였다는 것을 알린다.
Future<bool?> showJunkConfirm(BuildContext context, {required JunkController controller}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final review = controller.selectedReviewItems;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.junkConfirmTitle),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.junkConfirmBody(controller.selected.length, formatBytes(controller.selectedBytes))),
        if (review.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.junkConfirmReview(review.map((i) => i.name).join(', ')),
            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w700),
          ),
        ],
      ]),
      actions: [
        TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.junkConfirmAction),
        ),
      ],
    ),
  );
}
