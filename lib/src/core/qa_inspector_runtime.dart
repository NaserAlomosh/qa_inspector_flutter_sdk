import '../events/qa_event.dart';
import '../events/qa_event_id_generator.dart';
import '../events/qa_event_timeline.dart';
import 'qa_inspector_config.dart';

final class QaInspectorRuntime {
  QaInspectorRuntime(this.config)
    : timeline = QaEventTimeline(maxEvents: config.maxEvents);

  final QaInspectorConfig config;
  final QaEventTimeline timeline;

  bool get isEnabled => config.enabled;

  String nextEventId() => QaEventIdGenerator.next();

  void publish(QaEvent event) {
    if (!isEnabled) {
      return;
    }

    timeline.add(event);
  }

  void dispose() {
    timeline.dispose();
  }
}
