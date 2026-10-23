import 'dart:ui';
import 'package:aves/widgets/common/fx/liquid.dart';
import 'package:aves/widgets/common/fx/black_hole.dart';
import 'package:aves/model/settings/enums/nav_bar_style.dart';
import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/model/security/privacy_options.dart';
import 'dart:async';
import 'dart:math';

import 'package:aves/app_mode.dart';
import 'package:aves/model/secret_reveal.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/common/bars/floating_bar.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:aves/widgets/common/basic/draggable_scrollbar/notifications.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/extensions/media_query.dart';
import 'package:aves/widgets/filter_grids/albums_page.dart';
import 'package:aves/widgets/navigation/nav_bar/floating.dart';
import 'package:aves/widgets/navigation/nav_bar/bubble_nav.dart';
import 'package:aves/widgets/navigation/nav_item.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const AppBottomNavBar({
  super.key,
  required final Stream<DraggableScrollbarEvent> events,
  // collection loaded in the `CollectionPage`, if any
  final CollectionLens? currentCollection,
}) extends StatefulWidget {
  static EdgeInsets getMargin(double safeBottomPadding) {
    return settings.navBarStyle.margin(safeBottomPadding);
  }

  static double getHeightWithMargin(double safeBottomPadding) {
    // tablet mode: bubbles instead of the bar
    if (settings.tabletMode) return BubbleNav.height + safeBottomPadding;
    return kBottomNavigationBarHeight + getMargin(safeBottomPadding).vertical;
  }

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  String? _lastRoute;
  Timer? _holdTimer;
  Offset? _holdOrigin;
  bool _holdFired = false;

  @override
  void initState() {
    super.initState();
    // Prime the persisted root-mode state so the bin icon is correct after relaunch.
    unawaited(FailsafeConfig.rootMode.then<void>((_) {}));
    _registerWidget(widget);
  }

  @override
  void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _unregisterWidget(widget);
    super.dispose();
  }

  void _registerWidget(AppBottomNavBar widget) {
    widget.currentCollection?.filterChangeNotifier.addListener(_onCollectionFilterChanged);
  }

  void _unregisterWidget(AppBottomNavBar widget) {
    widget.currentCollection?.filterChangeNotifier.removeListener(_onCollectionFilterChanged);
  }

  @override
  Widget build(BuildContext context) {
    final items = context.select<Settings, List<AvesNavItem>>((v) => v.bottomNavigationActions);
    if (items.length < 2) return const SizedBox();

    // tablet mode: bubbles instead of the bar (no Bat-Lens either)
    if (context.select<Settings, bool>((v) => v.tabletMode)) {
      final bubbles = items.take(BubbleNav.maxBubbles).toList();
      return BubbleNav(
        items: bubbles,
        currentIndex: _getCurrentIndex(context, bubbles),
        onSelect: (index) => _goTo(context, bubbles, index),
        onSecretHold: () => unawaited(_toggleReveal(context)),
      );
    }

    final navBarStyle = context.select<Settings, NavBarStyle>((v) => v.navBarStyle);
    // rebuild when the lens is toggled
    context.select<Settings, bool>((v) => v.navLens);
    final safeBottomPadding = context.select<MediaQueryData, double>((mq) => mq.safeBottomPadding);
    Widget child = FloatingNavBar(
      scrollController: PrimaryScrollController.of(context),
      events: widget.events,
      childHeight: AppBottomNavBar.getHeightWithMargin(safeBottomPadding),
      child: SafeArea(
        bottom: false,
        child: MediaQuery.removePadding(
          context: context,
          // `bottom` is computed beforehand and used in multiple places,
          // so we remove it from context to prevent additional padding
          removeBottom: true,
          child: AvesFloatingBar(
            margin: AppBottomNavBar.getMargin(safeBottomPadding),
            borderRadius: navBarStyle.borderRadius,
            builder: (context, backgroundColor, child) => LayoutBuilder(
              builder: (context, constraints) {
                final isRtl = Directionality.of(context) == TextDirection.rtl;
                // the pointer is only observed, so taps are handled as usual by the bar
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) => _onPointerDown(context, event, items, context.size?.width ?? constraints.maxWidth, isRtl),
                  onPointerMove: _onPointerMove,
                  onPointerUp: (_) => _cancelHold(),
                  onPointerCancel: (_) => _cancelHold(),
                  child: _withLens(
                    context,
                    navBarStyle,
                    items.length,
                    _getCurrentIndex(context, items),
                    isRtl,
                    BottomNavigationBar(
                    items: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final label = item.getText(context);
                      final isSelected = !settings.navLens && index == _getCurrentIndex(context, items);
                      return BottomNavigationBarItem(
                        // One stable icon subtree serves both selected and unselected states.
                        // Rebuilding separate icon and activeIcon trees restarted LiquidIcon
                        // bursts whenever selection changed.
                        icon: _navIcon(context, item, highlighted: isSelected),
                        label: label,
                        tooltip: label,
                      );
                    }).toList(),
                    onTap: (index) => _goTo(context, items, index),
                    currentIndex: _getCurrentIndex(context, items),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: backgroundColor,
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final animate = context.select<Settings, bool>((v) => v.animate);
    // Keep Hero in the tree even when transitions are disabled. Swapping
    // Hero <-> FloatingNavBar used to dispose the entire nav subtree and restart
    // every stateful icon effect whenever the motion preference changed.
    return HeroMode(
      enabled: animate,
      child: Hero(
        tag: 'nav-bar',
        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
          return MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: toHeroContext.widget,
          );
        },
        child: child,
      ),
    );
  }

  void _onCollectionFilterChanged() => setState(() {});

  // The bin has its own motion; Black Hole mode replaces the ordinary icon
  // with an accretion disc while preserving the familiar trash silhouette.
  // Keep one icon subtree across selection changes so LiquidIcon bursts do not restart.
  Widget _navIcon(BuildContext context, AvesNavItem item, {required bool highlighted}) {
    final icon = item.getIcon(context);
    final animate = settings.animate;
    final Widget visual = item.opensBin
        ? ValueListenableBuilder<bool>(
            valueListenable: FailsafeConfig.rootModeActive,
            builder: (context, blackHole, _) => blackHole
                ? BlackHoleIcon(size: 30, animate: animate, child: icon)
                : TrashIconMotion(animate: animate, child: LiquidIcon(child: icon)),
          )
        : LiquidIcon(child: icon);
    final color = settings.materialStyle?.accent ?? Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: highlighted
            ? [BoxShadow(color: color.withValues(alpha: .65), blurRadius: 16, spreadRadius: 2)]
            : const [],
      ),
      child: visual,
    );
  }

  // Nav Lens: layered glass and a restrained reflection tied to the existing spring.
  Widget _withLens(BuildContext context, NavBarStyle style, int count, int index, bool isRtl, Widget bar) {
    if (style == NavBarStyle.classic || !settings.navLens) return bar;
    final blur = settings.enableBlurEffect && settings.glassEverywhere;
    final material = settings.materialStyle;
    final radius = BorderRadius.circular(style == NavBarStyle.rectangular ? 8 : 22);
    final lensColors = material?.lens ?? const [Color(0x40FFFFFF), Color(0x0DFFFFFF)];
    final lensBorder = material?.lensBorder ?? const Color(0x73FFFFFF);
    final lensAccent = material?.accent ?? Theme.of(context).colorScheme.primary;
    Widget lens = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: lensColors),
        border: Border.all(color: lensBorder, width: 1.15),
        boxShadow: [
          BoxShadow(color: const Color(0x33000000), blurRadius: 9, spreadRadius: -2, offset: const Offset(0, 3)),
          BoxShadow(color: lensAccent.withValues(alpha: .20), blurRadius: 15, spreadRadius: -4),
          BoxShadow(color: Colors.white.withValues(alpha: .08), blurRadius: 2, offset: const Offset(0, -1)),
        ],
      ),
    );
    if (blur) {
      lens = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.05, sigmaY: 1.05),
          child: lens,
        ),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        bar,
        Positioned.fill(
          child: IgnorePointer(
            child: _LensSlider(
              count: count,
              index: index,
              isRtl: isRtl,
              lens: lens,
              radius: radius,
              accent: lensAccent,
              edge: lensBorder,
              animateReflection: settings.animate && !settings.performanceMode,
            ),
          ),
        ),
      ],
    );
  }

  int _getCurrentIndex(BuildContext context, List<AvesNavItem> items) {
    // current route may be null during navigation
    final currentRoute = context.currentRouteName ?? _lastRoute;
    _lastRoute = currentRoute;

    final currentItem = items.firstWhereOrNull((item) {
      final itemRoute = item.route;
      if (currentRoute != itemRoute) return false;

      switch (itemRoute) {
        case CollectionPage.routeName:
          final currentFilters = widget.currentCollection?.filters ?? {};
          return const SetEquality().equals(currentFilters, item.filters ?? {});
        default:
          return true;
      }
    });
    final currentIndex = currentItem != null ? items.indexOf(currentItem) : 0;
    return currentIndex;
  }

  void _goTo(BuildContext context, List<AvesNavItem> items, int index) {
    // the release of a long hold on the Albums item should not navigate,
    // as it would cover the lock dialog that was just shown
    if (_holdFired) {
      _holdFired = false;
      return;
    }
    final current = _getCurrentIndex(context, items);
    LensMemory.remember(current);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (index != current) TabSlide.request((index > current) != rtl ? 1 : -1);
    items[index].goTo(context, topLevel: null);
  }

  // holding the Albums item toggles the reveal of hidden items
  void _onPointerDown(BuildContext context, PointerDownEvent event, List<AvesNavItem> items, double barWidth, bool isRtl) {
    _holdFired = false;
    _cancelHold();
    if (!privacyOptions.revealGesture) return;
    if (items.isEmpty || barWidth <= 0) return;

    final rawIndex = (event.localPosition.dx / barWidth * items.length).floor();
    var index = max(0, min(rawIndex, items.length - 1));
    if (isRtl) index = items.length - 1 - index;
    if (items[index].route != AlbumListPage.routeName) return;

    _holdOrigin = event.position;
    _holdTimer = Timer(SecretReveal.holdDuration, () {
      _holdTimer = null;
      _holdFired = true;
      if (context.mounted) {
        unawaited(_toggleReveal(context));
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    final origin = _holdOrigin;
    if (origin != null && (event.position - origin).distance > 32) {
      _cancelHold();
    }
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdOrigin = null;
  }

  Future<void> _toggleReveal(BuildContext context) async {
    // hiding does not need any confirmation
    if (secretReveal.active) {
      secretReveal.active = false;
      return;
    }

    // without a configured reveal lock, nothing happens
    final lock = SecretLock.reveal;
    if (await lock.getLockType() == null) return;
    if (!context.mounted) return;

    if (await lock.authenticate(context)) {
      secretReveal.active = true;
    }
  }
}

class const NavBarPaddingSliver({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canNavigate = context.select<ValueNotifier<AppMode>, bool>((v) => v.value.canNavigate);
    final enableBottomNavigationBar = context.select<Settings, bool>((v) => v.enableBottomNavigationBar);
    final safeBottomPadding = context.select<MediaQueryData, double>((mq) => mq.safeBottomPadding);
    final showBottomNavigationBar = canNavigate && enableBottomNavigationBar;
    final height = showBottomNavigationBar ? AppBottomNavBar.getHeightWithMargin(safeBottomPadding) : safeBottomPadding;
    return SliverToBoxAdapter(
      child: SizedBox(height: height),
    );
  }
}

// damped spring: overshoots the target and settles
// swipe horizontally over the page to go to the previous / next item of the navigation bar.
// Raw pointer events are observed (no gesture arena), so scrolling and other gestures are never disturbed
class SwipeTabs extends StatefulWidget {
  const SwipeTabs({
    super.key,
    required this.enabled,
    required this.child,
    this.currentCollection,
  });

  final bool enabled;
  final CollectionLens? currentCollection;
  final Widget child;

  @override
  State<SwipeTabs> createState() => _SwipeTabsState();
}

class _SwipeTabsState extends State<SwipeTabs> {
  static const _edge = 28.0;
  static const _minDistance = 70.0;
  static const _maxDuration = Duration(milliseconds: 900);

  final Set<int> _pointers = {};
  Offset? _start;
  DateTime? _startTime;
  bool _cancelled = false;

  @override
  Widget build(BuildContext context) {
    final swipeTabs = context.select<Settings, bool>((v) => v.swipeTabs);
    if (!widget.enabled || !swipeTabs) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _pointers.add(event.pointer);
        if (_pointers.length == 1) {
          final width = MediaQuery.sizeOf(context).width;
          // edges are left to the drawer and the system back gesture
          _cancelled = event.position.dx < _edge || event.position.dx > width - _edge;
          _start = event.position;
          _startTime = DateTime.now();
        } else {
          _cancelled = true;
        }
      },
      onPointerUp: (event) {
        final wasSingle = _pointers.length == 1;
        _pointers.remove(event.pointer);
        final start = _start;
        final startTime = _startTime;
        if (!wasSingle || _cancelled || start == null || startTime == null) return;
        final delta = event.position - start;
        if (DateTime.now().difference(startTime) > _maxDuration) return;
        if (delta.dx.abs() < _minDistance || delta.dx.abs() < delta.dy.abs() * 2) return;
        _go(context, delta.dx);
      },
      onPointerCancel: (event) {
        _pointers.remove(event.pointer);
        _cancelled = true;
      },
      child: widget.child,
    );
  }

  void _go(BuildContext context, double dx) {
    final items = settings.bottomNavigationActions;
    if (items.length < 2) return;

    final currentRoute = context.currentRouteName;
    final currentIndex = items.indexWhere((item) {
      if (item.route != currentRoute) return false;
      if (item.route == CollectionPage.routeName) {
        return const SetEquality().equals(widget.currentCollection?.filters ?? {}, item.filters ?? {});
      }
      return true;
    });
    if (currentIndex < 0) return;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // finger moving to the left goes to the next item
    final forward = isRtl ? dx > 0 : dx < 0;
    final target = currentIndex + (forward ? 1 : -1);
    if (target < 0 || target >= items.length) return;
    LensMemory.remember(currentIndex);
    TabSlide.request(forward ? 1 : -1);
    items[target].goTo(context, topLevel: null);
  }
}

// remembers where the lens was before changing page, so that the new page's lens can slide from there
class LensMemory {
  static int? _from;
  static DateTime? _at;

  static void remember(int index) {
    _from = index;
    _at = DateTime.now();
  }

  static int? recent() {
    final at = _at;
    if (at == null || DateTime.now().difference(at) > const Duration(milliseconds: 750)) return null;
    return _from;
  }

  // how far the slide is, in 0..1, according to the time elapsed since the page change:
  // every lens built for the same page change (hero flight, new page) continues the same slide instead of restarting it
  static double progress() {
    final at = _at;
    if (at == null) return 1;
    return (DateTime.now().difference(at).inMilliseconds / 750).clamp(0.0, 1.0);
  }
}

// lens sliding between items like a drop of water: the leading edge goes first with a spring,
// the trailing edge follows later, so the lens stretches while moving and then settles
class _LensSlider extends StatefulWidget {
  const _LensSlider({
    required this.count,
    required this.index,
    required this.isRtl,
    required this.lens,
    required this.radius,
    required this.accent,
    required this.edge,
    required this.animateReflection,
  });

  final int count;
  final int index;
  final bool isRtl;
  final Widget lens;
  final BorderRadius radius;
  final Color accent;
  final Color edge;
  final bool animateReflection;

  @override
  State<_LensSlider> createState() => _LensSliderState();
}

class _LensSliderState extends State<_LensSlider> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late int _from;
  late int _to;

  int _visual(int i) => widget.isRtl ? widget.count - 1 - i : i;

  @override
  void initState() {
    super.initState();
    _to = widget.index;
    _from = LensMemory.recent() ?? _to;
    if (_from != _to && widget.animateReflection) {
      _controller.forward(from: LensMemory.progress());
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _LensSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animateReflection) {
      _controller.value = 1;
      _from = widget.index;
      _to = widget.index;
      return;
    }
    if (widget.index != _to) {
      _from = _to;
      _to = widget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / widget.count;
        final from = _visual(_from).toDouble();
        final to = _visual(_to).toDouble();
        final d = to - from;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            const fast = Cubic(.2, .9, .3, 1.12);
            final slow = Interval(.1, 1, curve: Curves.easeOutCubic);
            final lead = fast.transform(t);
            final trail = slow.transform(t);
            final left = from + d * (d >= 0 ? trail : lead);
            final right = from + 1 + d * (d >= 0 ? lead : trail);
            final width = max(.6, right - left);
            final stretch = (lead - trail).abs().clamp(0.0, .22).toDouble();
            final inset = constraints.maxHeight * (.09 + stretch * .14);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: left * itemWidth,
                  width: width * itemWidth,
                  top: inset,
                  bottom: inset,
                  child: ClipRect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          widget.lens,
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _LensReflectionPainter(
                                progress: t,
                                radius: widget.radius,
                                accent: widget.accent,
                                edge: widget.edge,
                                animate: widget.animateReflection,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Surface-only reflection: animated with the slider, never as a perpetual background effect.
class _LensReflectionPainter extends CustomPainter {
  const _LensReflectionPainter({
    required this.progress,
    required this.radius,
    required this.accent,
    required this.edge,
    required this.animate,
  });

  final double progress;
  final BorderRadius radius;
  final Color accent;
  final Color edge;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final corner = radius.topLeft.x;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(corner)));

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.1), Radius.circular(max(0, corner - 1.1))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65
        ..color = edge.withValues(alpha: .40),
    );
    final topEdge = Path()
      ..moveTo(corner, 1.5)
      ..quadraticBezierTo(size.width * .5, -1, size.width - corner, 1.5);
    canvas.drawPath(
      topEdge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: .46), edge.withValues(alpha: .20), Colors.transparent],
        ).createShader(rect),
    );

    if (animate && progress < .985) {
      final t = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0).toDouble());
      final sweepWidth = max(8.0, size.width * .24);
      final centerX = size.width * (1.72 * t - .34);
      final sweep = Path()
        ..moveTo(centerX - sweepWidth, 0)
        ..lineTo(centerX - sweepWidth * .34, 0)
        ..lineTo(centerX + sweepWidth, size.height)
        ..lineTo(centerX + sweepWidth * .34, size.height)
        ..close();
      canvas.drawPath(
        sweep,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: .055),
              Colors.white.withValues(alpha: .28),
              accent.withValues(alpha: .15),
              Colors.transparent,
            ],
            stops: const [0, .32, .49, .62, 1],
          ).createShader(Rect.fromLTWH(centerX - sweepWidth, 0, sweepWidth * 2, size.height)),
      );
      final glint = Path()
        ..moveTo(centerX - sweepWidth * .12, 0)
        ..lineTo(centerX + sweepWidth * .02, 0)
        ..lineTo(centerX + sweepWidth * .47, size.height)
        ..lineTo(centerX + sweepWidth * .31, size.height)
        ..close();
      canvas.drawPath(glint, Paint()..color = Colors.white.withValues(alpha: .16));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LensReflectionPainter old) =>
      old.progress != progress || old.radius != radius || old.accent != accent || old.edge != edge || old.animate != animate;
}
