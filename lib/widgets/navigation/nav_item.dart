import 'package:aves/model/filters/favourite.dart';
import 'package:aves/model/item_locks.dart';
import 'dart:convert';

import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/trash.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/about/about_page.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:aves/widgets/debug/app_debug_page.dart';
import 'package:aves/widgets/explorer/explorer_page.dart';
import 'package:aves/widgets/filter_grids/albums_page.dart';
import 'package:aves/widgets/filter_grids/countries_page.dart';
import 'package:aves/widgets/filter_grids/places_page.dart';
import 'package:aves/widgets/filter_grids/tags_page.dart';
import 'package:aves/widgets/home/home_page.dart';
import 'package:aves/widgets/navigation/drawer/tile.dart';
import 'package:aves/widgets/navigation/nav_display.dart';
import 'package:aves/widgets/search/collection_search_page_route.dart';
import 'package:aves/widgets/settings/settings_page.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AvesNavItem extends Equatable {
  final String route;
  final Set<CollectionFilter>? filters;
  final String? path;

  @override
  List<Object?> get props => [route, filters, path];

  const new({
    required this.route,
    this.filters,
    this.path,
  });

  Widget getIcon(BuildContext context) {
    if (route == CollectionPage.routeName) {
      return DrawerFilterIcon(filter: filters?.firstOrNull);
    }

    final textScaler = MediaQuery.textScalerOf(context);
    final iconSize = textScaler.scale(24);
    return Icon(NavigationDisplay.getPageIcon(route), size: iconSize);
  }

  String getText(BuildContext context) {
    if (route == CollectionPage.routeName) {
      return NavigationDisplay.getFilterTitle(context, filters?.firstOrNull);
    }
    return NavigationDisplay.getPageTitle(context, route);
  }

  bool get _opensBin => route == CollectionPage.routeName && (filters?.contains(TrashFilter.instance) ?? false);

  Future<void> goTo(BuildContext context, {bool? topLevel}) async {
    // the recycle bin may have its own lock
    if (_opensBin) {
      if (!await SecretLock.bin.authenticate(context)) return;
      if (!context.mounted) return;
    }

    if (this.route == CollectionPage.routeName && (filters?.any((v) => v is FavouriteFilter) ?? false)) {
      if (!await itemLocks.unlockFavourites(context)) return;
      if (!context.mounted) return;
    }

    topLevel ??= _defaultTopLevel;
    final route = routeBuilder(context, topLevel: topLevel);
    if (topLevel) {
      await Navigator.maybeOf(context)?.pushAndRemoveUntil(
        route,
        (route) => false,
      );
    } else {
      await Navigator.maybeOf(context)?.push(route);
    }
  }

  bool get _defaultTopLevel {
    switch (route) {
      case AboutPage.routeName:
      case AppDebugPage.routeName:
      case SearchPage.routeName:
      case SettingsPage.routeName:
        return false;
      default:
        return true;
    }
  }

  Route routeBuilder(BuildContext context, {required bool topLevel}) {
    switch (route) {
      case HomePage.routeName:
        return settings.homeNavItem.routeBuilder(context, topLevel: topLevel);
      case SearchPage.routeName:
        final currentCollection = context.read<CollectionLens?>();
        return CollectionSearchPageRoute(
          context: context,
          parentCollection: topLevel ? currentCollection?.copyWith() : currentCollection,
        );
      default:
        final slide = TabSlide.consume();
        if (topLevel && slide != null && settings.animate) {
          return TabSlideRoute(
            settings: RouteSettings(name: route),
            builder: _materialPageBuilder(route),
            direction: slide,
          );
        }
        return MaterialPageRoute(
          settings: RouteSettings(name: route),
          builder: _materialPageBuilder(route),
        );
    }
  }

  WidgetBuilder _materialPageBuilder(String route) {
    switch (route) {
      case CollectionPage.routeName:
        return (context) => CollectionPage(
          source: context.read<CollectionSource>(),
          filters: filters,
        );
      case AlbumListPage.routeName:
        return (_) => const AlbumListPage(initialGroup: null);
      case CountryListPage.routeName:
        return (_) => const CountryListPage();
      case PlaceListPage.routeName:
        return (_) => const PlaceListPage();
      case TagListPage.routeName:
        return (_) => const TagListPage(initialGroup: null);
      case AboutPage.routeName:
        return (_) => const AboutPage();
      case AppDebugPage.routeName:
        return (_) => const AppDebugPage();
      case ExplorerPage.routeName:
        return (_) => ExplorerPage(path: path);
      case SettingsPage.routeName:
        return (_) => const SettingsPage();
      default:
        throw Exception('unknown route=$route');
    }
  }

  // serialization

  static AvesNavItem _fromMap(Map<String, Object?> json) {
    return AvesNavItem(
      route: json['route'] as String,
      filters: (json['filters'] as List?)?.map(CollectionFilter.fromJson).nonNulls.toSet(),
      path: json['path'] as String?,
    );
  }

  Map<String, Object?> _toMap() => {
    'route': route,
    if (filters != null) 'filters': filters!.map((v) => v.toJsonMap()).toList(),
    'path': ?path,
  };

  String toJson() => jsonEncode(_toMap());

  static AvesNavItem? fromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final jsonMap = jsonDecode(jsonString);
      if (jsonMap is Map<String, Object?>) {
        return _fromMap(jsonMap);
      }
      debugPrint('failed to parse navigation item from json=$jsonString');
    } catch (error) {
      // no need for stack
      debugPrint('failed to parse navigation item from json=$jsonString error=$error');
    }
    return null;
  }
}

// Instagram-like tab change: the new tab slides in from the side of the movement, while fading in
class TabSlide {
  static int? _direction;
  static DateTime? _at;

  // 1: the new tab comes from the right, -1: from the left
  static void request(int direction) {
    _direction = direction;
    _at = DateTime.now();
  }

  static int? consume() {
    final at = _at, direction = _direction;
    _direction = null;
    _at = null;
    if (at == null || DateTime.now().difference(at) > const Duration(seconds: 3)) return null;
    return direction;
  }
}

class TabSlideRoute<T> extends PageRouteBuilder<T> {
  TabSlideRoute({
    super.settings,
    required WidgetBuilder builder,
    required int direction,
  }) : super(
         pageBuilder: (context, _, _) => builder(context),
         transitionDuration: const Duration(milliseconds: 380),
         reverseTransitionDuration: const Duration(milliseconds: 380),
         transitionsBuilder: (context, animation, secondary, child) {
           final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
           return SlideTransition(
             position: Tween<Offset>(begin: Offset(direction.toDouble(), 0), end: Offset.zero).animate(curved),
             child: FadeTransition(opacity: Tween<double>(begin: .55, end: 1).animate(curved), child: child),
           );
         },
       );
}
