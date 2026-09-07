import 'package:flutter/widgets.dart';

import '../core/qa_inspector_controller.dart';
import '../events/qa_route_event.dart';

/// Resolves a lightweight name for a Flutter route.
typedef QaRouteNameResolver = String? Function(Route<dynamic> route);

/// Decides whether a Flutter route should produce timeline events.
typedef QaRouteFilter = bool Function(Route<dynamic> route);

/// Observes a Navigator and publishes route events to a shared controller.
final class QaRouteObserver extends NavigatorObserver {
  /// Creates a route observer.
  QaRouteObserver({
    required this.controller,
    this.routeNameResolver,
    this.shouldTrackRoute,
    this.includeNonPageRoutes = false,
    Set<String> ignoredRoutes = const <String>{},
  }) : ignoredRoutes = Set<String>.unmodifiable(ignoredRoutes);

  /// The controller shared with QA Inspector and other collectors.
  final QaInspectorController controller;

  /// An optional application-specific route-name resolver.
  final QaRouteNameResolver? routeNameResolver;

  /// An optional application-specific route filter.
  final QaRouteFilter? shouldTrackRoute;

  /// Whether routes other than [PageRoute] produce events.
  final bool includeNonPageRoutes;

  /// Resolved route names that should not produce events.
  final Set<String> ignoredRoutes;

  int? _currentRouteIdentity;
  String? _currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _safelyObserve(() {
      final toRoute = _resolve(route);
      final fromRoute = previousRoute == null ? null : _resolve(previousRoute);
      _currentRouteIdentity = identityHashCode(route);
      _currentRouteName = toRoute;
      _recordIfTracked(
        route: route,
        action: QaRouteAction.push,
        fromRoute: fromRoute,
        toRoute: toRoute,
      );
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _safelyObserve(() {
      final fromRoute = _resolve(route);
      final toRoute = previousRoute == null ? null : _resolve(previousRoute);
      _currentRouteIdentity = previousRoute == null
          ? null
          : identityHashCode(previousRoute);
      _currentRouteName = toRoute;
      _recordIfTracked(
        route: route,
        action: QaRouteAction.pop,
        fromRoute: fromRoute,
        toRoute: toRoute,
      );
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _safelyObserve(() {
      final fromRoute = oldRoute == null ? null : _resolve(oldRoute);
      final toRoute = newRoute == null ? null : _resolve(newRoute);
      final replacedCurrent =
          oldRoute == null ||
          _currentRouteIdentity == identityHashCode(oldRoute);
      if (replacedCurrent) {
        _currentRouteIdentity = newRoute == null
            ? null
            : identityHashCode(newRoute);
        _currentRouteName = toRoute;
      }
      final trackedRoute = newRoute ?? oldRoute;
      if (trackedRoute != null) {
        _recordIfTracked(
          route: trackedRoute,
          action: QaRouteAction.replace,
          fromRoute: fromRoute,
          toRoute: toRoute,
        );
      }
    });
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _safelyObserve(() {
      final fromRoute = _resolve(route);
      final toRoute = previousRoute == null ? null : _resolve(previousRoute);
      if (_currentRouteIdentity == identityHashCode(route)) {
        _currentRouteIdentity = previousRoute == null
            ? null
            : identityHashCode(previousRoute);
        _currentRouteName = toRoute;
      }
      _recordIfTracked(
        route: route,
        action: QaRouteAction.remove,
        fromRoute: fromRoute,
        toRoute: toRoute,
      );
    });
  }

  void _recordIfTracked({
    required Route<dynamic> route,
    required QaRouteAction action,
    required String? fromRoute,
    required String? toRoute,
  }) {
    if (!_shouldTrack(
      route,
      action == QaRouteAction.push ? toRoute : fromRoute,
    )) {
      return;
    }

    controller.recordRoute(
      action: action,
      fromRoute: fromRoute,
      toRoute: toRoute,
      currentRoute: _currentRouteName,
    );
  }

  bool _shouldTrack(Route<dynamic> route, String? routeName) {
    if (!includeNonPageRoutes && route is! PageRoute<dynamic>) {
      return false;
    }
    if (routeName != null && ignoredRoutes.contains(routeName)) {
      return false;
    }
    return shouldTrackRoute?.call(route) ?? true;
  }

  String _resolve(Route<dynamic> route) {
    String? resolvedName;
    try {
      resolvedName = routeNameResolver?.call(route);
    } catch (_) {
      resolvedName = null;
    }
    return resolvedName ?? route.settings.name ?? '<unnamed>';
  }

  void _safelyObserve(VoidCallback observation) {
    if (!controller.config.enabled) {
      return;
    }
    try {
      observation();
    } catch (_) {
      // Diagnostics are best-effort and must never interrupt navigation.
    }
  }
}
