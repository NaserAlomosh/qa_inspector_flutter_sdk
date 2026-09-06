import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

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
}
