import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  testWidgets('keeps the host child unchanged while disabled', (tester) async {
    const hostKey = Key('host');

    await tester.pumpWidget(
      const QaInspector(
        config: QaInspectorConfig(enabled: false),
        child: SizedBox(key: hostKey),
      ),
    );

    expect(find.byKey(hostKey), findsOneWidget);
  });

  testWidgets('keeps the host child unchanged while enabled', (tester) async {
    const hostKey = Key('host');

    await tester.pumpWidget(
      const QaInspector(
        config: QaInspectorConfig(enabled: true),
        child: SizedBox(key: hostKey),
      ),
    );

    expect(find.byKey(hostKey), findsOneWidget);
  });
}
