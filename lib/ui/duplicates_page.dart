import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../cleaner/disk_info.dart';
import '../cleaner/format.dart';
import '../duplicates/duplicate_controller.dart';
import '../duplicates/duplicate_scanner.dart';
import '../engine/paths.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/broom_style.dart';
import 'broom/buttons.dart';
import 'broom/glass.dart';

/// 중복 파일: 폴더 고르기 → 내용으로 비교 → 똑같은 파일 묶음 보기 → (고른 것을) 휴지통으로.
class DuplicatesPage extends StatelessWidget {
  const DuplicatesPage({super.key, required this.controller, required this.disk, this.pickFolder});

  final DuplicateController controller;
  final DiskInfo disk;

  /// 폴더 고르기 창. 테스트에서 바꿔 끼운다.
  final Future<String?> Function(String? initial)? pickFolder;

  Future<void> _pick() async {
    final initial = controller.folder == null ? null : expandPath(controller.folder!);
    final path = await (pickFolder ?? ((i) => getDirectoryPath(initialDirectory: i)))(initial);
    if (path != null) await controller.scan(path);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Header(controller: controller, onPick: _pick),
          const SizedBox(height: AppSpacing.lg),
          ..._notices(context),
          Expanded(child: _body(context)),
          if (controller.groups.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), _Footer(controller: controller)],
        ]),
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
      if (c.status == DuplicateStatus.failed) notice(Icons.error_outline_rounded, l10n.dupFailed('${c.error}'), color: error),
      if (c.status == DuplicateStatus.cancelled && c.groups.isNotEmpty) notice(Icons.pause_circle_outline_rounded, l10n.dupCancelled),
      if (c.failedCount > 0) notice(Icons.error_outline_rounded, l10n.dupTrashFailed(c.failedCount, c.failedReason ?? ''), color: error),
      if (c.lastMoved != null) notice(Icons.check_circle_rounded, l10n.dupMoved(formatBytes(c.lastMoved!)), color: BroomAccent.mint),
      if (c.unreadable > 0 && c.status == DuplicateStatus.done) notice(Icons.lock_outline_rounded, l10n.dupUnreadable(c.unreadable)),
    ];
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    if (c.groups.isEmpty && !c.scanning) {
      final text = switch (c.status) {
        DuplicateStatus.done => l10n.dupNone(c.scannedFiles),
        DuplicateStatus.cancelled => l10n.dupCancelled,
        _ => l10n.dupIntro,
      };
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(c.status == DuplicateStatus.done ? Icons.check_circle_outline_rounded : Icons.copy_all_rounded,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (c.status == DuplicateStatus.idle) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.dupSkipNote, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
          ]),
        ),
      );
    }
    final groups = c.groups;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (c.scanning) ...[_ScanProgress(controller: c), const SizedBox(height: AppSpacing.md)],
      if (groups.isNotEmpty) ...[
        Row(children: [
          Expanded(
            child: Text(
              c.scanning
                  ? l10n.dupFoundSoFar(groups.length, c.duplicateFiles)
                  : l10n.dupSummary(groups.length, c.duplicateFiles, formatBytes(c.wastedBytes)),
              style: theme.textTheme.bodySmall,
            ),
          ),
          GhostButton(small: true, onPressed: c.trashing ? null : c.selectAllButOldest, label: l10n.dupSelectExtras),
          const SizedBox(width: AppSpacing.sm),
          GhostButton(
              small: true, onPressed: c.trashing || c.selected.isEmpty ? null : c.clearSelection, label: l10n.dupClearSelection),
        ]),
        const SizedBox(height: AppSpacing.md),
      ],
      Expanded(
        child: ListView.builder(
          itemCount: groups.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _GroupCard(key: ValueKey(groups[i].hash), controller: c, group: groups[i], root: c.folder ?? '', disk: disk),
          ),
        ),
      ),
    ]);
  }
}

/// 찾는 중: 진행 막대(비교 단계는 읽은 바이트 비율), 지금 보는 폴더·파일, 정지 단추.
class _ScanProgress extends StatelessWidget {
  const _ScanProgress({required this.controller});

  final DuplicateController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    final pr = c.progress;
    final hashing = pr != null && pr.phase == DuplicatePhase.hashing && pr.total > 0;
    final current = pr == null || pr.current.isEmpty ? '' : abbreviateHome(pr.current);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(
              hashing ? l10n.dupHashing(formatBytes(pr.done), formatBytes(pr.total)) : l10n.dupListing(pr?.files ?? 0),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: hashing ? (pr.done / pr.total).clamp(0.0, 1.0) : null, minHeight: 6),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              current,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.userContent.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
        const SizedBox(width: AppSpacing.lg),
        GradientButton(onPressed: c.cancel, icon: Icons.stop_rounded, label: l10n.dupStop, gradient: BroomAccent.danger),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.onPick});

  final DuplicateController controller;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    final busy = c.scanning || c.trashing;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.dupTitle, style: theme.textTheme.titleMedium),
          if (c.folder != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(abbreviateHome(c.folder!),
                style: AppFonts.userContent.copyWith(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
      if (c.folder == null)
        GradientButton(onPressed: busy ? null : onPick, icon: Icons.folder_open_rounded, label: l10n.dupPickFolder)
      else ...[
        GhostButton(onPressed: busy ? null : onPick, icon: Icons.folder_open_rounded, label: l10n.dupChangeFolder),
        const SizedBox(width: AppSpacing.sm),
        GhostButton(onPressed: busy ? null : () => c.scan(), icon: Icons.refresh_rounded, label: l10n.dupRescan),
      ],
    ]);
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({super.key, required this.controller, required this.group, required this.root, required this.disk});

  final DuplicateController controller;
  final DuplicateGroup group;
  final String root;
  final DiskInfo disk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final b = context.broom;
    final timeFormat = DateFormat.yMd(Localizations.localeOf(context).toString()).add_Hm();
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      radius: 12,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
          child: Row(children: [
            Expanded(
              child: Text(
                p.basename(group.files.first.path),
                style: AppFonts.userContent.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.dupGroupTitle(group.files.length, formatBytes(group.bytes)), style: theme.textTheme.bodySmall),
          ]),
        ),
        for (var i = 0; i < group.files.length; i++) ...[
          if (i > 0) Divider(color: b.border, height: 1),
          _FileRow(
            file: group.files[i],
            checked: controller.selected.contains(group.files[i].path),
            enabled: !controller.trashing && controller.canSelect(group, group.files[i].path),
            onChanged: (on) => controller.toggle(group, group.files[i].path, on),
            location: _relativeDir(group.files[i].path),
            modified: timeFormat.format(group.files[i].modified),
            oldest: i == 0,
            busy: controller.trashing,
            onReveal: () => disk.reveal(group.files[i].path),
            onTrash: () => controller.trashOne(group.files[i].path),
          ),
        ],
      ]),
    );
  }

  /// 고른 폴더 기준의 상대 위치. 바로 그 폴더면 폴더 이름.
  String _relativeDir(String path) {
    final dir = p.dirname(path);
    if (p.equals(dir, root)) return p.basename(root);
    return p.isWithin(root, dir) ? p.join(p.basename(root), p.relative(dir, from: root)) : abbreviateHome(dir);
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.checked,
    required this.enabled,
    required this.onChanged,
    required this.location,
    required this.modified,
    required this.oldest,
    required this.busy,
    required this.onReveal,
    required this.onTrash,
  });

  final DuplicateFile file;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String location;
  final String modified;
  final bool oldest;
  final bool busy;
  final VoidCallback onReveal;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget box = Opacity(
      opacity: enabled ? 1 : 0.35,
      child: IgnorePointer(ignoring: !enabled, child: BroomCheckbox(value: checked, onChanged: onChanged)),
    );
    if (!enabled) box = Tooltip(message: l10n.dupKeepOne, child: box);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(children: [
        box,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(p.basename(file.path),
                    style: AppFonts.userContent.copyWith(fontSize: 12.5), overflow: TextOverflow.ellipsis),
              ),
              if (oldest) ...[
                const SizedBox(width: AppSpacing.sm),
                Pill(l10n.dupOldest, color: theme.brightness == Brightness.light ? AppColors.successTextLight : BroomAccent.mint),
              ],
            ]),
            Text('$location  ·  $modified',
                style: AppFonts.userContent.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        IconButton(
          tooltip: Platform.isWindows ? l10n.dupRevealExplorer : l10n.dupRevealFinder,
          icon: const Icon(Icons.folder_open_rounded, size: 16),
          onPressed: onReveal,
        ),
        IconButton(
          tooltip: l10n.dupTrashOne,
          icon: Icon(Icons.delete_outline_rounded, size: 16, color: theme.colorScheme.error),
          onPressed: busy ? null : onTrash,
        ),
      ]),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final DuplicateController controller;

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dupConfirmTitle),
        content: Text(l10n.dupConfirmBody(c.selected.length, formatBytes(c.selectedBytes))),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.dupConfirmAction),
          ),
        ],
      ),
    );
    if (ok == true) await c.trashSelected();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = controller;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        Expanded(
          child: Text(
            c.trashing ? l10n.dupTrashing : l10n.dupSelectedSummary(c.selected.length, formatBytes(c.selectedBytes)),
            style: theme.textTheme.titleSmall,
          ),
        ),
        GradientButton(
          onPressed: c.trashing || c.selected.isEmpty ? null : () => _confirm(context),
          icon: Icons.delete_outline_rounded,
          label: l10n.dupTrash,
          gradient: BroomAccent.danger,
          large: true,
        ),
      ]),
    );
  }
}
