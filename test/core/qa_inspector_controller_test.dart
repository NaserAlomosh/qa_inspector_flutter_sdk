import 'package:flutter/material.dart';
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

  test('notes are in-memory, bounded, and notify read-only listeners', () {
    final controller = _enabledController();
    var notifications = 0;
    void listener() => notifications++;
    controller.changes.addListener(listener);

    controller.updateNotes('line one\nline two');
    expect(controller.notes, 'line one\nline two');
    expect(notifications, 1);

    controller.updateNotes(List<String>.filled(QaInspectorController.maxNotesLength + 10, 'x').join());
    expect(controller.notes, hasLength(QaInspectorController.maxNotesLength));
    expect(notifications, 2);

    controller.changes.removeListener(listener);
    controller.dispose();
  });

  test('clear session clears notes and events and advances generation', () {
    final controller = _enabledController();
    final observer = QaRouteObserver(controller: controller);
    observer.didPush(_route('/before'), null);
    controller.updateNotes('Issue notes');
    final generation = controller.sessionGeneration;

    controller.clearSession();

    expect(controller.events, isEmpty);
    expect(controller.notes, isEmpty);
    expect(controller.sessionGeneration, generation + 1);
    observer.didPush(_route('/after'), null);
    expect(controller.events, hasLength(1));
    controller.dispose();
  });

  test('disabled controller ignores notes without creating UI state', () {
    final controller = QaInspectorController();

    controller.updateNotes('not retained');
    controller.clearSession();

    expect(controller.notes, isEmpty);
    expect(controller.sessionGeneration, 0);
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
