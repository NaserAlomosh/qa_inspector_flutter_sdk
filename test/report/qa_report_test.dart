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
