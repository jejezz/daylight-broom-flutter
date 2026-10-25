// MacBroom에서 가져온 "Broom" 시각 언어 — 그라디언트, 글래스, 글로우.
//
// 규약 테마(app_theme.dart)를 대체하지 않고 그 위에 얹는다: 라이트/다크 ColorScheme,
// SeoulNamsan 글꼴, 간격·모서리 토큰은 그대로 두고, 앱 고유의 장식만 ThemeExtension 으로
// 둔다 (theming.md §2: 앱 고유 색은 라이트·다크 한 쌍으로). 글자는 Theme.textTheme 을 쓴다.

import 'package:flutter/material.dart';

abstract final class BroomAccent {
  static const violet = Color(0xFF7C6CFF);
  static const pink = Color(0xFFE961FF);
  static const cyan = Color(0xFF34E0FF);
  static const mint = Color(0xFF3DF2B2);
  static const amber = Color(0xFFFFB84D);
  static const rose = Color(0xFFFF5D7A);

  static const accent = LinearGradient(colors: [violet, pink], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const cool = LinearGradient(colors: [cyan, violet], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const success = LinearGradient(colors: [mint, cyan], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const danger = LinearGradient(colors: [rose, pink], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

@immutable
class BroomStyle extends ThemeExtension<BroomStyle> {
  const BroomStyle({
    required this.background,
    required this.rail,
    required this.glassTop,
    required this.glassBottom,
    required this.glassHover,
    required this.border,
    required this.borderStrong,
    required this.glowScale,
  });

  /// 화면 전체 배경.
  final LinearGradient background;
  final Color rail;

  /// 글래스 패널의 위·아래 색.
  final Color glassTop;
  final Color glassBottom;
  final Color glassHover;
  final Color border;
  final Color borderStrong;

  /// 글로우 세기 배율. 밝은 배경에서는 번져 보이므로 줄인다.
  final double glowScale;

  static const dark = BroomStyle(
    background: LinearGradient(
      colors: [Color(0xFF0A0D1C), Color(0xFF141233), Color(0xFF1B1441)],
      stops: [0, 0.55, 1],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    rail: Color(0x99070A16),
    glassTop: Color(0x1FFFFFFF),
    glassBottom: Color(0x0AFFFFFF),
    glassHover: Color(0x1FFFFFFF),
    border: Color(0x1FFFFFFF),
    borderStrong: Color(0x40FFFFFF),
    glowScale: 1,
  );

  static const light = BroomStyle(
    background: LinearGradient(
      colors: [Color(0xFFF4F6FA), Color(0xFFEEF0FF), Color(0xFFF6EEFF)],
      stops: [0, 0.55, 1],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    rail: Color(0xB3FFFFFF),
    glassTop: Color(0xE6FFFFFF),
    glassBottom: Color(0xB3FFFFFF),
    glassHover: Color(0x14000000),
    border: Color(0x14000000),
    borderStrong: Color(0x2E000000),
    glowScale: 0.35,
  );

  static BroomStyle of(BuildContext context) => Theme.of(context).extension<BroomStyle>() ?? dark;

  List<BoxShadow> glow(Color c, {double blur = 24, double alpha = 0.45}) =>
      [BoxShadow(color: c.withValues(alpha: alpha * glowScale), blurRadius: blur, spreadRadius: -2)];

  @override
  BroomStyle copyWith({
    LinearGradient? background,
    Color? rail,
    Color? glassTop,
    Color? glassBottom,
    Color? glassHover,
    Color? border,
    Color? borderStrong,
    double? glowScale,
  }) =>
      BroomStyle(
        background: background ?? this.background,
        rail: rail ?? this.rail,
        glassTop: glassTop ?? this.glassTop,
        glassBottom: glassBottom ?? this.glassBottom,
        glassHover: glassHover ?? this.glassHover,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        glowScale: glowScale ?? this.glowScale,
      );

  @override
  BroomStyle lerp(BroomStyle? other, double t) {
    if (other == null) return this;
    return BroomStyle(
      background: LinearGradient.lerp(background, other.background, t)!,
      rail: Color.lerp(rail, other.rail, t)!,
      glassTop: Color.lerp(glassTop, other.glassTop, t)!,
      glassBottom: Color.lerp(glassBottom, other.glassBottom, t)!,
      glassHover: Color.lerp(glassHover, other.glassHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      glowScale: glowScale + (other.glowScale - glowScale) * t,
    );
  }
}

extension BroomContext on BuildContext {
  BroomStyle get broom => BroomStyle.of(this);
}
