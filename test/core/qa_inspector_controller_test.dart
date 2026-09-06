import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  test('collectors sharing a controller publish to one ordered timeline', () {
    final controller = _enabledController();
    final firstObserver = QaRouteObserver(controller: controller);
    final secondObserver = QaRouteObserver(controller: controller);

    firstObserver.didPush(_route('/root'), null);
    secondObserver.didPush(_route('/nested'), null);

    expect(
      controller.events.whereType<QaRouteEvent>().map((event) => event.toRoute),
      <String>['/root', '/nested'],
    );
    expect(controller.currentRoute, '/nested');
    controller.dispose();
  });

  test('event IDs are unique within a controller runtime', () {
    final controller = _enabledController();
    final observer = QaRouteObserver(controller: controller);

    for (var index = 0; index < 1000; index++) {
      observer.didPush(_route('/route-$index'), null);
    }

    expect(controller.events.map((event) => event.id).toSet(), hasLength(200));
    controller.dispose();
  });

  test('disposal is idempotent and stops later collection', () {
    final controller = _enabledController();
    final observer = QaRouteObserver(controller: controller);
    observer.didPush(_route('/before'), null);

    controller
      ..dispose()
      ..dispose();
    expect(
      () => observer.didPush(_route('/after'), null),
      returnsNormally,
    );
    expect(controller.events, hasLength(1));
  });

  test('event snapshots cannot mutate the shared timeline', () {
    final controller = _enabledController();
    QaRouteObserver(controller: controller).didPush(_route('/home'), null);

    expect(() => controller.events.clear(), throwsUnsupportedError);
    expect(controller.events, hasLength(1));
    controller.dispose();
  });
}

QaInspectorController _enabledController() => QaInspectorController(
  config: const QaInspectorConfig(enabled: true),
);

MaterialPageRoute<void> _route(String name) => MaterialPageRoute<void>(
  settings: RouteSettings(name: name),
  builder: (_) => const SizedBox(),
);
