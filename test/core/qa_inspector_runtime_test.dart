import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/src/core/qa_inspector_runtime.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  test('uses the configured default maxEvents', () {
    final runtime = QaInspectorRuntime(
      const QaInspectorConfig(enabled: true),
    );

    expect(runtime.timeline.maxEvents, QaInspectorConfig.defaultMaxEvents);
  });

  test('generates unique event IDs across runtimes', () {
    final firstRuntime = QaInspectorRuntime(const QaInspectorConfig());
    final secondRuntime = QaInspectorRuntime(const QaInspectorConfig());

    final ids = <String>{
      for (var index = 0; index < 1000; index++)
        index.isEven
            ? firstRuntime.nextEventId()
            : secondRuntime.nextEventId(),
    };

    expect(ids, hasLength(1000));
  });

  test('publishes events when enabled', () {
    final runtime = QaInspectorRuntime(
      const QaInspectorConfig(enabled: true, maxEvents: 2),
    );
    final event = RuntimeTestEvent(
      id: runtime.nextEventId(),
      timestamp: DateTime.utc(2026),
    );

    runtime.publish(event);

    expect(runtime.timeline.events, <QaEvent>[event]);
  });

  test('does not retain or notify for events when disabled', () {
    final runtime = QaInspectorRuntime(
      const QaInspectorConfig(enabled: false),
    );
    var notifications = 0;
    runtime.timeline.addListener(() => notifications++);

    runtime.publish(
      RuntimeTestEvent(
        id: runtime.nextEventId(),
        timestamp: DateTime.utc(2026),
      ),
    );

    expect(runtime.isEnabled, isFalse);
    expect(runtime.timeline.events, isEmpty);
    expect(notifications, 0);
  });
}

final class RuntimeTestEvent extends QaEvent {
  const RuntimeTestEvent({required String id, required DateTime timestamp})
    : super(id: id, timestamp: timestamp, type: QaEventType.sdk);
}
