import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  test('uses safe defaults', () {
    const config = QaInspectorConfig();

    expect(config.enabled, isFalse);
    expect(config.maxEvents, QaInspectorConfig.defaultMaxEvents);
  });

  test('accepts enabled and maxEvents values', () {
    const config = QaInspectorConfig(enabled: true, maxEvents: 50);

    expect(config.enabled, isTrue);
    expect(config.maxEvents, 50);
  });
}
