import 'package:flutter/material.dart';

import '../cleaner/disk_info.dart';
import '../cleaner/format.dart';
import '../diskusage/file_category.dart';
import '../diskusage/usage_controller.dart';
import '../diskusage/usage_model.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/broom_style.dart';
import 'broom/buttons.dart';
import 'broom/glass.dart';

Color _categoryColor(FileCategory c) => switch (c) {
      FileCategory.applications => BroomAccent.violet,
      FileCategory.documents => BroomAccent.cyan,
      FileCategory.music => BroomAccent.pink,
      FileCategory.video => BroomAccent.amber,
      FileCategory.other => BroomAccent.mint,
    };

IconData _categoryIcon(FileCategory c) => switch (c) {
      FileCategory.applications => Icons.apps_rounded,
      FileCategory.documents => Icons.description_outlined,
      FileCategory.music => Icons.music_note_rounded,
      FileCategory.video => Icons.movie_outlined,
      FileCategory.other => Icons.folder_open_rounded,
    };

String _categoryLabel(AppLocalizations l10n, FileCategory c) => switch (c) {
      FileCategory.applications => l10n.storageCatApplications,
      FileCategory.documents => l10n.storageCatDocuments,
      FileCategory.music => l10n.storageCatMusic,
      FileCategory.video => l10n.storageCatVideo,
      FileCategory.other => l10n.storageCatOther,
    };

/// 디스크 선택 → 종류 → 폴더로 내려가며 어디에 용량이 있는지 보여 준다.
class StoragePage extends StatefulWidget {
  const StoragePage({super.key, required this.disk, required this.usage});

  final DiskController disk;
  final UsageController usage;

  @override
  State<StoragePage> createState() => _StoragePageState();
}

/// 디스크마다 따로 기억하는 화면 위치.
class _Nav {
  FileCategory? category;
  String? dir;
}

class _StoragePageState extends State<StoragePage> {
  final Map<String, _Nav> _nav = {};

  _Nav _navOf(String root) => _nav.putIfAbsent(root, _Nav.new);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.disk, widget.usage]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final v = widget.disk.volume;
        final busyElsewhere = widget.usage.scanning != null && widget.usage.scanning != v?.path;
        final state = v == null ? null : widget.usage.of(v.path);
        final scanning = state?.status == UsageStatus.scanning;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(l10n.storageTitle, style: theme.textTheme.titleMedium)),
              if (v != null && scanning)
                GhostButton(label: l10n.storageCancel, icon: Icons.close_rounded, small: true, onPressed: widget.usage.cancel)
              else if (v != null && state!.result != null)
                GhostButton(
                    label: l10n.storageReanalyze,
                    icon: Icons.refresh_rounded,
                    small: true,
                    onPressed: busyElsewhere ? null : () => widget.usage.scan(v.path))
              else if (v != null)
                GradientButton(
                    label: l10n.storageAnalyze,
                    icon: Icons.search_rounded,
                    onPressed: busyElsewhere ? null : () => widget.usage.scan(v.path)),
            ]),
            const SizedBox(height: AppSpacing.lg),
            if (widget.disk.volumes.length > 1) ...[
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                for (final d in widget.disk.volumes)
                  ChoiceChip(
                    label: Text('${d.name} · ${formatBytes(d.total)}'),
                    selected: d.path == v?.path,
                    onSelected: (_) => widget.disk.select(d),
                  ),
              ]),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (v == null)
              Text(widget.disk.loaded ? l10n.storageNoDisk : '', style: theme.textTheme.bodySmall)
            else
              _body(context, v, state!),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext context, DiskVolume v, VolumeUsage state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (state.status == UsageStatus.scanning) {
      final p = state.progress;
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(children: [
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.storageScanning(p == null ? '0' : '${p.files}', formatBytes(p?.bytes ?? 0)), style: theme.textTheme.titleSmall),
              if (p != null) ...[
                const SizedBox(height: 2),
                Text(p.currentDir, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        ]),
      );
    }
    final result = state.result;
    if (result == null) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (state.status == UsageStatus.cancelled || state.status == UsageStatus.failed) ...[
            Text(state.status == UsageStatus.cancelled ? l10n.storageCancelled : l10n.storageFailed, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(l10n.storageIntro, style: theme.textTheme.bodyMedium),
        ]),
      );
    }

    final nav = _navOf(v.path);
    final category = nav.category;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Crumbs(
        volumeName: v.name,
        category: category,
        root: result.root,
        dir: nav.dir,
        separator: result.separator,
        onRoot: () => setState(() => nav..category = null..dir = null),
        onCategory: () => setState(() => nav.dir = result.root),
        onDir: (d) => setState(() => nav.dir = d),
      ),
      const SizedBox(height: AppSpacing.md),
      if (category == null)
        _Categories(result: result, onOpen: (c) => setState(() => nav..category = c..dir = result.root))
      else
        _Folders(
          result: result,
          category: category,
          dir: nav.dir ?? result.root,
          disk: widget.disk.info,
          onOpen: (d) => setState(() => nav.dir = d),
        ),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.storageScannedAt(_formatTime(result.scannedAt)), style: theme.textTheme.bodySmall),
      if (result.unreadable > 0) Text(l10n.storageUnreadable(result.unreadable), style: theme.textTheme.bodySmall),
    ]);
  }

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}

/// "디스크 › 종류 › 폴더 › 폴더" 경로. 어느 단계든 눌러서 돌아갈 수 있다.
class _Crumbs extends StatelessWidget {
  const _Crumbs({
    required this.volumeName,
    required this.category,
    required this.root,
    required this.dir,
    required this.separator,
    required this.onRoot,
    required this.onCategory,
    required this.onDir,
  });

  final String volumeName;
  final FileCategory? category;
  final String root;
  final String? dir;
  final String separator;
  final VoidCallback onRoot;
  final VoidCallback onCategory;
  final ValueChanged<String> onDir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final crumbs = <(String, VoidCallback?)>[(volumeName, category == null ? null : onRoot)];
    final c = category;
    if (c != null) {
      final inFolder = dir != null && dir != root;
      crumbs.add((_categoryLabel(l10n, c), inFolder ? onCategory : null));
      if (inFolder) {
        final base = root.endsWith(separator) ? root : '$root$separator';
        var path = root;
        final parts = dir!.substring(base.length).split(separator);
        for (var i = 0; i < parts.length; i++) {
          path = i == 0 ? '$base${parts[i]}' : '$path$separator${parts[i]}';
          final target = path;
          crumbs.add((parts[i], i == parts.length - 1 ? null : () => onDir(target)));
        }
      }
    }
    final theme = Theme.of(context);
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      for (var i = 0; i < crumbs.length; i++) ...[
        if (i > 0) Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
        InkWell(
          onTap: crumbs[i].$2,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(crumbs[i].$1,
                style: (crumbs[i].$2 == null ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
                    ?.copyWith(color: crumbs[i].$2 == null ? null : theme.colorScheme.primary)),
          ),
        ),
      ],
    ]);
  }
}

/// 1단계: 종류별 막대와 목록.
class _Categories extends StatelessWidget {
  const _Categories({required this.result, required this.onOpen});

  final DiskUsage result;
  final ValueChanged<FileCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = result.totalBytes;
    final sorted = [...FileCategory.values]..sort((a, b) => result.bytesOf(b).compareTo(result.bytesOf(a)));
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(children: [
              for (final c in sorted)
                if (result.bytesOf(c) > 0)
                  Expanded(flex: (result.bytesOf(c) * 1000 ~/ (total == 0 ? 1 : total)).clamp(1, 1000), child: ColoredBox(color: _categoryColor(c))),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final c in sorted)
          _Row(
            icon: _categoryIcon(c),
            color: _categoryColor(c),
            title: _categoryLabel(l10n, c),
            subtitle: l10n.storageFileCount(result.fileCounts[c.index]),
            bytes: result.bytesOf(c),
            fraction: total == 0 ? 0 : result.bytesOf(c) / total,
            onTap: result.bytesOf(c) == 0 ? null : () => onOpen(c),
          ),
      ]),
    );
  }
}

/// 2단계 이후: 한 종류 안에서 폴더별 크기. 폴더를 눌러 더 내려간다.
class _Folders extends StatelessWidget {
  const _Folders({required this.result, required this.category, required this.dir, required this.disk, required this.onOpen});

  final DiskUsage result;
  final FileCategory category;
  final String dir;
  final DiskInfo disk;
  final ValueChanged<String> onOpen;

  String _name(String path) {
    final cut = path.lastIndexOf(result.separator);
    return cut < 0 || cut == path.length - 1 ? path : path.substring(cut + 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = _categoryColor(category);
    final here = result.bytesUnder(category, dir);
    final kids = result.childrenOf(category, dir);
    final direct = result.directBytes(category, dir);
    final atRoot = dir == result.root;
    final tops = atRoot ? result.topFiles[category.index] : const <UsageFile>[];
    if (here == 0) {
      return GlassCard(child: Text(l10n.storageEmptyCategory, style: theme.textTheme.bodyMedium));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        glowColor: color,
        child: Column(children: [
          for (final k in kids)
            _Row(
              icon: Icons.folder_rounded,
              color: color,
              title: _name(k.path),
              bytes: k.bytes,
              fraction: here == 0 ? 0 : k.bytes / here,
              onTap: () => onOpen(k.path),
              onReveal: () => disk.reveal(k.path),
              revealTooltip: l10n.storageReveal,
            ),
          if (direct > 0)
            _Row(
              icon: Icons.insert_drive_file_outlined,
              color: color,
              title: l10n.storageDirectFiles,
              bytes: direct,
              fraction: here == 0 ? 0 : direct / here,
              onReveal: () => disk.reveal(dir),
              revealTooltip: l10n.storageReveal,
            ),
        ]),
      ),
      if (tops.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.storageLargestFiles, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(children: [
            for (final f in tops)
              _Row(
                icon: Icons.insert_drive_file_outlined,
                color: color,
                title: _name(f.path),
                subtitle: f.path.substring(0, f.path.length - _name(f.path).length),
                bytes: f.bytes,
                onReveal: () => disk.reveal(f.path),
                revealTooltip: l10n.storageReveal,
              ),
          ]),
        ),
      ],
    ]);
  }
}

/// 이름 · 크기 · 비율 막대 한 줄. [onTap]이 있으면 눌러서 내려가고, [onReveal]이 있으면 위치 열기 단추가 붙는다.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.bytes,
    this.subtitle,
    this.fraction,
    this.onTap,
    this.onReveal,
    this.revealTooltip,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final int bytes;
  final double? fraction;
  final VoidCallback? onTap;
  final VoidCallback? onReveal;
  final String? revealTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = fraction;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: AppSpacing.md),
                if (subtitle != null && f != null) Text(subtitle!, style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(formatBytes(bytes), style: theme.textTheme.titleSmall),
                if (f != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(width: 44, child: Text('${(f * 100).toStringAsFixed(f > 0 && f < 0.1 ? 1 : 0)}%', textAlign: TextAlign.end, style: theme.textTheme.bodySmall)),
                ],
              ]),
              if (subtitle != null && f == null)
                Text(subtitle!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (f != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: f.clamp(0, 1),
                    minHeight: 5,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ]),
          ),
          if (onReveal != null)
            IconButton(
              tooltip: revealTooltip,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: onReveal,
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          if (onTap != null) Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}
