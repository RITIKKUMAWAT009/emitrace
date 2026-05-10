import 'package:emitrace/src/core/emitrace_controller.dart';
import 'package:flutter/widgets.dart';

/// Route observer that records route transitions in Emitrace breadcrumbs.
class EmitraceRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  final EmitraceController _controller = EmitraceController();

  bool _shouldTrack(Route<dynamic>? route) {
    if (route == null) return false;
    // Ignore overlays like bottom sheets/dialogs and only track page-level navigation.
    return route is PageRoute<dynamic>;
  }

  String _routeName(Route<dynamic>? route) {
    if (route == null) return 'unknown';
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    return route.runtimeType.toString();
  }

  void _record({
    required String transition,
    required Route<dynamic>? previousRoute,
    required Route<dynamic>? currentRoute,
  }) {
    final from = _routeName(previousRoute);
    final to = _routeName(currentRoute);
    _controller.navigation(from, to, transition: transition);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_shouldTrack(route)) {
      super.didPush(route, previousRoute);
      return;
    }
    _record(
      transition: 'push',
      previousRoute: previousRoute,
      currentRoute: route,
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_shouldTrack(route)) {
      super.didPop(route, previousRoute);
      return;
    }
    _record(
      transition: 'pop',
      previousRoute: route,
      currentRoute: previousRoute,
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_shouldTrack(route)) {
      super.didRemove(route, previousRoute);
      return;
    }
    _record(
      transition: 'remove',
      previousRoute: route,
      currentRoute: previousRoute,
    );
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (!_shouldTrack(newRoute) && !_shouldTrack(oldRoute)) {
      super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
      return;
    }
    _record(
      transition: 'replace',
      previousRoute: oldRoute,
      currentRoute: newRoute,
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
