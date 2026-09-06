import '../events/qa_event.dart';
import '../events/qa_route_event.dart';
import 'qa_inspector_config.dart';
import 'qa_inspector_runtime.dart';

/// The shared integration handle for QA Inspector collectors.
///
/// The object that creates this controller owns it and must call [dispose].
/// Widgets and collectors receiving a controller never dispose it.
final class QaInspectorController {
  /// Creates one in-memory QA Inspector runtime.
  QaInspectorController({this.config = const QaInspectorConfig()})
    : _runtime = QaInspectorRuntime(config);

  /// Immutable configuration for this runtime.
  final QaInspectorConfig config;

  final QaInspectorRuntime _runtime;
  bool _isDisposed = false;

  /// A stable, immutable snapshot of captured events.
  List<QaEvent> get events => _runtime.timeline.snapshot();

  /// The current lightweight route name, or `null` before one is observed.
  String? get currentRoute => _runtime.routeContext.currentRoute;

  /// Removes all currently captured events.
  void clearEvents() {
    if (!_isDisposed) {
      _runtime.timeline.clear();
    }
  }

  /// Releases runtime resources. Calling this more than once is safe.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _runtime.dispose();
  }

  /// Records a route transition for SDK routing integrations.
  void recordRoute({
    required QaRouteAction action,
    required String? fromRoute,
    required String? toRoute,
    required String? currentRoute,
  }) {
    if (!config.enabled || _isDisposed) {
      return;
    }

    _runtime.routeContext.update(currentRoute);
    _runtime.publish(
      QaRouteEvent(
        id: _runtime.nextEventId(),
        timestamp: DateTime.now(),
        action: action,
        fromRoute: fromRoute,
        toRoute: toRoute,
        currentRoute: currentRoute,
      ),
    );
  }
}
