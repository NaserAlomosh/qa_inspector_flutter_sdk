import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  testWidgets('keeps the host child visually unchanged', (tester) async {
    final controller = QaInspectorController(
      config: const QaInspectorConfig(enabled: true),
    );
    const hostKey = Key('host');

    await tester.pumpWidget(
      QaInspector(
        controller: controller,
        child: const SizedBox(key: hostKey),
      ),
    );

    expect(find.byKey(hostKey), findsOneWidget);
    controller.dispose();
  });

  testWidgets('does not dispose an externally owned controller', (
    tester,
  ) async {
    final controller = QaInspectorController(
      config: const QaInspectorConfig(enabled: true),
    );
    final observer = QaRouteObserver(controller: controller);

    await tester.pumpWidget(
      QaInspector(controller: controller, child: const SizedBox()),
    );
    await tester.pumpWidget(const SizedBox());

    observer.didPush(_route('/home'), null);

    expect(controller.events, hasLength(1));
    controller.dispose();
  });
}

MaterialPageRoute<void> _route(String name) => MaterialPageRoute<void>(
  settings: RouteSettings(name: name),
  builder: (_) => const SizedBox(),
);
