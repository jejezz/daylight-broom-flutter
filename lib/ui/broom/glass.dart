import 'package:flutter/material.dart';

import '../../theme/broom_style.dart';

/// 반투명 글래스 패널: 가는 테두리와 위쪽 하이라이트.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 16, this.glowColor});

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final b = context.broom;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: b.border),
        boxShadow: glowColor == null ? null : b.glow(glowColor!, blur: 40, alpha: 0.25),
        gradient: LinearGradient(colors: [b.glassTop, b.glassBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// 그라디언트로 칠한 글자.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style, this.gradient = BroomAccent.accent});

  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
        child: Text(text, style: style.copyWith(color: Colors.white)),
      );
}

/// 작은 둥근 라벨 (개수, 안전 등급 등).
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
        ]),
      );
}

/// 화면 전체를 칠하는 그라디언트 배경.
class BroomBackground extends StatelessWidget {
  const BroomBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      DecoratedBox(decoration: BoxDecoration(gradient: context.broom.background), child: child);
}
