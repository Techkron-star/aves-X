import 'package:aves/model/security/failsafe.dart';
import 'package:aves/services/common/services.dart';
import 'package:material_ui/material_ui.dart';

class ReportingRouteTracker extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _log('Nav push to ${_name(route)}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _log('Nav pop to ${_name(previousRoute)}');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _log('Nav remove to ${_name(previousRoute)}');

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _log('Nav replace to ${_name(newRoute)}');

  void _log(String m) {
    reportService.log(m);
    failsafe.breadcrumb(m);
  }

  String _name(Route<Object?>? route) => route?.settings.name ?? 'unnamed ${route?.runtimeType}';
}
