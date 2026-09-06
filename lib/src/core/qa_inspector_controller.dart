import 'package:flutter/foundation.dart';

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
  _QaControllerChanges? _changeNotifications;
  bool _isDisposed = false;
  String _notes = '';

  /// Maximum number of characters retained in session notes.
  static const int maxNotesLength = 5000;

  /// A stable, immutable snapshot of captured events.
  List<QaEvent> get events => _runtime.timeline.snapshot();

  /// Read-only notifications for event and session-note changes.
  ///
  /// Consumers should request a fresh [events] snapshot when notified.
  Listenable get changes =>
      _changeNotifications ??= _QaControllerChanges(_runtime);

  /// Notes retained in memory for the current QA session.
  String get notes => _notes;

  /// Replaces the current session notes, bounded by [maxNotesLength].
  void updateNotes(String value) {
    if (!config.enabled || _isDisposed) {
      return;
    }
    final bounded = value.length <= maxNotesLength
        ? value
        : value.substring(0, maxNotesLength);
    if (_notes == bounded) {
      return;
    }
    _notes = bounded;
    _changeNotifications?.notifySessionChanged();
  }

  /// The current lightweight route name, or `null` before one is observed.
  String? get currentRoute => _runtime.routeContext.currentRoute;

  /// Identifies the current in-memory inspection session.
  ///
  /// Collectors use this value to discard work that began before [clearEvents].
  int get sessionGeneration => _runtime.sessionGeneration;

  /// Removes all currently captured events.
  void clearEvents() {
    if (!_isDisposed) {
      _runtime.clearEvents();
    }
  }

  /// Clears captured events and notes and advances the session generation.
  void clearSession() {
    if (!config.enabled || _isDisposed) {
      return;
    }
    _notes = '';
    _runtime.clearEvents();
    _changeNotifications?.notifySessionChanged();
  }

  /// Publishes a collector event if its originating session is still current.
  ///
  /// This is intended for asynchronous SDK collectors. Host applications should
  /// not need to call it directly.
  void recordEvent(QaEvent event, {required int sessionGeneration}) {
    if (!config.enabled ||
        _isDisposed ||
        sessionGeneration != _runtime.sessionGeneration) {
      return;
    }
    _runtime.publish(event);
  }

  /// Creates an identifier in the shared runtime event sequence.
  ///
  /// This is intended for SDK collectors.
  String nextEventId() => _runtime.nextEventId();

  /// Releases runtime resources. Calling this more than once is safe.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _changeNotifications?.dispose();
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

final class _QaControllerChanges extends ChangeNotifier {
  _QaControllerChanges(this._runtime);

  final QaInspectorRuntime _runtime;
  bool _listeningToTimeline = false;
  int _listenerCount = 0;

  @override
  void addListener(VoidCallback listener) {
    if (!_listeningToTimeline) {
      _runtime.timeline.addListener(notifyListeners);
      _listeningToTimeline = true;
    }
    super.addListener(listener);
    _listenerCount++;
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_listenerCount > 0) {
      _listenerCount--;
    }
    if (_listenerCount == 0 && _listeningToTimeline) {
      _runtime.timeline.removeListener(notifyListeners);
      _listeningToTimeline = false;
    }
  }

  void notifySessionChanged() => notifyListeners();

  @override
  void dispose() {
    if (_listeningToTimeline) {
      _runtime.timeline.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
