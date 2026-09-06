import 'qa_event.dart';

/// The navigation operation represented by a [QaRouteEvent].
enum QaRouteAction {
  /// A route was pushed onto the navigator.
  push,

  /// A route was popped from the navigator.
  pop,

  /// An existing route was replaced.
  replace,

  /// A route was removed from the navigator stack.
  remove,
}

/// An immutable navigation event captured by QA Inspector.
final class QaRouteEvent extends QaEvent {
  /// Creates a route event containing lightweight route names only.
  const QaRouteEvent({
    required super.id,
    required super.timestamp,
    required this.action,
    required this.fromRoute,
    required this.toRoute,
    required this.currentRoute,
  }) : super(type: QaEventType.route);

  /// The navigation operation that occurred.
  final QaRouteAction action;

  /// The route affected or left by the operation.
  final String? fromRoute;

  /// The destination or adjacent route for the operation.
  final String? toRoute;

  /// The visible route after the operation.
  final String? currentRoute;
}
