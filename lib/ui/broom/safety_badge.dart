import 'package:flutter/material.dart';

import '../../cleaner/scan_target.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/broom_style.dart';
import 'glass.dart';

/// 안전 등급 알약. 라이트 테마에서는 흰 바탕 위 글자 대비를 위해 어두운 변형을 쓴다 (theming.md §2).
class SafetyBadge extends StatelessWidget {
  const SafetyBadge(this.safety, {super.key});

  final Safety safety;

  static Color colorOf(BuildContext context, Safety s) {
    final light = Theme.of(context).brightness == Brightness.light;
    return switch (s) {
      Safety.safe => light ? AppColors.successTextLight : BroomAccent.mint,
      Safety.rebuild => light ? AppColors.warningTextLight : BroomAccent.amber,
      Safety.review => light ? AppColors.dangerTextLight : BroomAccent.rose,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, icon) = switch (safety) {
      Safety.safe => (l10n.safetySafe, Icons.verified_user_rounded),
      Safety.rebuild => (l10n.safetyRebuild, Icons.autorenew_rounded),
      Safety.review => (l10n.safetyReview, Icons.visibility_rounded),
    };
    return Pill(label, color: colorOf(context, safety), icon: icon);
  }
}
