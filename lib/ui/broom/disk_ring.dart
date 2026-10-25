import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/broom_style.dart';

/// 빛나는 그라디언트 도넛. [extraRatio]는 지금 선택한 항목을 정리하면 사용 영역에서
/// 얼마가 비는지를 성공 그라디언트로 미리 보여 준다.
class DiskRing extends StatelessWidget {
  const DiskRing({super.key, required this.usedRatio, this.extraRatio = 0, required this.child, this.size = 180});

  final double usedRatio;
  final double extraRatio;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final track = context.broom.border;
    final glow = context.broom.glowScale;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: usedRatio.clamp(0, 1)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, used, _) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: extraRatio.clamp(0, used)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, extra, _) => CustomPaint(
          painter: _RingPainter(used: used, extra: extra, track: track, glow: glow),
          child: SizedBox.square(dimension: size, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.used, required this.extra, required this.track, required this.glow});

  final double used, extra, glow;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 6);
    const start = -pi / 2;

    canvas.drawArc(rect, 0, 2 * pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track);

    final sweep = 2 * pi * used;
    final shader = SweepGradient(
      endAngle: 2 * pi,
      colors: const [BroomAccent.cyan, BroomAccent.violet, BroomAccent.pink, BroomAccent.cyan],
      stops: const [0, 0.45, 0.85, 1],
      transform: const GradientRotation(start),
    ).createShader(rect);

    Paint arc() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader;
    canvas.drawArc(rect, start, sweep, false, arc()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..color = Color.fromRGBO(255, 255, 255, 0.5 * glow));
    canvas.drawArc(rect, start, sweep, false, arc());

    if (extra > 0.002) {
      final eSweep = 2 * pi * extra;
      final freed = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = BroomAccent.success.createShader(rect);
      canvas.drawArc(rect, start + sweep - eSweep, eSweep, false, freed..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      canvas.drawArc(rect, start + sweep - eSweep, eSweep, false, freed..maskFilter = null);
    }

    canvas.drawCircle(rect.center, rect.width / 2 - stroke, Paint()
      ..shader = RadialGradient(colors: [BroomAccent.violet.withValues(alpha: 0.18 * glow), Colors.transparent]).createShader(rect));
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.used != used || o.extra != extra || o.track != track || o.glow != glow;
}
