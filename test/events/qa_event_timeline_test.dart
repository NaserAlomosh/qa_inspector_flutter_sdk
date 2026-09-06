import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/src/events/qa_event_timeline.dart';
import 'package:qa_inspector/qa_inspector.dart';

void main() {
  group('QaEvent', () {
    test('retains its immutable core values', () {
      final timestamp = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final event = TestEvent(
        id: 'event-1',
        timestamp: timestamp,
        type: QaEventType.log,
      );

      expect(event.id, 'event-1');
      expect(event.timestamp, same(timestamp));
      expect(event.type, QaEventType.log);
    });
  });

  group('QaEventTimeline', () {
    test('adds events and preserves insertion order', () {
      final timeline = QaEventTimeline(maxEvents: 3);
      final timestamp = DateTime.utc(2026);
      final first = TestEvent(id: '1', timestamp: timestamp);
      final second = TestEvent(id: '2', timestamp: timestamp);
      final third = TestEvent(
        id: '3',
        timestamp: timestamp.subtract(const Duration(days: 1)),
      );

      timeline
        ..add(first)
        ..add(second)
        ..add(third);

      expect(timeline.events, <QaEvent>[first, second, third]);
    });

    test('evicts the oldest event when maxEvents is reached', () {
      final timeline = QaEventTimeline(maxEvents: 3);
      final events = List<TestEvent>.generate(4, eventWithIndex);

      for (final event in events) {
        timeline.add(event);
      }

      expect(timeline.events, events.skip(1));
      expect(timeline.events.length, 3);
    });

    test('supports a custom single-event limit', () {
      final timeline = QaEventTimeline(maxEvents: 1)
        ..add(eventWithIndex(0))
        ..add(eventWithIndex(1));

      expect(timeline.events.single.id, '1');
    });

    test('returns a stable immutable snapshot', () {
      final timeline = QaEventTimeline(maxEvents: 3)
        ..add(eventWithIndex(0));
      final snapshot = timeline.snapshot();

      timeline.add(eventWithIndex(1));

      expect(snapshot.map((event) => event.id), <String>['0']);
      expect(
        () => snapshot.add(eventWithIndex(2)),
        throwsUnsupportedError,
      );
    });

    test('does not expose its mutable collection through events', () {
      final timeline = QaEventTimeline(maxEvents: 3)
        ..add(eventWithIndex(0));

      expect(
        () => timeline.events.clear(),
        throwsUnsupportedError,
      );
      expect(timeline.events, hasLength(1));
    });

    test('clear removes events and collection continues afterward', () {
      final timeline = QaEventTimeline(maxEvents: 3)
        ..add(eventWithIndex(0))
        ..clear()
        ..add(eventWithIndex(1));

      expect(timeline.events.map((event) => event.id), <String>['1']);
    });

    test('notifies once for each addition and non-empty clear', () {
      final timeline = QaEventTimeline(maxEvents: 3);
      var notifications = 0;
      timeline.addListener(() => notifications++);

      timeline
        ..add(eventWithIndex(0))
        ..add(eventWithIndex(1))
        ..clear()
        ..clear();

      expect(notifications, 3);
    });

    test('retains only the newest rapid additions', () {
      final timeline = QaEventTimeline(maxEvents: 10);

      for (var index = 0; index < 1000; index++) {
        timeline.add(eventWithIndex(index));
      }

      expect(timeline.events, hasLength(10));
      expect(
        timeline.events.map((event) => event.id),
        List<String>.generate(10, (index) => '${index + 990}'),
      );
    });
  });
}

TestEvent eventWithIndex(int index) => TestEvent(
  id: '$index',
  timestamp: DateTime.utc(2026).add(Duration(microseconds: index)),
);

final class TestEvent extends QaEvent {
  const TestEvent({
    required super.id,
    required super.timestamp,
    super.type = QaEventType.sdk,
  });
}
