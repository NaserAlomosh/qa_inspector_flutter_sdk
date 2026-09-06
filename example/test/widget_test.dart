import 'package:flutter_test/flutter_test.dart';

import 'package:qa_inspector_example/main.dart';

void main() {
  testWidgets('navigates to the details screen', (tester) async {
    await tester.pumpWidget(const ExampleBootstrap());

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('Observed route'), findsOneWidget);
  });
}
