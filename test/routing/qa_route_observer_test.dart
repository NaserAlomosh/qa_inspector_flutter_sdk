import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  group('QaRouteObserver', () {
    late QaInspectorController controller;
    late QaRouteObserver observer;

    setUp(() {
      controller = QaInspectorController(
        config: const QaInspectorConfig(enabled: true),
      );
      observer = QaRouteObserver(controller: controller);
    });

    tearDown(() => controller.dispose());

    test('initial push establishes route context and creates an event', () {
      observer.didPush(_route('/home'), null);

      final event = _events(controller).single;
      expect(event.action, QaRouteAction.push);
      expect(event.fromRoute, isNull);
      expect(event.toRoute, '/home');
      expect(event.currentRoute, '/home');
      expect(controller.currentRoute, '/home');
    });

    test('push records source, destination, and current route', () {
      final home = _route('/home');
      observer
        ..didPush(home, null)
        ..didPush(_route('/transfer'), home);

      final event = _events(controller).last;
      expect(event.action, QaRouteAction.push);
      expect(event.fromRoute, '/home');
      expect(event.toRoute, '/transfer');
      expect(event.currentRoute, '/transfer');
    });

    test('pop records the popped route and newly visible route', () {
      final home = _route('/home');
      final transfer = _route('/transfer');
      observer
        ..didPush(home, null)
        ..didPush(transfer, home)
        ..didPop(transfer, home);

      final event = _events(controller).last;
      expect(event.action, QaRouteAction.pop);
      expect(event.fromRoute, '/transfer');
      expect(event.toRoute, '/home');
      expect(event.currentRoute, '/home');
      expect(controller.currentRoute, '/home');
    });

    test('replace records old and new visible routes', () {
      final login = _route('/login');
      final home = _route('/home');
      observer
        ..didPush(login, null)
        ..didReplace(oldRoute: login, newRoute: home);

      final event = _events(controller).last;
      expect(event.action, QaRouteAction.replace);
      expect(event.fromRoute, '/login');
      expect(event.toRoute, '/home');
      expect(event.currentRoute, '/home');
    });

    test('removing the current route exposes the previous route', () {
      final home = _route('/home');
      final transfer = _route('/transfer');
      observer
        ..didPush(home, null)
        ..didPush(transfer, home)
        ..didRemove(transfer, home);

      final event = _events(controller).last;
      expect(event.action, QaRouteAction.remove);
      expect(event.fromRoute, '/transfer');
      expect(event.toRoute, '/home');
      expect(event.currentRoute, '/home');
    });

    test('removing a non-current route keeps the visible route unchanged', () {
      final home = _route('/home');
      final transfer = _route('/transfer');
      final confirmation = _route('/confirmation');
      observer
        ..didPush(home, null)
        ..didPush(transfer, home)
        ..didPush(confirmation, transfer)
        ..didRemove(transfer, home);

      final event = _events(controller).last;
      expect(event.action, QaRouteAction.remove);
      expect(event.fromRoute, '/transfer');
      expect(event.toRoute, '/home');
      expect(event.currentRoute, '/confirmation');
      expect(controller.currentRoute, '/confirmation');
    });

    test('uses a stable name for unnamed routes', () {
      observer.didPush(_route(null), null);

      expect(_events(controller).single.toRoute, '<unnamed>');
      expect(controller.currentRoute, '<unnamed>');
    });

    test('uses a custom route resolver', () {
      observer = QaRouteObserver(
        controller: controller,
        routeNameResolver: (_) => '/resolved',
      );

      observer.didPush(_route('/original'), null);

      expect(_events(controller).single.toRoute, '/resolved');
    });

    test('falls back safely when a custom resolver throws', () {
      observer = QaRouteObserver(
        controller: controller,
        routeNameResolver: (_) => throw StateError('resolver failed'),
      );

      expect(
        () => observer.didPush(_route('/fallback'), null),
        returnsNormally,
      );
      expect(_events(controller).single.toRoute, '/fallback');
    });

    test('supports ignored routes and custom filtering', () {
      observer = QaRouteObserver(
        controller: controller,
        ignoredRoutes: const <String>{'/ignored'},
        shouldTrackRoute: (route) => route.settings.name != '/filtered',
      );

      observer
        ..didPush(_route('/ignored'), null)
        ..didPush(_route('/filtered'), null)
        ..didPush(_route('/tracked'), null);

      expect(_events(controller).map((event) => event.toRoute), <String>[
        '/tracked',
      ]);
    });

    test('route events contain lightweight values and preserve order', () {
      final home = _route('/home');
      final details = _route('/details');
      observer
        ..didPush(home, null)
        ..didPush(details, home)
        ..didPop(details, home);

      expect(_events(controller).map((event) => event.action), <QaRouteAction>[
        QaRouteAction.push,
        QaRouteAction.push,
        QaRouteAction.pop,
      ]);
      for (final event in _events(controller)) {
        expect(event.fromRoute, anyOf(isNull, isA<String>()));
        expect(event.toRoute, anyOf(isNull, isA<String>()));
        expect(event.currentRoute, anyOf(isNull, isA<String>()));
      }
    });

    test('filter failure never escapes into navigation', () {
      observer = QaRouteObserver(
        controller: controller,
        shouldTrackRoute: (_) => throw StateError('filter failed'),
      );

      expect(() => observer.didPush(_route('/home'), null), returnsNormally);
      expect(controller.events, isEmpty);
    });
  });

  test('disabled mode does not resolve, update context, or create events', () {
    final controller = QaInspectorController(
      config: const QaInspectorConfig(enabled: false),
    );
    var resolverCalls = 0;
    final observer = QaRouteObserver(
      controller: controller,
      routeNameResolver: (route) {
        resolverCalls++;
        return route.settings.name;
      },
    );

    observer.didPush(_route('/home'), null);

    expect(resolverCalls, 0);
    expect(controller.currentRoute, isNull);
    expect(controller.events, isEmpty);
    controller.dispose();
  });

  test('multiple observers share route context and timeline', () {
    final controller = QaInspectorController(
      config: const QaInspectorConfig(enabled: true),
    );
    final rootObserver = QaRouteObserver(controller: controller);
    final nestedObserver = QaRouteObserver(controller: controller);

    rootObserver.didPush(_route('/root'), null);
    nestedObserver.didPush(_route('/tab/details'), null);

    expect(controller.currentRoute, '/tab/details');
    expect(_events(controller), hasLength(2));
    controller.dispose();
  });
}

List<QaRouteEvent> _events(QaInspectorController controller) =>
    controller.events.whereType<QaRouteEvent>().toList();

MaterialPageRoute<void> _route(String? name) => MaterialPageRoute<void>(
  settings: RouteSettings(name: name),
  builder: (_) => const SizedBox(),
);
