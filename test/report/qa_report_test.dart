import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  final base = DateTime.utc(2026, 9, 6, 19, 30, 22);

  group('QaReportBuilder', () {
    test('builds an empty immutable snapshot', () {
      final data = const QaReportBuilder().build(
        events: const <QaEvent>[],
        notes: '',
        currentRoute: null,
        generatedAt: base,
      );

      expect(data.steps, isEmpty);
      expect(data.totalApis, 0);
      expect(data.currentRoute, '<unknown>');
      expect(() => data.steps.add(_step()), throwsUnsupportedError);
    });

    test('preserves repeated visits, zero API screens, and request-start association', () {
      final events = <QaEvent>[
        _route('r1', base, null, '/home'),
        _network('late', base.add(const Duration(seconds: 1)), '/home'),
        _route('r2', base.add(const Duration(seconds: 2)), '/home', '/transfer'),
        _route('r3', base.add(const Duration(seconds: 3)), '/transfer', '/home', action: QaRouteAction.pop),
        _network('second', base.add(const Duration(seconds: 4)), '/home'),
      ];
      final data = const QaReportBuilder().build(
        events: events,
        notes: 'Journey stopped',
        currentRoute: '/home',
        generatedAt: base,
      );

      expect(data.steps.map((step) => step.route), <String>['/home', '/transfer', '/home']);
      expect(data.steps[0].apis.single.path, '/late');
      expect(data.steps[1].apis, isEmpty);
      expect(data.steps[2].apis.single.path, '/second');
      expect(data.steps[0].nextNavigation?.action, QaRouteAction.push);
      expect(data.steps[1].nextNavigation?.action, QaRouteAction.pop);
      expect(data.steps.last.nextNavigation, isNull);
      expect(data.notes, 'Journey stopped');
    });

    test('orders parallel APIs by start time and insertion order for ties', () {
      final events = <QaEvent>[
        _route('route', base, null, '/home'),
        _network('cards', base.add(const Duration(seconds: 2)), '/home', completedOffset: 3),
        _network('accounts', base.add(const Duration(seconds: 1)), '/home', completedOffset: 9),
        _network('tie', base.add(const Duration(seconds: 1)), '/home', completedOffset: 2),
      ];
      final data = const QaReportBuilder().build(events: events, notes: '', currentRoute: '/home', generatedAt: base);
      expect(data.steps.single.apis.map((api) => api.path), <String>['/accounts', '/tie', '/cards']);
    });

    test('remove does not invent a step and no-route APIs use fallback', () {
      final removed = _route('remove', base, '/old', '/home', action: QaRouteAction.remove);
      final api = _network('api', base, null);
      final data = const QaReportBuilder().build(events: <QaEvent>[removed, api], notes: '', currentRoute: null, generatedAt: base);
      expect(data.steps, hasLength(1));
      expect(data.steps.single.route, '<unknown>');
      expect(data.steps.single.apis, hasLength(1));
    });

    test('includes outcomes, payloads, errors, and truncation without raw secrets', () {
      final api = _network(
        'failure',
        base,
        '/confirm',
        outcome: QaNetworkOutcome.failure,
        request: const <String, Object?>{'password': '***', 'otp': '***'},
        response: const <String, Object?>{'access_token': '***'},
        truncated: true,
      );
      final data = const QaReportBuilder().build(events: <QaEvent>[api], notes: '', currentRoute: '/confirm', generatedAt: base);
      final reportApi = data.steps.single.apis.single;
      expect(reportApi.outcome, QaNetworkOutcome.failure);
      expect(reportApi.requestBody, contains('***'));
      expect(reportApi.responseBody, contains('***'));
      expect(reportApi.responseTruncated, isTrue);
      expect(reportApi.errorType, 'badResponse');
      final representation = '${reportApi.requestBody}${reportApi.responseBody}';
      expect(representation, isNot(contains('raw-password')));
      expect(representation, isNot(contains('bearer-secret')));
    });

    test('applies report and payload limits with omission counts', () {
      final events = <QaEvent>[];
      for (var i = 0; i < 3; i++) {
        events.add(_route('r$i', base.add(Duration(seconds: i)), i == 0 ? null : '/p${i - 1}', '/p$i'));
        events.add(_network('a$i', base.add(Duration(seconds: i, milliseconds: 1)), '/p$i', response: {'value': '123456789'}));
      }
      final data = const QaReportBuilder(limits: QaReportLimits(maxSteps: 2, maxApis: 1, maxTextPayloadCharacters: 5)).build(
        events: events,
        notes: '',
        currentRoute: '/p2',
        generatedAt: base,
      );
      expect(data.steps, hasLength(2));
      expect(data.omittedSteps, 1);
      expect(data.omittedApis, 2);
      expect(data.steps.first.apis.single.responseBody, contains('[preview limited]'));
    });

    test('built report is unchanged when source events change or session clears', () {
      final source = <QaEvent>[_network('one', base, '/home')];
      final data = const QaReportBuilder().build(events: source, notes: 'snapshot', currentRoute: '/home', generatedAt: base);
      source..clear()..add(_network('two', base, '/other'));
      expect(data.steps.single.apis.single.path, '/one');
      expect(data.notes, 'snapshot');
    });
  });

  test('text report follows the canonical journey structure', () {
    final data = const QaReportBuilder().build(
      events: <QaEvent>[
        _route('route', base, null, '/confirmation'),
        _network('api', base.add(const Duration(milliseconds: 1)), '/confirmation', outcome: QaNetworkOutcome.failure),
      ],
      notes: 'Confirmation failed.',
      currentRoute: '/confirmation',
      generatedAt: base,
    );
    final text = const QaReportTextRenderer().render(data);
    for (final expected in <String>[
      'QA REPORT', 'Generated: 2026-09-06T19:30:22.000Z', 'Current Screen: /confirmation',
      'Total Screens: 1', 'Total APIs: 1', 'Failed APIs: 1', 'Issue Notes:', 'Confirmation failed.',
      'STEP 1', 'Route: /confirmation', 'APIs Triggered: 1', 'POST /api', 'Status: 500',
      'Request:', 'Response:', 'Error:', 'NEXT ACTION:', 'None',
    ]) {
      expect(text, contains(expected));
    }
  });

  test('filename and clipboard limits are deterministic', () {
    expect(qaReportPngFilename(base), 'qa_report_20260906_193022.png');
    final data = const QaReportBuilder().build(
      events: <QaEvent>[_network('clipboard', base, '/home')],
      notes: 'A long report note',
      currentRoute: '/home',
      generatedAt: base,
    );
    final text = const QaReportTextRenderer().renderForClipboard(
      data,
      maxCharacters: 100,
    );
    expect(text, hasLength(100));
    expect(text, endsWith('[report truncated for clipboard safety]'));
  });

  group('Phase 7 report semantics', () {
    QaReportData build(List<QaEvent> events, {String? currentRoute = '/final', QaReportLimits limits = const QaReportLimits()}) =>
        QaReportBuilder(limits: limits).build(events: events, notes: '', currentRoute: currentRoute, generatedAt: base);

    test('renders PUSH, POP, and REPLACE as next-navigation semantics', () {
      for (final action in <QaRouteAction>[QaRouteAction.push, QaRouteAction.pop, QaRouteAction.replace]) {
        final report = build(<QaEvent>[
          _route('first', base, null, '/first'),
          _route('next', base.add(const Duration(seconds: 1)), '/first', '/next', action: action),
        ]);
        expect(report.steps.first.nextNavigation?.action, action);
        expect(report.steps.first.nextNavigation?.fromRoute, '/first');
        expect(report.steps.first.nextNavigation?.toRoute, '/next');
      }
    });

    test('REMOVE never creates a visit or false next action', () {
      final report = build(<QaEvent>[
        _route('first', base, null, '/first'),
        _route('remove', base.add(const Duration(seconds: 1)), '/first', '/removed', action: QaRouteAction.remove),
      ], currentRoute: '/first');
      expect(report.steps, hasLength(1));
      expect(report.steps.single.nextNavigation, isNull);
      expect(report.steps.single.isFinal, isTrue);
    });

    test('repeated route visits associate APIs by originating time', () {
      final events = <QaEvent>[];
      for (var i = 0; i < 4; i++) {
        events.add(_route('r$i', base.add(Duration(seconds: i * 2)), i == 0 ? null : '/same', '/same'));
        events.add(_network('a$i', base.add(Duration(seconds: i * 2 + 1)), '/same'));
      }
      final report = build(events, currentRoute: '/same');
      expect(report.steps, hasLength(4));
      for (var i = 0; i < 4; i++) {
        expect(report.steps[i].apis.single.path, '/a$i');
      }
    });

    test('a request at a transition timestamp belongs to the new visit', () {
      final transition = base.add(const Duration(seconds: 1));
      final report = build(<QaEvent>[
        _route('home', base, null, '/home'),
        _network('exact', transition, '/details'),
        _route('details', transition, '/home', '/details'),
      ], currentRoute: '/details');
      expect(report.steps.first.apis, isEmpty);
      expect(report.steps.last.apis.single.path, '/exact');
    });

    test('equal API timestamps retain source insertion order', () {
      final report = build(<QaEvent>[
        _route('home', base, null, '/home'),
        _network('first', base, '/home'),
        _network('second', base, '/home'),
        _network('third', base, '/home'),
      ], currentRoute: '/home');
      expect(report.steps.single.apis.map((api) => api.path), <String>['/first', '/second', '/third']);
    });

    test('completion after navigation does not move an API from its originating step', () {
      final report = build(<QaEvent>[
        _route('home', base, null, '/home'),
        _network('slow', base.add(const Duration(milliseconds: 1)), '/home', completedOffset: 60),
        _route('next', base.add(const Duration(seconds: 2)), '/home', '/next'),
      ], currentRoute: '/next');
      expect(report.steps.first.apis.single.path, '/slow');
      expect(report.steps.last.apis, isEmpty);
    });

    test('success, failure, and cancellation retain distinct data', () {
      final report = build(<QaEvent>[
        _network('success', base, '/home', response: const {'result': 'accepted'}),
        _network('failed', base.add(const Duration(seconds: 1)), '/home', outcome: QaNetworkOutcome.failure, response: const {'reason': 'declined'}),
        _network('cancelled', base.add(const Duration(seconds: 2)), '/home', outcome: QaNetworkOutcome.cancelled),
      ], currentRoute: '/home');
      final apis = report.steps.single.apis;
      expect(apis[0].responseBody, contains('accepted'));
      expect(apis[1].responseBody, contains('declined'));
      expect(apis[1].errorType, 'badResponse');
      expect(apis[1].errorMessage, 'Safe failure');
      expect(apis[2].outcome, QaNetworkOutcome.cancelled);
      expect(apis[2].isFailure, isFalse);
    });

    test('zero-API and final/current route data are preserved', () {
      final report = build(<QaEvent>[
        _route('one', base, null, '/one'),
        _route('two', base.add(const Duration(seconds: 1)), '/one', '/two'),
      ], currentRoute: '/two');
      expect(report.steps.every((step) => step.apis.isEmpty), isTrue);
      expect(report.steps.last.nextNavigation, isNull);
      expect(report.steps.last.isFinal, isTrue);
      expect(report.currentRoute, '/two');
    });

    test('no-route APIs are safe and route-less sessions keep every API', () {
      final report = build(<QaEvent>[
        _network('null', base, null),
        _network('captured-a', base.add(const Duration(seconds: 1)), '/a'),
        _network('captured-b', base.add(const Duration(seconds: 2)), '/b'),
      ], currentRoute: null);
      expect(report.totalApis, 3);
      expect(report.steps.single.apis, hasLength(3));
      expect(report.steps.single.route, QaReportBuilder.unknownRoute);
    });

    test('maxSteps and maxApis report accurate global and per-step omissions', () {
      final report = build(<QaEvent>[
        _route('one', base, null, '/one'),
        _network('one-a', base.add(const Duration(milliseconds: 1)), '/one'),
        _network('one-b', base.add(const Duration(milliseconds: 2)), '/one'),
        _route('two', base.add(const Duration(seconds: 1)), '/one', '/two'),
        _network('two-a', base.add(const Duration(seconds: 1, milliseconds: 1)), '/two'),
        _network('two-b', base.add(const Duration(seconds: 1, milliseconds: 2)), '/two'),
        _route('three', base.add(const Duration(seconds: 2)), '/two', '/three'),
        _network('three-a', base.add(const Duration(seconds: 2, milliseconds: 1)), '/three'),
      ], currentRoute: '/three', limits: const QaReportLimits(maxSteps: 2, maxApis: 2));
      expect(report.steps, hasLength(2));
      expect(report.omittedSteps, 1);
      expect(report.steps[0].omittedApis, 0);
      expect(report.steps[1].omittedApis, 2);
      expect(report.omittedApis, 3);
      expect(report.totalApis, 5);
    });

    test('preview truncation is explicit and collections are deeply snapshot-safe', () {
      final payload = <String, Object?>{'value': 'abcdefghij'};
      final source = <QaEvent>[_network('api', base, '/home', response: payload)];
      final report = build(source, currentRoute: '/home', limits: const QaReportLimits(maxTextPayloadCharacters: 8));
      payload['value'] = 'changed';
      source.clear();
      expect(report.steps.single.apis.single.responseBody, contains('[preview limited]'));
      expect(report.steps.single.apis.single.responseBody, isNot(contains('changed')));
      expect(() => report.steps.add(_step()), throwsUnsupportedError);
      expect(() => report.steps.single.apis.clear(), throwsUnsupportedError);
    });
  });

  group('Phase 7 text rendering', () {
    test('renders all navigation actions and final None', () {
      final data = const QaReportBuilder().build(events: <QaEvent>[
        QaRouteEvent(id: 'a', timestamp: base, action: QaRouteAction.push, fromRoute: null, toRoute: '/a', currentRoute: '/a'),
        QaRouteEvent(id: 'b', timestamp: base, action: QaRouteAction.push, fromRoute: '/a', toRoute: '/b', currentRoute: '/b'),
        QaRouteEvent(id: 'c', timestamp: base, action: QaRouteAction.pop, fromRoute: '/b', toRoute: '/a', currentRoute: '/a'),
        QaRouteEvent(id: 'd', timestamp: base, action: QaRouteAction.replace, fromRoute: '/a', toRoute: '/c', currentRoute: '/c'),
      ], notes: '', currentRoute: '/c', generatedAt: base);
      final text = const QaReportTextRenderer().render(data);
      expect(text, contains('PUSH\n/a -> /b'));
      expect(text, contains('POP\n/b -> /a'));
      expect(text, contains('REPLACE\n/a -> /c'));
      expect(text, contains('NEXT ACTION:\nNone\nUser remained on /c'));
      expect(text, contains('APIs Triggered: None'));
      expect(text, contains('Issue Notes:\nNone'));
    });

    test('renders outcomes, bodies, error metadata, and omission notices', () {
      final data = const QaReportBuilder(limits: QaReportLimits(maxSteps: 1, maxApis: 3)).build(
        events: <QaEvent>[
          _route('one', base, null, '/one'),
          _network('ok', base, '/one', response: const {'safe': 'yes'}),
          _network('bad', base, '/one', outcome: QaNetworkOutcome.failure, response: const {'safe_error': 'yes'}),
          _network('cancel', base, '/one', outcome: QaNetworkOutcome.cancelled),
          _network('omitted', base, '/one'),
          _route('two', base, '/one', '/two'),
        ], notes: '', currentRoute: '/two', generatedAt: base);
      final text = const QaReportTextRenderer().render(data);
      expect(text, contains('"safe": "yes"'));
      expect(text, contains('"safe_error": "yes"'));
      expect(text, contains('Error:\nbadResponse: Safe failure'));
      expect(text, contains('Status: Cancelled'));
      expect(text, contains('Outcome: CANCELLED'));
      expect(text, contains('[1 additional steps omitted]'));
      expect(text, contains('[1 additional APIs omitted]'));
    });

    test('known raw secrets never appear in data or canonical text', () {
      const secrets = <String>['raw-password-secret', 'raw-otp-secret', 'Bearer raw-access-token', 'raw-refresh-token'];
      final data = const QaReportBuilder().build(
        events: <QaEvent>[_network('secure', base, '/secure', request: const {'password': '***', 'otp': '***', 'authorization': '***'}, response: const {'refresh_token': '***'})],
        notes: '', currentRoute: '/secure', generatedAt: base);
      final inspected = '${data.currentRoute}|${data.notes}|${data.steps.expand((step) => step.apis).map((api) => '${api.url}|${api.queryParameters}|${api.requestBody}|${api.responseBody}|${api.errorMessage}').join()}';
      final text = const QaReportTextRenderer().render(data);
      for (final secret in secrets) {
        expect(inspected, isNot(contains(secret)));
        expect(text, isNot(contains(secret)));
      }
      expect(text, contains('***'));
    });
  });

}

QaRouteEvent _route(String id, DateTime time, String? from, String? to, {QaRouteAction action = QaRouteAction.push}) => QaRouteEvent(
  id: id,
  timestamp: time,
  action: action,
  fromRoute: from,
  toRoute: to,
  currentRoute: to,
);

QaNetworkEvent _network(
  String id,
  DateTime started,
  String? route, {
  QaNetworkOutcome outcome = QaNetworkOutcome.success,
  int completedOffset = 1,
  Object? request,
  Object? response,
  bool truncated = false,
}) => QaNetworkEvent(
  id: id,
  timestamp: started,
  method: 'POST',
  url: 'https://example.test/api',
  path: '/$id'.replaceFirst('/failure', '/api'),
  queryParameters: const <String, Object?>{'page': 1},
  requestHeaders: const <String, Object?>{'Authorization': '***'},
  requestBody: QaPayloadCapture(data: request, isTruncated: truncated, originalSize: null, capturedSize: null),
  responseHeaders: null,
  responseBody: QaPayloadCapture(data: response ?? const <String, Object?>{'ok': true}, isTruncated: truncated, originalSize: null, capturedSize: null),
  statusCode: outcome == QaNetworkOutcome.cancelled ? null : (outcome == QaNetworkOutcome.failure ? 500 : 200),
  startedAt: started,
  completedAt: started.add(Duration(seconds: completedOffset)),
  duration: Duration(seconds: completedOffset),
  route: route,
  outcome: outcome,
  error: outcome == QaNetworkOutcome.success ? null : const QaNetworkError(type: 'badResponse', message: 'Safe failure'),
);

QaReportStep _step() => QaReportStep(
  number: 1,
  route: '/x',
  screen: 'x',
  enteredAt: null,
  enteredFrom: null,
  enteredBy: null,
  apis: const <QaReportApi>[],
  nextNavigation: null,
  isFinal: true,
  omittedApis: 0,
);
