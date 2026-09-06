import '../events/qa_event.dart';
import '../events/qa_event_id_generator.dart';
import '../events/qa_event_timeline.dart';
import '../routing/qa_route_context.dart';
import 'qa_inspector_config.dart';

final class QaInspectorRuntime {
  QaInspectorRuntime(this.config)
    : timeline = QaEventTimeline(maxEvents: config.maxEvents),
      eventIdGenerator = QaEventIdGenerator();

  final QaInspectorConfig config;
  final QaEventTimeline timeline;
  final QaRouteContext routeContext = QaRouteContext();
  final QaEventIdGenerator eventIdGenerator;
  bool _isDisposed = false;

  bool get isEnabled => config.enabled;

  String nextEventId() => eventIdGenerator.next();

  void publish(QaEvent event) {
    if (!isEnabled || _isDisposed) {
      return;
    }

    timeline.add(event);
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    timeline.dispose();
  }
}
