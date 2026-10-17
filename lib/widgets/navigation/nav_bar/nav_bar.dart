import 'dart:ui';
import 'package:aves/widgets/common/fx/liquid.dart';
import 'package:aves/model/settings/enums/nav_bar_style.dart';
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

    final navBarStyle = context.select<Settings, NavBarStyle>((v) => v.navBarStyle);
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
                    items: items.map((item) {
                      final label = item.getText(context);
                      return BottomNavigationBarItem(
                        icon: LiquidIcon(child: item.getIcon(context)),
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
    if (animate) {
      child = Hero(
        tag: 'nav-bar',
        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
          return MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: toHeroContext.widget,
          );
        },
        child: child,
      );
    }

    return child;
  }

  void _onCollectionFilterChanged() => setState(() {});

  // iOS-like lens over the selected item (rounded and rectangular bars)
  Widget _withLens(BuildContext context, NavBarStyle style, int count, int index, bool isRtl, Widget bar) {
    if (style == NavBarStyle.classic) return bar;
    final blur = settings.enableBlurEffect;
    final bat = settings.batGlass;
    final radius = BorderRadius.circular(style == NavBarStyle.rectangular ? 8 : 22);
    final position = count <= 1 ? 0.0 : -1 + 2 * index / (count - 1);
    Widget lens = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bat ? const [Color(0x55FF3B5C), Color(0x14E0183E)] : const [Color(0x40FFFFFF), Color(0x0DFFFFFF)],
        ),
        border: Border.all(color: bat ? const Color(0x99FF6A80) : const Color(0x73FFFFFF), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
      ),
    );
    if (blur) {
      lens = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          // very light blur only, so that the icon below stays crisp
          filter: ImageFilter.blur(sigmaX: .6, sigmaY: .6),
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
            child: AnimatedAlign(
              alignment: Alignment(isRtl ? -position : position, 0),
              duration: settings.animate ? const Duration(milliseconds: 650) : Duration.zero,
              curve: const _SpringCurve(),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: .82,
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: lens),
              ),
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
class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) => 1 - exp(-6.5 * t) * cos(2 * pi * 1.4 * t);
}
