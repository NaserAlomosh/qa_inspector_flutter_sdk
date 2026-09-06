import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';
import 'package:qa_inspector/src/ui/report/qa_report_widget.dart';

void main() {
  testWidgets('exports repeatable non-empty PNG bytes and filename', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold(body: Text('Host'));
          },
        ),
      ),
    );
    final data = QaReportData(
      generatedAt: DateTime.utc(2026, 9, 6, 19, 30, 22),
      currentRoute: '/home',
      notes: 'Visible note',
      steps: <QaReportStep>[
        QaReportStep(
          number: 1,
          route: '/home',
          screen: 'home',
          enteredAt: DateTime.utc(2026, 9, 6),
          enteredFrom: null,
          enteredBy: null,
          apis: const <QaReportApi>[],
          nextNavigation: null,
          isFinal: true,
          omittedApis: 0,
        ),
      ],
      totalScreens: 1,
      totalApis: 0,
      failedApis: 0,
      omittedSteps: 0,
      omittedApis: 0,
    );
    const exporter = QaReportImageExporter(
      limits: QaReportLimits(maxImageWidth: 600, maxImageHeight: 3000, pixelRatio: 1),
    );

    final firstFuture = exporter.export(context, data);
    await tester.pump();
    await tester.pump();
    final first = await firstFuture;
    expect(first.isSuccess, isTrue, reason: first.errorMessage);
    expect(first.filename, 'qa_report_20260906_193022.png');
    expect(first.bytes, isNotEmpty);
    expect(first.bytes!.take(8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);

    final secondFuture = exporter.export(context, data);
    await tester.pump();
    await tester.pump();
    expect((await secondFuture).isSuccess, isTrue);
  });

  testWidgets('PNG-facing widget receives only masked secret values', (tester) async {
    const secrets = <String>[
      'raw-password-secret',
      'raw-otp-secret',
      'Bearer raw-access-token',
      'raw-refresh-token',
    ];
    final report = _data(
      steps: <QaReportStep>[
        _step(1, '/secure', <QaReportApi>[_api('/secure', QaNetworkOutcome.success)]),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(child: QaReportWidget(data: report)),
      ),
    );

    expect(find.textContaining('***'), findsWidgets);
    for (final secret in secrets) {
      expect(find.textContaining(secret), findsNothing);
    }
  });

  testWidgets('unsafe report height returns a controlled failure', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final data = QaReportData(
      generatedAt: DateTime.utc(2026),
      currentRoute: '/home',
      notes: 'A report note',
      steps: const <QaReportStep>[],
      totalScreens: 0,
      totalApis: 0,
      failedApis: 0,
      omittedSteps: 0,
      omittedApis: 0,
    );
    const exporter = QaReportImageExporter(
      limits: QaReportLimits(maxImageWidth: 600, maxImageHeight: 1, pixelRatio: 1),
    );
    final future = exporter.export(context, data);
    await tester.pump();
    await tester.pump();
    final result = await future;
    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('too large'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('report document remains outside the active viewport while rendering', (tester) async {
    late BuildContext context;
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return Scaffold(body: GestureDetector(onTap: () => taps++, child: const SizedBox.expand(key: Key('interactive-host'))));
    })));
    final future = const QaReportImageExporter(
      limits: QaReportLimits(maxImageWidth: 600, maxImageHeight: 3000, pixelRatio: 1),
    ).export(context, _data());

    await tester.pump();
    final reportTitle = find.text('QA REPORT');
    expect(reportTitle, findsOneWidget);
    expect(tester.getTopLeft(reportTitle).dx, greaterThan(tester.view.physicalSize.width / tester.view.devicePixelRatio));
    await tester.tap(find.byKey(const Key('interactive-host')));
    expect(taps, 1);
    await tester.pump();
    expect((await future).isSuccess, isTrue);
  });

  testWidgets('exports representative multi-step, failed, cancelled, notes, and truncated reports', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const Scaffold(body: Text('Host'));
    })));
    final report = _data(
      notes: 'Important reproduction notes',
      steps: <QaReportStep>[
        _step(1, '/start', <QaReportApi>[
          _api('/success', QaNetworkOutcome.success),
          _api('/failure', QaNetworkOutcome.failure),
          _api('/cancel', QaNetworkOutcome.cancelled, truncated: true),
        ]),
        _step(2, '/empty', const <QaReportApi>[]),
      ],
    );
    final future = const QaReportImageExporter(
      limits: QaReportLimits(maxImageWidth: 600, maxImageHeight: 5000, pixelRatio: 1),
    ).export(context, report);
    await tester.pump();
    await tester.pump();
    final result = await future;
    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(result.bytes!.take(8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  });

  testWidgets('a tall report below the configured maximum succeeds', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final report = _data(steps: List<QaReportStep>.generate(8, (index) => _step(index + 1, '/step-$index', const <QaReportApi>[])));
    final future = const QaReportImageExporter(
      limits: QaReportLimits(maxImageWidth: 600, maxImageHeight: 8000, pixelRatio: 1),
    ).export(context, report);
    await tester.pump();
    await tester.pump();
    expect((await future).isSuccess, isTrue);
  });

  testWidgets('unsafe pixel ratios and missing overlays fail without host exceptions', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (value) {
      context = value;
      return const Directionality(textDirection: TextDirection.ltr, child: Text('Host'));
    }));
    for (final ratio in <double>[0, -1, 3.1]) {
      final result = await QaReportImageExporter(limits: QaReportLimits(pixelRatio: ratio)).export(context, _data());
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('unsafe'));
    }
    final result = await const QaReportImageExporter().export(context, _data());
    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('unavailable'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('export consumes a stable snapshot after source mutation', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final sourceSteps = <QaReportStep>[_step(1, '/original', const <QaReportApi>[])];
    final report = _data(steps: sourceSteps);
    final future = const QaReportImageExporter(
      limits: QaReportLimits(maxImageWidth: 600, maxImageHeight: 3000, pixelRatio: 1),
    ).export(context, report);
    sourceSteps.clear();
    await tester.pump();
    expect(find.text('Route: /original'), findsOneWidget);
    await tester.pump();
    expect((await future).isSuccess, isTrue);
  });

}


QaReportData _data({String notes = '', List<QaReportStep>? steps}) => QaReportData(
  generatedAt: DateTime.utc(2026, 9, 6, 19, 30, 22),
  currentRoute: steps == null || steps.isEmpty ? '/home' : steps.last.route,
  notes: notes,
  steps: steps ?? <QaReportStep>[_step(1, '/home', const <QaReportApi>[])],
  totalScreens: steps?.length ?? 1,
  totalApis: steps?.fold<int>(0, (total, step) => total + step.apis.length) ?? 0,
  failedApis: steps?.expand((step) => step.apis).where((api) => api.isFailure).length ?? 0,
  omittedSteps: 0,
  omittedApis: 0,
);

QaReportStep _step(int number, String route, List<QaReportApi> apis) => QaReportStep(
  number: number,
  route: route,
  screen: route,
  enteredAt: DateTime.utc(2026),
  enteredFrom: number == 1 ? null : '/previous',
  enteredBy: number == 1 ? null : QaRouteAction.push,
  apis: apis,
  nextNavigation: null,
  isFinal: true,
  omittedApis: 0,
);

QaReportApi _api(String path, QaNetworkOutcome outcome, {bool truncated = false}) => QaReportApi(
  method: 'POST',
  url: 'https://example.test$path',
  path: path,
  route: '/start',
  startedAt: DateTime.utc(2026),
  completedAt: DateTime.utc(2026).add(const Duration(milliseconds: 10)),
  duration: const Duration(milliseconds: 10),
  statusCode: outcome == QaNetworkOutcome.success ? 200 : outcome == QaNetworkOutcome.failure ? 500 : null,
  outcome: outcome,
  queryParameters: 'None',
  requestBody: truncated ? 'preview\n[preview limited]' : '{"password":"***"}',
  responseBody: '{"result":"safe"}',
  requestTruncated: truncated,
  responseTruncated: truncated,
  errorType: outcome == QaNetworkOutcome.failure ? 'badResponse' : null,
  errorMessage: outcome == QaNetworkOutcome.failure ? 'Safe failure' : null,
);
