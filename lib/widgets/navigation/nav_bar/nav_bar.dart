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
                  child: BottomNavigationBar(
                    items: items.map((item) {
                      final label = item.getText(context);
                      return BottomNavigationBarItem(
                        icon: item.getIcon(context),
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
