import 'package:flutter/material.dart';

import '../../theme/broom_style.dart';

/// 주 동작 단추: 그라디언트, 글로우, 올라가는 호버, 눌리면 줄어듦.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = BroomAccent.accent,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LinearGradient gradient;
  final bool large;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hover = false, _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final b = context.broom;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.96 : (_hover && enabled ? 1.03 : 1),
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.4,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: widget.large ? 22 : 16, vertical: widget.large ? 13 : 9),
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: enabled
                    ? b.glow(widget.gradient.colors.first, blur: _hover ? 30 : 18, alpha: _hover ? 0.6 : 0.4)
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: widget.large ? 16 : 14, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(widget.label,
                    style: TextStyle(
                      fontSize: widget.large ? 14.5 : 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// 보조 단추: 글래스 윤곽.
class GhostButton extends StatefulWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.icon, this.small = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final b = context.broom;
    final fg = Theme.of(context).colorScheme.onSurface;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: widget.small ? 10 : 14, vertical: widget.small ? 5 : 8),
          decoration: BoxDecoration(
            color: _hover && enabled ? b.glassHover : b.glassBottom,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _hover && enabled ? b.borderStrong : b.border),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 13, color: fg), const SizedBox(width: 6)],
              Text(widget.label, style: TextStyle(fontSize: widget.small ? 11.5 : 12.5, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 그라디언트 체크박스. [value]가 null이면 일부 선택.
class BroomCheckbox extends StatelessWidget {
  const BroomCheckbox({super.key, required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = value != false;
    final b = context.broom;
    return Semantics(
      checked: value == true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value != true),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              gradient: on ? BroomAccent.accent : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: on ? Colors.transparent : b.borderStrong, width: 1.5),
              boxShadow: on ? b.glow(BroomAccent.violet, blur: 10, alpha: 0.5) : null,
            ),
            child: on
                ? Center(
                    child: value == null
                        ? Container(width: 8, height: 2, color: Colors.white)
                        : CustomPaint(size: const Size(10, 8), painter: _CheckPainter()),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(0.5, size.height * 0.55)
        ..lineTo(size.width * 0.38, size.height - 0.5)
        ..lineTo(size.width - 0.5, 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
