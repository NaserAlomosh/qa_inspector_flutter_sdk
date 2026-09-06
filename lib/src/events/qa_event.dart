/// Categories of events retained by QA Inspector.
enum QaEventType {
  /// A navigation event.
  route,

  /// A network request event.
  network,

  /// An application log event.
  log,

  /// An event produced by QA Inspector itself.
  sdk,
}

/// Immutable base class for events captured by QA Inspector.
abstract class QaEvent {
  /// Creates an event.
  const QaEvent({
    required this.id,
    required this.timestamp,
    required this.type,
  });

  /// The identifier unique to the current SDK runtime.
  final String id;

  /// The time at which the event occurred.
  final DateTime timestamp;

  /// The event category.
  final QaEventType type;
}
