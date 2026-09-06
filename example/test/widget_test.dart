import 'package:flutter_test/flutter_test.dart';

import 'package:qa_inspector_example/main.dart';

void main() {
  testWidgets('example application starts', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('QA Inspector example application'), findsOneWidget);
  });
}
