import 'dart:math';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/blurred.dart';
import 'package:aves/widgets/navigation/nav_item.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show SingleChildRenderObjectWidget;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Tablet mode: instead of the bottom bar (that makes the thumbs stretch to the middle of a big screen),
// a big bubble near the edge opens up to six small bubbles on an arc, within the thumb's reach.
// Tap the big bubble and then a small one, or slide from the big bubble to a small one and release.
class BubbleNav extends StatefulWidget {
  static const maxBubbles = 6;
  static const height = 72.0;

  final List<AvesNavItem> items;
  final int currentIndex;
  final void Function(int index) onSelect;

  const BubbleNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  State<BubbleNav> createState() => _BubbleNavState();
}

class _BubbleNavState extends State<BubbleNav> with SingleTickerProviderStateMixin {
  static const _mainSize = 64.0;
  static const _bubbleSize = 52.0;
  static const _margin = 16.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    reverseDuration: const Duration(milliseconds: 200),
  );
  bool _open = false;
  bool _openedByThisPress = false;
  bool _dragged = false;
  int? _hover;
  Offset? _downAt;

  List<AvesNavItem> get _items => widget.items.take(BubbleNav.maxBubbles).toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setOpen(bool open) {
    if (_open == open) return;
    setState(() {
      _open = open;
      if (!open) _hover = null;
    });
    if (settings.animate) {
      open ? _controller.forward() : _controller.reverse();
    } else {
      _controller.value = open ? 1 : 0;
    }
  }

  // arc from straight up to straight left of the big bubble, wide enough for the bubbles not to overlap
  double get _radius => max(96.0, 62.0 * (_items.length - 1) / (pi / 2));

  // (towards the screen's inner side, up) distances from the big bubble's center
  Offset _spot(int i) {
    final n = _items.length;
    final a = (n == 1 ? .5 : i / (n - 1)) * pi / 2;
    return Offset(sin(a) * _radius, cos(a) * _radius);
  }

  void _select(int i) {
    HapticFeedback.selectionClick();
    _setOpen(false);
    if (i != widget.currentIndex) widget.onSelect(i);
  }

  void _onDown(PointerDownEvent event) {
    _downAt = event.localPosition;
    _dragged = false;
    _openedByThisPress = !_open;
    if (!_open) {
      HapticFeedback.lightImpact();
      _setOpen(true);
    }
  }

  void _onMove(PointerMoveEvent event, bool rtl) {
    if (!_open) return;
    final down = _downAt;
    if (down == null) return;
    if (!_dragged && (event.localPosition - down).distance < 12) return;
    _dragged = true;
    final v = event.localPosition - const Offset(_mainSize / 2, _mainSize / 2);
    final sign = rtl ? 1.0 : -1.0;
    int? hover;
    var best = _bubbleSize * .7;
    for (var i = 0; i < _items.length; i++) {
      final spot = _spot(i);
      final d = (v - Offset(spot.dx * sign, -spot.dy)).distance;
      if (d < best) {
        best = d;
        hover = i;
      }
    }
    if (hover != _hover) {
      if (hover != null) HapticFeedback.selectionClick();
      setState(() => _hover = hover);
    }
  }

  void _onUp(PointerUpEvent event) {
    final hover = _hover;
    if (_dragged) {
      if (hover != null) {
        _select(hover);
      } else {
        _setOpen(false);
      }
    } else if (!_openedByThisPress) {
      // a tap on the big bubble while the menu is open closes it
      _setOpen(false);
    }
    _downAt = null;
    _dragged = false;
    setState(() => _hover = null);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final safeBottom = context.select<MediaQueryData, double>((mq) => mq.padding.bottom);
    final bottom = 8 + safeBottom;
    final current = widget.currentIndex.clamp(0, max(0, items.length - 1));
    final blur = settings.enableBlurEffect;

    return _OverflowHit(
      child: SizedBox(
        height: BubbleNav.height + safeBottom,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < items.length; i++) _buildBubble(context, i, items[i], bottom, blur, scheme),
            PositionedDirectional(
              end: _margin,
              bottom: bottom,
              width: _mainSize,
              height: _mainSize,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onDown,
                onPointerMove: (e) => _onMove(e, rtl),
                onPointerUp: _onUp,
                onPointerCancel: (_) {
                  _downAt = null;
                  _setOpen(false);
                },
                child: Tooltip(
                  message: context.l10n.bubbleNavTooltip,
                  child: _glassCircle(
                    size: _mainSize,
                    blur: blur,
                    color: scheme.primary.withValues(alpha: .35),
                    borderColor: scheme.primary.withValues(alpha: .9),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: RotationTransition(turns: Tween(begin: .75, end: 1.0).animate(animation), child: child)),
                      child: _open ? const Icon(Icons.close, key: ValueKey('close')) : KeyedSubtree(key: ValueKey(current), child: items.isEmpty ? const SizedBox() : items[current].getIcon(context)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, int i, AvesNavItem item, double bottom, bool blur, ColorScheme scheme) {
    final spot = _spot(i);
    final active = i == widget.currentIndex;
    final hovered = i == _hover;
    final n = _items.length;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // each bubble starts a little after the previous one, with a soft overshoot
        final start = .08 * i / max(1, n - 1) * 3;
        final t = Curves.easeOutBack.transform(((_controller.value - start) / (1 - start)).clamp(0.0, 1.0));
        if (_controller.value == 0) return const SizedBox();
        final fade = (_controller.value * 1.6).clamp(0.0, 1.0);
        final offset = (_mainSize - _bubbleSize) / 2;
        return PositionedDirectional(
          end: _margin + offset + spot.dx * t,
          bottom: bottom + offset + spot.dy * t,
          width: _bubbleSize,
          height: _bubbleSize,
          child: Opacity(
            opacity: fade,
            child: Transform.scale(
              scale: (.2 + .8 * t.clamp(0.0, 1.2)) * (hovered ? 1.2 : 1),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _open ? () => _select(i) : null,
                    child: _glassCircle(
                      size: _bubbleSize,
                      blur: blur,
                      color: active ? scheme.primary.withValues(alpha: .4) : Colors.black.withValues(alpha: .22),
                      borderColor: active || hovered ? scheme.primary : Colors.white.withValues(alpha: .35),
                      child: item.getIcon(context),
                    ),
                  ),
                  if (hovered)
                    Positioned(
                      bottom: _bubbleSize + 6,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .75), borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: Text(item.getText(context), maxLines: 1, softWrap: false, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _glassCircle({required double size, required bool blur, required Color color, required Color borderColor, required Widget child}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: BlurredOval(
        enabled: blur,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: borderColor, width: 1.4)),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// lets the bubbles be touched outside of the (small) box of the navigation slot they overflow
class _OverflowHit extends SingleChildRenderObjectWidget {
  const _OverflowHit({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOverflowHit();
}

class _RenderOverflowHit extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => hitTestChildren(result, position: position);
}
