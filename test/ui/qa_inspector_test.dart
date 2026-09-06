import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  testWidgets('disabled inspector renders only the host child', (tester) async {
    final controller = QaInspectorController();

    await tester.pumpWidget(_host(controller));

    expect(find.byKey(const Key('host')), findsOneWidget);
    expect(find.byKey(const Key('qa-inspector-button')), findsNothing);
    expect(find.byKey(const Key('qa-inspector-overlay')), findsNothing);
    controller.dispose();
  });

  testWidgets('enabled inspector has one button and keeps host visible', (tester) async {
    final controller = _controller();

    await tester.pumpWidget(_host(controller));
    await tester.pump();

    expect(find.byKey(const Key('host')), findsOneWidget);
    expect(find.byKey(const Key('qa-inspector-button')), findsOneWidget);
    controller.dispose();
  });

  testWidgets('opens and closes repeatedly without duplicate buttons', (tester) async {
    final controller = _controller();
    await tester.pumpWidget(_host(controller));

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(const Key('qa-inspector-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qa-inspector-overlay')), findsOneWidget);
      expect(find.byKey(const Key('qa-inspector-button')), findsNothing);

      await tester.tap(find.byKey(const Key('qa-inspector-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qa-inspector-overlay')), findsNothing);
      expect(find.byKey(const Key('qa-inspector-button')), findsOneWidget);
    }
    expect(find.byKey(const Key('host')), findsOneWidget);
    controller.dispose();
  });

  testWidgets('timeline displays mixed route and network events in insertion order', (tester) async {
    final controller = _controller();
    _addRoute(controller, id: 'route-1', to: '/transfer');
    _addNetwork(controller, id: 'api-1', path: '/validate');
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();

    expect(find.text('PUSH'), findsOneWidget);
    expect(find.textContaining('/home → /transfer'), findsOneWidget);
    expect(find.textContaining('POST /validate'), findsOneWidget);
    expect(find.textContaining('200 • 182 ms'), findsOneWidget);
    expect(find.textContaining('/transfer •'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('API filters, method search, and route grouping derive from timeline', (tester) async {
    final controller = _controller();
    _addNetwork(controller, id: 'success', path: '/accounts', method: 'GET');
    _addNetwork(controller, id: 'failed', path: '/transfer', outcome: QaNetworkOutcome.failure, status: 500);
    _addNetwork(controller, id: 'cancelled', path: '/cancel', outcome: QaNetworkOutcome.cancelled, status: null, route: '/home');
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APIs'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qa-network-success')), findsOneWidget);
    expect(find.byKey(const Key('qa-network-failed')), findsOneWidget);
    expect(find.byKey(const Key('qa-network-cancelled')), findsOneWidget);

    await tester.tap(find.byKey(const Key('qa-filter-failed')));
    await tester.pump();
    expect(find.byKey(const Key('qa-network-failed')), findsOneWidget);
    expect(find.byKey(const Key('qa-network-success')), findsNothing);

    await tester.tap(find.byKey(const Key('qa-filter-success')));
    await tester.pump();
    expect(find.byKey(const Key('qa-network-success')), findsOneWidget);
    expect(find.byKey(const Key('qa-network-failed')), findsNothing);

    await tester.tap(find.byKey(const Key('qa-filter-cancelled')));
    await tester.pump();
    expect(find.byKey(const Key('qa-network-cancelled')), findsOneWidget);
    expect(find.byKey(const Key('qa-network-success')), findsNothing);

    await tester.tap(find.byKey(const Key('qa-filter-all')));
    await tester.enterText(find.byKey(const Key('qa-api-search')), 'GET');
    await tester.pump();
    expect(find.byKey(const Key('qa-network-success')), findsOneWidget);
    expect(find.byKey(const Key('qa-network-failed')), findsNothing);

    await tester.enterText(find.byKey(const Key('qa-api-search')), '/cancel');
    await tester.pump();
    expect(find.byKey(const Key('qa-network-cancelled')), findsOneWidget);
    expect(find.text('Originating route'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('API detail shows successful response, sanitization, error and truncation', (tester) async {
    final controller = _controller();
    _addNetwork(controller, id: 'detail', path: '/detail', truncated: true);
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APIs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-network-detail')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qa-api-details')), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Request'), findsOneWidget);
    expect(find.text('Response'), findsOneWidget);
    expect(find.textContaining('"password": "***"'), findsOneWidget);
    expect(find.textContaining('"result": "accepted"'), findsOneWidget);
    expect(find.textContaining('Payload truncated'), findsWidgets);
    expect(find.textContaining('No error metadata'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qa-api-details-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qa-api-details')), findsNothing);
    controller.dispose();
  });

  testWidgets('failed API detail displays safe error metadata', (tester) async {
    final controller = _controller();
    _addNetwork(controller, id: 'error', path: '/failure', outcome: QaNetworkOutcome.failure, status: 422);
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APIs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-network-error')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Type: badResponse'), findsOneWidget);
    expect(find.textContaining('Message: Safe failure'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('routes tab uses central events and handles unnamed routes', (tester) async {
    final controller = _controller();
    _addRoute(controller, id: 'unnamed', from: null, to: null);
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Routes'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qa-route-unnamed')), findsOneWidget);
    expect(find.textContaining('<unnamed> → <unnamed>'), findsOneWidget);
    expect(find.textContaining('Current: <unnamed>'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('notes support multiline editing and enforce the session limit', (tester) async {
    final controller = _controller();
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('qa-notes-field')), 'First line\nSecond line');
    expect(controller.notes, 'First line\nSecond line');
    controller.updateNotes(List<String>.filled(5100, 'x').join());
    await tester.pump();
    expect(controller.notes, hasLength(QaInspectorController.maxNotesLength));
    controller.dispose();
  });

  testWidgets('clear requires confirmation and clears events and notes', (tester) async {
    final controller = _controller();
    _addRoute(controller, id: 'before');
    controller.updateNotes('Reproduction note');
    final generation = controller.sessionGeneration;
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qa-clear-session')));
    await tester.pumpAndSettle();
    expect(find.text('Clear current QA session?'), findsOneWidget);
    expect(controller.events, isNotEmpty);
    await tester.tap(find.byKey(const Key('qa-confirm-clear')));
    await tester.pumpAndSettle();

    expect(controller.events, isEmpty);
    expect(controller.notes, isEmpty);
    expect(controller.sessionGeneration, generation + 1);
    expect(find.text('No timeline events yet'), findsOneWidget);

    _addRoute(controller, id: 'after');
    await tester.pump();
    expect(find.byKey(const Key('qa-route-after')), findsOneWidget);
    controller.dispose();
  });

  testWidgets('timeline notifications do not rebuild the host subtree', (tester) async {
    final controller = _controller();
    var builds = 0;
    final host = _BuildCounter(onBuild: () => builds++);
    await tester.pumpWidget(QaInspector(controller: controller, child: host));
    final initialBuilds = builds;

    _addRoute(controller, id: 'background');
    await tester.pump();

    expect(builds, initialBuilds);
    controller.dispose();
  });

  testWidgets('copy actions copy only sanitized event data', (tester) async {
    final controller = _controller();
    _addNetwork(controller, id: 'copy', path: '/copy');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APIs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-network-copy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-copy-api-details')));
    await tester.pump();

    expect(copied, contains('"password": "***"'));
    expect(copied, isNot(contains('raw-secret')));
    controller.dispose();
  });

  testWidgets('bounded large timeline renders lazily without errors', (tester) async {
    final controller = QaInspectorController(config: const QaInspectorConfig(enabled: true, maxEvents: 200));
    for (var index = 0; index < 250; index++) {
      _addNetwork(controller, id: '$index', path: '/item/$index');
    }
    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();

    expect(controller.events, hasLength(200));
    expect(tester.takeException(), isNull);
    expect(find.byType(ListTile), findsWidgets);
    controller.dispose();
  });
}

QaInspectorController _controller() => QaInspectorController(
  config: const QaInspectorConfig(enabled: true),
);

Widget _host(QaInspectorController controller) => QaInspector(
  controller: controller,
  child: const MaterialApp(home: Scaffold(body: Text('Host child', key: Key('host')))),
);

Widget _openHost(QaInspectorController controller) => MaterialApp(
  home: Builder(
    builder: (context) => QaInspector(
      controller: controller,
      child: const Scaffold(body: Text('Host child', key: Key('host'))),
    ),
  ),
);

void _addRoute(
  QaInspectorController controller, {
  required String id,
  String? from = '/home',
  String? to = '/transfer',
}) {
  controller.recordEvent(
    QaRouteEvent(
      id: id,
      timestamp: DateTime(2026, 1, 1, 10),
      action: QaRouteAction.push,
      fromRoute: from,
      toRoute: to,
      currentRoute: to,
    ),
    sessionGeneration: controller.sessionGeneration,
  );
}

void _addNetwork(
  QaInspectorController controller, {
  required String id,
  required String path,
  String method = 'POST',
  QaNetworkOutcome outcome = QaNetworkOutcome.success,
  int? status = 200,
  String? route = '/transfer',
  bool truncated = false,
}) {
  final startedAt = DateTime(2026, 1, 1, 10, 0, 1);
  controller.recordEvent(
    QaNetworkEvent(
      id: id,
      timestamp: startedAt,
      method: method,
      url: 'https://example.test$path?token=***',
      path: path,
      queryParameters: const <String, Object?>{'token': '***'},
      requestHeaders: const <String, Object?>{'authorization': '***'},
      requestBody: QaPayloadCapture(
        data: const <String, Object?>{'password': '***'},
        isTruncated: truncated,
        originalSize: truncated ? 60000 : 24,
        capturedSize: truncated ? 48 : 24,
      ),
      responseHeaders: const <String, Object?>{'content-type': 'application/json'},
      responseBody: QaPayloadCapture(
        data: const <String, Object?>{'result': 'accepted'},
        isTruncated: truncated,
        originalSize: truncated ? 60000 : 21,
        capturedSize: truncated ? 48 : 21,
      ),
      statusCode: status,
      startedAt: startedAt,
      completedAt: startedAt.add(const Duration(milliseconds: 182)),
      duration: const Duration(milliseconds: 182),
      route: route,
      outcome: outcome,
      error: outcome == QaNetworkOutcome.failure
          ? const QaNetworkError(type: 'badResponse', message: 'Safe failure')
          : outcome == QaNetworkOutcome.cancelled
              ? const QaNetworkError(type: 'cancel', message: 'Request cancelled')
              : null,
    ),
    sessionGeneration: controller.sessionGeneration,
  );
}

class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const MaterialApp(home: Scaffold(body: Text('Host child')));
  }
}
