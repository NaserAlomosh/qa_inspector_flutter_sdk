import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/qa_inspector_controller.dart';
import '../events/qa_network_event.dart';
import '../security/qa_data_sanitization_config.dart';
import '../security/qa_data_sanitizer.dart';

/// Observes Dio traffic and publishes sanitized events to a shared controller.
///
/// Multiple instances can share one controller. If more than one QA interceptor
/// is installed on the same request, the first instance captures it and the
/// remaining instances pass it through without producing duplicate events.
final class QaNetworkInterceptor extends Interceptor {
  /// Creates a network interceptor.
  QaNetworkInterceptor({
    required this.controller,
    QaDataSanitizationConfig? sanitizationConfig,
    this.requestBodyLimit = defaultPayloadLimit,
    this.responseBodyLimit = defaultPayloadLimit,
  }) : assert(requestBodyLimit >= 0),
       assert(responseBodyLimit >= 0),
       _sanitizer = QaDataSanitizer(config: sanitizationConfig);

  /// Default request and response capture limit (50 KiB).
  static const int defaultPayloadLimit = 50 * 1024;

  static const String _contextKey = 'qa_inspector.request_context';

  /// Controller shared with routing and other SDK collectors.
  final QaInspectorController controller;

  /// Maximum approximate UTF-8 bytes retained for a request body.
  final int requestBodyLimit;

  /// Maximum approximate UTF-8 bytes retained for a response body.
  final int responseBodyLimit;
  final QaDataSanitizer _sanitizer;
  final Object _owner = Object();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!controller.config.enabled) {
      handler.next(options);
      return;
    }

    try {
      if (!options.extra.containsKey(_contextKey)) {
        final startedAt = DateTime.now();
        options.extra[_contextKey] = _RequestContext(
          owner: _owner,
          generation: controller.sessionGeneration,
          startedAt: startedAt,
          route: controller.currentRoute,
          method: options.method,
          url: _sanitizer.sanitizeUrl(options.uri.toString()),
          path: options.uri.path,
          queryParameters: _freeze(
            _sanitizer.sanitizeQueryParameters(options.queryParameters),
          ),
          requestHeaders: _freeze(_sanitizer.sanitizeHeaders(options.headers)),
          requestBody: _captureRequestBody(options.data),
        );
      }
    } catch (_) {
      // Network inspection is observational and must not affect the request.
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!controller.config.enabled) {
      handler.next(response);
      return;
    }
    try {
      _publish(
        response.requestOptions,
        response: response,
        outcome: QaNetworkOutcome.success,
      );
    } catch (_) {
      // Network inspection is observational and must not affect the response.
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!controller.config.enabled) {
      handler.next(err);
      return;
    }
    try {
      final cancelled = err.type == DioExceptionType.cancel;
      _publish(
        err.requestOptions,
        response: err.response,
        outcome: cancelled
            ? QaNetworkOutcome.cancelled
            : QaNetworkOutcome.failure,
        error: QaNetworkError(
          type: err.type.name,
          message: cancelled ? 'Request cancelled' : 'Dio request failed',
        ),
      );
    } catch (_) {
      // Preserve the exact DioException and its original error flow.
    }
    handler.next(err);
  }

  QaPayloadCapture _captureRequestBody(Object? body) {
    if (body is FormData) {
      return _capture(_sanitizeFormData(body), requestBodyLimit);
    }
    return _capture(_sanitizeBody(body), requestBodyLimit);
  }

  QaPayloadCapture _captureResponseBody(Object? body) =>
      _capture(_sanitizeBody(body), responseBodyLimit);

  Object? _sanitizeBody(Object? body) {
    final safeBody = _safeBody(body);
    if (safeBody is String) {
      final trimmed = safeBody.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return _sanitizer.sanitizeBody(jsonDecode(safeBody));
        } catch (_) {
          return safeBody;
        }
      }
    }
    return _sanitizer.sanitizeBody(safeBody);
  }

  Object? _safeBody(Object? body) {
    if (body is ByteBuffer || body is TypedData || body is Stream) {
      return QaDataSanitizer.binaryContent;
    }
    return body;
  }

  Object _sanitizeFormData(FormData formData) {
    final fields = <String, Object?>{};
    for (final entry in formData.fields) {
      final existing = fields[entry.key];
      fields[entry.key] = existing == null
          ? entry.value
          : existing is List<Object?>
          ? <Object?>[...existing, entry.value]
          : <Object?>[existing, entry.value];
    }
    final files = <Object?>[
      for (final entry in formData.files) _sanitizeFile(entry),
    ];
    return _sanitizer.sanitizeBody(<String, Object?>{
      'fields': fields,
      'files': files,
    })!;
  }

  Object? _sanitizeFile(MapEntry<String, MultipartFile> entry) {
    final metadata = <String, Object?>{
      'fieldName': entry.key,
      'filename': entry.value.filename,
      'contentType': entry.value.contentType?.toString(),
      'length': entry.value.length,
      'content': QaDataSanitizer.binaryContent,
    };
    final keyed =
        _sanitizer.sanitizeBody(<String, Object?>{entry.key: metadata})
            as Map<Object?, Object?>;
    final sanitized = keyed[entry.key];
    return sanitized == QaDataSanitizer.mask
        ? <String, Object?>{
            'fieldName': entry.key,
            'metadata': QaDataSanitizer.mask,
          }
        : sanitized;
  }

  QaPayloadCapture _capture(Object? safeData, int limit) {
    final size = _encodedSize(safeData);
    if (size == null) {
      return QaPayloadCapture(
        data: _freeze(safeData),
        isTruncated: false,
        originalSize: null,
        capturedSize: null,
      );
    }
    if (size <= limit) {
      return QaPayloadCapture(
        data: _freeze(safeData),
        isTruncated: false,
        originalSize: size,
        capturedSize: size,
      );
    }
    const omitted = '[content omitted: payload limit exceeded]';
    final capturedSize = utf8.encode(omitted).length;
    return QaPayloadCapture(
      data: omitted,
      isTruncated: true,
      originalSize: size,
      capturedSize: capturedSize,
    );
  }

  int? _encodedSize(Object? value) {
    try {
      return utf8.encode(jsonEncode(value)).length;
    } catch (_) {
      return null;
    }
  }

  void _publish(
    RequestOptions options, {
    required Response<dynamic>? response,
    required QaNetworkOutcome outcome,
    QaNetworkError? error,
  }) {
    final context = options.extra[_contextKey];
    if (context is! _RequestContext || !identical(context.owner, _owner)) {
      return;
    }
    options.extra.remove(_contextKey);
    if (context.generation != controller.sessionGeneration) {
      return;
    }
    final completedAt = DateTime.now();
    final event = QaNetworkEvent(
      id: controller.nextEventId(),
      timestamp: context.startedAt,
      method: context.method,
      url: context.url,
      path: context.path,
      queryParameters: context.queryParameters,
      requestHeaders: context.requestHeaders,
      requestBody: context.requestBody,
      responseHeaders: _freeze(
        _sanitizer.sanitizeHeaders(response?.headers.map),
      ),
      responseBody: _captureResponseBody(response?.data),
      statusCode: response?.statusCode,
      startedAt: context.startedAt,
      completedAt: completedAt,
      duration: completedAt.difference(context.startedAt),
      route: context.route,
      outcome: outcome,
      error: error,
    );
    controller.recordEvent(event, sessionGeneration: context.generation);
  }
}

final class _RequestContext {
  const _RequestContext({
    required this.owner,
    required this.generation,
    required this.startedAt,
    required this.route,
    required this.method,
    required this.url,
    required this.path,
    required this.queryParameters,
    required this.requestHeaders,
    required this.requestBody,
  });

  final Object owner;
  final int generation;
  final DateTime startedAt;
  final String? route;
  final String method;
  final String url;
  final String path;
  final Object? queryParameters;
  final Object? requestHeaders;
  final QaPayloadCapture requestBody;
}

Object? _freeze(Object? value) {
  if (value is Map) {
    return UnmodifiableMapView<Object?, Object?>(<Object?, Object?>{
      for (final entry in value.entries) entry.key: _freeze(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freeze));
  }
  return value;
}
