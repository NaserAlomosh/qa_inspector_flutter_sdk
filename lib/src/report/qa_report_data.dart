import '../events/qa_network_event.dart';
import '../events/qa_route_event.dart';

/// Optional metadata supplied by an SDK consumer for a QA report.
final class QaReportMetadata {
  /// Creates report metadata without collecting device information.
  const QaReportMetadata({
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.osVersion,
    this.deviceModel,
  });

  /// Host-provided application version.
  final String? appVersion;

  /// Host-provided application build number.
  final String? buildNumber;

  /// Host-provided platform label.
  final String? platform;

  /// Host-provided operating-system version.
  final String? osVersion;

  /// Host-provided device model.
  final String? deviceModel;
}

/// A navigation transition displayed after a report step.
final class QaReportNavigation {
  /// Creates a captured transition between visible visits.
  const QaReportNavigation({
    required this.action,
    required this.fromRoute,
    required this.toRoute,
  });

  /// Navigation operation.
  final QaRouteAction action;

  /// Route left by the transition.
  final String fromRoute;

  /// Route entered by the transition.
  final String toRoute;
}

/// An immutable, presentation-ready sanitized API record.
final class QaReportApi {
  /// Creates a presentation-ready API record.
  const QaReportApi({
    required this.method,
    required this.url,
    required this.path,
    required this.route,
    required this.startedAt,
    required this.completedAt,
    required this.duration,
    required this.statusCode,
    required this.outcome,
    required this.queryParameters,
    required this.requestBody,
    required this.responseBody,
    required this.requestTruncated,
    required this.responseTruncated,
    required this.errorType,
    required this.errorMessage,
  });

  /// HTTP method.
  final String method;

  /// Sanitized full URL.
  final String url;

  /// Sanitized request path.
  final String path;

  /// Route captured when the request started.
  final String route;

  /// Request start time.
  final DateTime startedAt;

  /// Request completion time.
  final DateTime? completedAt;

  /// Request duration.
  final Duration? duration;

  /// HTTP status when available.
  final int? statusCode;

  /// Final network outcome.
  final QaNetworkOutcome outcome;

  /// Deterministically formatted sanitized query.
  final String queryParameters;

  /// Deterministically formatted sanitized request body.
  final String requestBody;

  /// Deterministically formatted sanitized response body.
  final String responseBody;

  /// Whether network capture truncated the request.
  final bool requestTruncated;

  /// Whether network capture truncated the response.
  final bool responseTruncated;

  /// Safe network error category.
  final String? errorType;

  /// Safe network error message.
  final String? errorMessage;

  /// Whether this API represents a backend/network failure.
  bool get isFailure => outcome == QaNetworkOutcome.failure;
}

/// One chronological visible-screen visit and its originating APIs.
final class QaReportStep {
  /// Creates one immutable visible-screen visit.
  QaReportStep({
    required this.number,
    required this.route,
    required this.screen,
    required this.enteredAt,
    required this.enteredFrom,
    required this.enteredBy,
    required List<QaReportApi> apis,
    required this.nextNavigation,
    required this.isFinal,
    required this.omittedApis,
  }) : apis = List<QaReportApi>.unmodifiable(apis);

  /// One-based step number.
  final int number;

  /// Route captured when the request started.
  final String route;

  /// Human-readable screen label.
  final String screen;

  /// Time this visit became active, when observed.
  final DateTime? enteredAt;

  /// Previous route, when known.
  final String? enteredFrom;

  /// Action that entered this visit; null denotes initial.
  final QaRouteAction? enteredBy;

  /// APIs that originated during this visit.
  final List<QaReportApi> apis;

  /// Transition that followed this visit.
  final QaReportNavigation? nextNavigation;

  /// Whether no later captured visit exists.
  final bool isFinal;

  /// APIs omitted from this step by safety limits.
  final int omittedApis;
}

/// A stable report snapshot shared by text and image renderers.
final class QaReportData {
  /// Creates a stable immutable report snapshot.
  QaReportData({
    required this.generatedAt,
    required this.currentRoute,
    required this.notes,
    required List<QaReportStep> steps,
    required this.totalScreens,
    required this.totalApis,
    required this.failedApis,
    required this.omittedSteps,
    required this.omittedApis,
    this.metadata,
  }) : steps = List<QaReportStep>.unmodifiable(steps);

  /// Time captured at report generation start.
  final DateTime generatedAt;

  /// Final route captured at report generation start.
  final String currentRoute;

  /// Session issue notes.
  final String notes;

  /// Bounded chronological screen visits.
  final List<QaReportStep> steps;

  /// Total visits before report limits.
  final int totalScreens;

  /// Total APIs before report limits.
  final int totalApis;

  /// Failed APIs before report limits.
  final int failedApis;

  /// Visits omitted by report limits.
  final int omittedSteps;

  /// APIs omitted from this step by safety limits.
  final int omittedApis;

  /// Optional host-provided metadata.
  final QaReportMetadata? metadata;
}
