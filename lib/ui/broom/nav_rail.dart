import 'package:flutter/material.dart';

import '../../app_identity.dart';
import '../../theme/broom_style.dart';

class NavItem {
  const NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// 왼쪽 레일: 로고, 아이콘 단추, 활성 항목에는 빛나는 그라디언트 알약.
/// [footer]는 아래쪽의 동작 단추(정보 등)로, 선택 상태가 없다.
class NavRail extends StatelessWidget {
  const NavRail({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
    this.footer = const [],
    this.footerActions = const [],
  }) : assert(footer.length == footerActions.length);

  final int index;
  final ValueChanged<int> onChanged;
  final List<NavItem> items;
  final List<NavItem> footer;
  final List<VoidCallback> footerActions;

  @override
  Widget build(BuildContext context) {
    final b = context.broom;
    return Container(
      width: 84,
      decoration: BoxDecoration(color: b.rail, border: Border(right: BorderSide(color: b.border))),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          const _Logo(),
          const SizedBox(height: 22),
          // 항목이 많아 창 높이(최소 560)를 넘으면 넘치지 않고 스크롤한다.
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                for (var i = 0; i < items.length; i++)
                  _RailButton(item: items[i], active: i == index, onTap: () => onChanged(i)),
              ]),
            ),
          ),
          for (var i = 0; i < footer.length; i++) _RailButton(item: footer[i], active: false, onTap: footerActions[i], dim: true),
        ],
      ),
    );
  }
}

/// 레일 맨 위: 앱 아이콘 (작업 표시줄·Dock 의 아이콘과 같은 그림). 그림 자체에 모서리와 여백이 있어 틀을 두르지 않는다.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Image.asset(
        AppIdentity.iconAsset,
        width: 48,
        height: 48,
        filterQuality: FilterQuality.medium,
        semanticLabel: AppIdentity.displayName,
      );
}

class _RailButton extends StatefulWidget {
  const _RailButton({required this.item, required this.active, required this.onTap, this.dim = false});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;
  final bool dim;

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  static const _fade = Duration(milliseconds: 180);
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = context.broom;
    final active = widget.active;
    final fg = active
        ? Colors.white
        : (_hover ? scheme.onSurface : (widget.dim ? scheme.onSurfaceVariant.withValues(alpha: 0.7) : scheme.onSurfaceVariant));
    return Semantics(
      button: true,
      selected: active,
      label: widget.item.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // 활성 알약은 별도 레이어로 페이드한다. 한 BoxDecoration 을 그라디언트와 단색 사이에서
              // 애니메이션하면 양 끝에서 튀어 깜박임으로 보인다.
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(fit: StackFit.expand, children: [
                  AnimatedContainer(
                    duration: _fade,
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: _hover && !active ? b.glassHover : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: _fade,
                    curve: Curves.easeOut,
                    opacity: active ? 1 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: BroomAccent.accent,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: b.glow(BroomAccent.violet, blur: 20, alpha: 0.6),
                      ),
                    ),
                  ),
                  Icon(widget.item.icon, size: 19, color: fg),
                ]),
              ),
              const SizedBox(height: 4),
              // 글자는 알약 밖에 있으므로, 활성일 때도 흰색이 아니라 본문색이어야 라이트 테마에서 보인다.
              Text(widget.item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: active ? scheme.onSurface : fg)),
            ]),
          ),
        ),
      ),
    );
  }
}
