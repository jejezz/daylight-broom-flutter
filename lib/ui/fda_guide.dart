import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../app_identity.dart';
import '../cleaner/disk_info.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/broom_style.dart';
import 'broom/buttons.dart';
import 'broom/glass.dart';

/// 전체 디스크 접근 권한을 주는 순서를 단계별로 안내한다. 열려 있는 동안 2초마다 권한을 확인해
/// macOS 가 허용으로 바꾸면 마지막 단계로 넘어간다.
Future<void> showFdaGuide(BuildContext context, {required DiskInfo info, required Future<void> Function() onGranted}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: _FdaGuide(info: info, onGranted: onGranted),
    ),
  );
}

class _FdaGuide extends StatefulWidget {
  const _FdaGuide({required this.info, required this.onGranted});

  final DiskInfo info;
  final Future<void> Function() onGranted;

  @override
  State<_FdaGuide> createState() => _FdaGuideState();
}

class _FdaGuideState extends State<_FdaGuide> {
  static const _stepCount = 5;

  int _step = 0;
  bool _granted = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _check());
    _check();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final ok = await widget.info.hasFullDiskAccess() ?? false;
    if (!mounted || ok == _granted) return;
    setState(() {
      _granted = ok;
      if (ok) _step = _stepCount - 1;
    });
    if (ok) {
      _poll?.cancel();
      await widget.onGranted();
    }
  }

  /// 실행 중인 .app: `<bundle>/Contents/MacOS/<exe>`.
  String get _appPath => p.dirname(p.dirname(p.dirname(Platform.resolvedExecutable)));

  (String, String) _text(AppLocalizations l10n) {
    const app = AppIdentity.displayName;
    return switch (_step) {
      0 => (l10n.fdaStep1Title, l10n.fdaStep1Body),
      1 => (l10n.fdaStep2Title, l10n.fdaStep2Body),
      2 => (l10n.fdaStep3Title(app), l10n.fdaStep3Body(app)),
      3 => (l10n.fdaStep4Title, l10n.fdaStep4Body(app)),
      _ => (l10n.fdaStep5Title, l10n.fdaStep5Body(app)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (title, body) = _text(l10n);
    final last = _step == _stepCount - 1;
    final b = context.broom;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(color: scheme.outline),
            boxShadow: b.glow(_granted ? BroomAccent.mint : BroomAccent.violet, blur: 40, alpha: 0.25),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              for (var i = 0; i < _stepCount; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _step ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: i == _step ? (_granted ? BroomAccent.success : BroomAccent.accent) : null,
                    color: i == _step ? null : scheme.onSurfaceVariant.withValues(alpha: i < _step ? 0.7 : 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const Spacer(),
              _granted
                  ? Pill(l10n.fdaGranted, color: BroomAccent.mint, icon: Icons.verified_rounded)
                  : Pill(l10n.fdaWaiting, color: BroomAccent.amber, icon: Icons.hourglass_top_rounded),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Text('${_step + 1}. $title', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xl),
            Row(children: [
              if (!last)
                GradientButton(
                    label: l10n.fdaOpenSettings, icon: Icons.settings_rounded, onPressed: widget.info.openFullDiskAccessSettings),
              if (_step == 2) ...[
                const SizedBox(width: AppSpacing.sm),
                GhostButton(
                  label: l10n.fdaShowInFinder(AppIdentity.displayName),
                  icon: Icons.folder_open_rounded,
                  onPressed: () => widget.info.revealInFinder(_appPath),
                ),
              ],
              if (last)
                GradientButton(label: l10n.fdaDone, gradient: BroomAccent.success, onPressed: () => Navigator.pop(context)),
              const Spacer(),
              GhostButton(label: l10n.fdaBack, small: true, onPressed: _step == 0 ? null : () => setState(() => _step--)),
              const SizedBox(width: AppSpacing.sm),
              GhostButton(
                label: last ? l10n.fdaClose : l10n.fdaNext,
                small: true,
                onPressed: last ? () => Navigator.pop(context) : () => setState(() => _step++),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
