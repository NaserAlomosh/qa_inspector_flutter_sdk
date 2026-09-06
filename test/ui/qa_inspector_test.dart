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

  testWidgets('QA button uses semantics without a Tooltip', (tester) async {
    final controller = _controller();
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(controller));

    expect(find.byType(Tooltip), findsNothing);
    expect(find.bySemanticsLabel('Open QA Inspector'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
    controller.dispose();
  });

  testWidgets('message follows locale and remains stable during updates', (tester) async {
    final controller = _controller();
    await tester.pumpWidget(_localizedHost(controller, const Locale('ar')));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();

    final initial = tester.widget<Text>(find.descendant(of: find.byKey(const Key('qa-session-message')), matching: find.byType(Text))).data;
    expect(initial, matches(RegExp(r'[\u0600-\u06FF]')));
    _addNetwork(controller, id: 'stable', path: '/stable');
    await tester.pump();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('qa-notes-field')), 'خطوات الاختبار');
    await tester.pump();
    final after = tester.widget<Text>(find.descendant(of: find.byKey(const Key('qa-session-message')), matching: find.byType(Text))).data;
    expect(after, initial);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('dark host brightness selects the dark inspector theme', (tester) async {
    final controller = _controller();
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: QaInspector(controller: controller, child: const SizedBox())));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const Key('qa-inspector-overlay')));
    expect(Theme.of(context).brightness, Brightness.dark);
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

  testWidgets('builder integration uses device safe area without exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(bottom: 102);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });
    final controller = _controller();

    await tester.pumpWidget(_host(controller));
    await tester.pump();

    expect(find.byKey(const Key('host')), findsOneWidget);
    expect(find.byKey(const Key('qa-inspector-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
    final buttonBottom = tester.getBottomLeft(
      find.byKey(const Key('qa-inspector-button')),
    ).dy;
    expect(buttonBottom, lessThanOrEqualTo(806));
    controller.dispose();
  });

  testWidgets('closing inspector restores host interaction', (tester) async {
    final controller = _controller();
    var hostTaps = 0;
    await tester.pumpWidget(
      _host(
        controller,
        host: TextButton(
          key: const Key('host-action'),
          onPressed: () => hostTaps++,
          child: const Text('Host action'),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('host-action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('qa-inspector-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('host-action')));

    expect(hostTaps, 1);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('inspector routes and dialogs stay off the host navigator', (
    tester,
  ) async {
    final controller = _controller();
    final observer = _CountingNavigatorObserver();
    await tester.pumpWidget(_host(controller, observer: observer));
    final initialEvents = observer.events;

    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-clear-session')));
    await tester.pumpAndSettle();
    expect(find.text('Clear QA session?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(observer.events, initialEvents);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('host navigator observer still receives host navigation', (
    tester,
  ) async {
    final controller = _controller();
    final observer = _CountingNavigatorObserver();
    await tester.pumpWidget(
      _host(controller, observer: observer, host: const _NavigationHost()),
    );
    final initialEvents = observer.events;

    await tester.tap(find.byKey(const Key('host-navigation')));
    await tester.pumpAndSettle();

    expect(find.text('Host destination'), findsOneWidget);
    expect(observer.events, initialEvents + 1);
    expect(tester.takeException(), isNull);
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
      expect(tester.takeException(), isNull);

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
    expect(find.text('Clear QA session?'), findsOneWidget);
    expect(controller.events, isNotEmpty);
    await tester.tap(find.byKey(const Key('qa-confirm-clear')));
    await tester.pumpAndSettle();

    expect(controller.events, isEmpty);
    expect(controller.notes, isEmpty);
    expect(controller.sessionGeneration, generation + 1);
    expect(find.text('No events yet'), findsOneWidget);

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

  testWidgets('report actions copy a stable sanitized step report', (tester) async {
    final controller = _controller();
    _addRoute(controller, id: 'report-route', from: null, to: '/transfer');
    _addNetwork(controller, id: 'report-api', path: '/validate');
    controller.updateNotes('Validation issue');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
          controller.clearSession();
          _addNetwork(controller, id: 'new-session', path: '/new');
        }
        return null;
      },
    );

    await tester.pumpWidget(_openHost(controller));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-report-actions')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qa-copy-report')), findsOneWidget);
    expect(find.byKey(const Key('qa-export-png')), findsOneWidget);
    await tester.tap(find.byKey(const Key('qa-copy-report')));
    await tester.pumpAndSettle();

    expect(copied, contains('QA REPORT'));
    expect(copied, contains('STEP 1'));
    expect(copied, contains('Validation issue'));
    expect(copied, contains('POST /validate'));
    expect(copied, contains('"password": "***"'));
    expect(copied, isNot(contains('raw-secret')));
    expect(copied, isNot(contains('/new')));
    expect(find.text('QA report copied.'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('PNG export succeeds without changing host navigation or inspector usability', (tester) async {
    final controller = _controller();
    _addRoute(controller, id: 'export-route', from: null, to: '/export');
    final observer = _CountingNavigatorObserver();
    await tester.pumpWidget(_host(controller, observer: observer));
    await tester.tap(find.byKey(const Key('qa-inspector-button')));
    await tester.pumpAndSettle();
    final routeEvents = observer.events;
    await tester.tap(find.byKey(const Key('qa-report-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-export-png')));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('PNG report generated: qa_report_'), findsOneWidget);
    expect(observer.events, routeEvents);
    expect(find.text('Timeline'), findsOneWidget);
    await tester.tap(find.text('APIs'));
    await tester.pumpAndSettle();
    expect(find.text('APIs'), findsWidgets);
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
    expect(find.byKey(const Key('qa-timeline-list')), findsOneWidget);
    controller.dispose();
  });
}

QaInspectorController _controller() => QaInspectorController(
  config: const QaInspectorConfig(enabled: true),
);

Widget _host(
  QaInspectorController controller, {
  NavigatorObserver? observer,
  Widget host = const Text('Host child', key: Key('host')),
}) =>
    MaterialApp(
      navigatorObservers: <NavigatorObserver>[
        if (observer != null) observer,
      ],
      home: Scaffold(body: Center(child: host)),
      builder: (context, child) => QaInspector(
        controller: controller,
        child: child ?? const SizedBox.shrink(),
      ),
    );

Widget _openHost(QaInspectorController controller) => MaterialApp(
  home: const Scaffold(body: Text('Host child', key: Key('host'))),
  builder: (context, child) => QaInspector(
    controller: controller,
    child: child ?? const SizedBox.shrink(),
  ),
);

class _NavigationHost extends StatelessWidget {
  const _NavigationHost();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: const Key('host-navigation'),
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Host destination')),
        ),
      ),
      child: const Text('Navigate'),
    );
  }
}

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

class _CountingNavigatorObserver extends NavigatorObserver {
  int events = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    events++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    events++;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    events++;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    events++;
  }
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

Widget _localizedHost(QaInspectorController controller, Locale locale) =>
    MaterialApp(
      home: Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: locale,
          child: QaInspector(controller: controller, child: const Scaffold()),
        ),
      ),
    );
