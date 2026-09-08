import 'qa_event.dart';

/// The final result of an inspected network request.
enum QaNetworkOutcome {
  /// The request was sent and is waiting for a response.
  pending,

  /// The request completed with a response accepted by Dio.
  success,

  /// The request completed through Dio's error path.
  failure,

  /// The request was cancelled.
  cancelled,
}

/// A bounded, sanitized payload retained by a network event.
final class QaPayloadCapture {
  /// Creates payload capture metadata.
  const QaPayloadCapture({
    required this.data,
    required this.isTruncated,
    required this.originalSize,
    required this.capturedSize,
  });

  /// The safe captured representation.
  final Object? data;

  /// Whether the original safe representation exceeded the capture limit.
  final bool isTruncated;

  /// Approximate UTF-8 size before truncation, when measurable.
  final int? originalSize;

  /// Approximate UTF-8 size retained by [data], when measurable.
  final int? capturedSize;
}

/// Lightweight information about a Dio error.
final class QaNetworkError {
  /// Creates safe error metadata.
  const QaNetworkError({required this.type, required this.message});

  /// Dio's error category.
  final String type;

  /// A non-sensitive description of the category.
  final String message;
}

/// An immutable, sanitized record of one network request lifecycle.
final class QaNetworkEvent extends QaEvent {
  /// Creates a network event at its current lifecycle state.
  const QaNetworkEvent({
    required super.id,
    required super.timestamp,
    required this.method,
    required this.url,
    required this.path,
    required this.queryParameters,
    required this.requestHeaders,
    required this.requestBody,
    required this.responseHeaders,
    required this.responseBody,
    required this.statusCode,
    required this.startedAt,
    this.completedAt,
    this.duration,
    required this.route,
    required this.outcome,
    required this.error,
  }) : super(type: QaEventType.network);

  /// Uppercase HTTP method captured at request start.
  final String method;

  /// Full sanitized request URL.
  final String url;

  /// Request URI path without its query string.
  final String path;

  /// Sanitized query parameter structure.
  final Object? queryParameters;

  /// Sanitized request headers.
  final Object? requestHeaders;

  /// Sanitized, bounded request payload.
  final QaPayloadCapture requestBody;

  /// Sanitized response headers, when a response was received.
  final Object? responseHeaders;

  /// Sanitized, bounded response payload.
  final QaPayloadCapture responseBody;

  /// HTTP response status, when a response was received.
  final int? statusCode;

  /// Time at which Dio began processing the request.
  final DateTime startedAt;

  /// Time at which Dio completed, or `null` while pending.
  final DateTime? completedAt;

  /// Elapsed time between [startedAt] and [completedAt], when complete.
  final Duration? duration;

  /// Lightweight route name captured at request start.
  final String? route;

  /// Current request outcome.
  final QaNetworkOutcome outcome;

  /// Safe error metadata for failed or cancelled requests.
  final QaNetworkError? error;
}
