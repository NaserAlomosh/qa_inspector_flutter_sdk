final class QaRouteContext {
  String? get currentRoute => _currentRoute;

  String? _currentRoute;

  void update(String? routeName) {
    _currentRoute = routeName;
  }
}
