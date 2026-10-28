import 'package:flutter/material.dart';

import '../cleaner/disk_info.dart';
import '../cleaner/format.dart';
import '../cleaner/junk_controller.dart';
import '../engine/tidy_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/broom_style.dart';
import 'broom/buttons.dart';
import 'broom/disk_ring.dart';
import 'broom/glass.dart';
import 'fda_guide.dart';

/// 개요: 디스크 사용량 링, 지금 선택한 정크를 정리하면 확보되는 용량 미리보기, 바로가기.
class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.disk,
    required this.junk,
    required this.service,
    required this.onGoToJunk,
    required this.onGoToTidy,
    this.onGoToStorage,
  });

  final DiskController disk;
  final JunkController? junk;
  final TidyService service;
  final VoidCallback onGoToJunk;
  final VoidCallback onGoToTidy;
  final VoidCallback? onGoToStorage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([disk, service, ?junk]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final v = disk.volume;
        final j = junk;
        final onSystemDisk = v == null || v.isSystem; // 정크 정리는 시스템 디스크의 사용자 영역만 다룬다
        final selected = onSystemDisk ? (j?.selectedBytes ?? 0) : 0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(l10n.overviewTitle, style: theme.textTheme.titleMedium)),
              GhostButton(label: l10n.overviewRefresh, icon: Icons.refresh_rounded, small: true, onPressed: disk.refresh),
            ]),
            const SizedBox(height: AppSpacing.lg),
            if (disk.volumes.length > 1) ...[
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                for (final d in disk.volumes)
                  ChoiceChip(
                    label: Text('${d.name} · ${formatBytes(d.total)}'),
                    selected: d.path == v?.path,
                    onSelected: (_) => disk.select(d),
                  ),
              ]),
              const SizedBox(height: AppSpacing.lg),
            ],
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              glowColor: BroomAccent.violet,
              child: Row(children: [
                DiskRing(
                  usedRatio: v?.usedRatio ?? 0,
                  extraRatio: v == null || v.total == 0 ? 0 : selected / v.total,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    GradientText(v == null ? '—' : '${(v.usedRatio * 100).round()}%',
                        style: theme.textTheme.headlineMedium!.copyWith(fontSize: 30), gradient: BroomAccent.cool),
                    Text(l10n.overviewUsedPercent, style: theme.textTheme.bodySmall),
                  ]),
                ),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Stat(label: l10n.overviewFree, value: v == null ? '—' : formatBytes(v.free), color: BroomAccent.mint),
                    _Stat(label: l10n.overviewUsed, value: v == null ? '—' : formatBytes(v.used), color: BroomAccent.violet),
                    _Stat(label: l10n.overviewTotal, value: v == null ? '—' : formatBytes(v.total), color: theme.colorScheme.onSurfaceVariant),
                    if (j != null && onSystemDisk) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Divider(color: context.broom.border),
                      const SizedBox(height: AppSpacing.sm),
                      _Stat(
                        label: l10n.overviewJunkFound,
                        value: j.items.isEmpty
                            ? (j.scanning ? l10n.overviewJunkScanning : (j.scanned ? formatBytes(0) : l10n.overviewJunkNotScanned))
                            : formatBytes(j.totalBytes),
                        color: BroomAccent.pink,
                      ),
                      if (selected > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(l10n.overviewFreeable(formatBytes(selected)), style: theme.textTheme.bodySmall),
                        ),
                    ],
                    if (disk.loaded && v == null)
                      Text(l10n.overviewUnavailable, style: theme.textTheme.bodySmall),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              if (j != null)
                Expanded(
                  child: _ActionCard(
                    icon: Icons.cleaning_services_rounded,
                    gradient: BroomAccent.accent,
                    title: l10n.overviewCardJunkTitle,
                    subtitle: l10n.overviewCardJunkSubtitle,
                    onTap: j.scanning || j.cleaning
                        ? null
                        : () {
                            onGoToJunk();
                            if (!j.scanned) j.scan();
                          },
                  ),
                ),
              if (j != null) const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _ActionCard(
                  icon: Icons.auto_awesome_rounded,
                  gradient: BroomAccent.cool,
                  title: l10n.overviewCardTidyTitle,
                  subtitle: l10n.overviewCardTidySubtitle(service.rules.where((r) => r.enabled).length),
                  onTap: onGoToTidy,
                ),
              ),
            ]),
            if (onGoToStorage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ActionCard(
                icon: Icons.pie_chart_rounded,
                gradient: BroomAccent.success,
                title: l10n.storageTitle,
                subtitle: l10n.storageIntro,
                onTap: onGoToStorage,
              ),
            ],
            if (disk.fullDiskAccess == false) ...[
              const SizedBox(height: AppSpacing.lg),
              _FdaBanner(
                onHelp: () => showFdaGuide(context, info: disk.info, onGranted: disk.refresh),
                onOpenSettings: disk.info.openFullDiskAccessSettings,
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: context.broom.glow(color, blur: 8, alpha: 0.8)),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(width: 96, child: Text(label, style: theme.textTheme.bodySmall)),
        Flexible(child: Text(value, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({required this.icon, required this.gradient, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: widget.title,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hover && enabled ? 1.02 : 1,
            duration: const Duration(milliseconds: 150),
            child: GlassCard(
              glowColor: _hover && enabled ? widget.gradient.colors.first : null,
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: context.broom.glow(widget.gradient.colors.first, blur: 18),
                  ),
                  child: Icon(widget.icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _FdaBanner extends StatelessWidget {
  const _FdaBanner({required this.onHelp, required this.onOpenSettings});

  final VoidCallback onHelp;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warn = theme.brightness == Brightness.light ? AppColors.warningTextLight : BroomAccent.amber;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: BroomAccent.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BroomAccent.amber.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, size: 18, color: warn),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(l10n.fdaBannerText, style: theme.textTheme.bodySmall)),
        const SizedBox(width: AppSpacing.md),
        GradientButton(label: l10n.fdaShowMe, icon: Icons.help_outline_rounded, onPressed: onHelp),
        const SizedBox(width: AppSpacing.sm),
        GhostButton(label: l10n.fdaOpenSettings, small: true, onPressed: onOpenSettings),
      ]),
    );
  }
}
