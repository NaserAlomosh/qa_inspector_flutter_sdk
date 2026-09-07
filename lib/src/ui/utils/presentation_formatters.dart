import 'dart:convert';

import '../../events/qa_network_event.dart';

/// Returns the display fallback for an unnamed [route].
String formatRoute(String? route) =>
    route == null || route.trim().isEmpty ? '<unnamed>' : route;

/// Formats [value] as a time including milliseconds.
String formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:'
    '${value.second.toString().padLeft(2, '0')}.${value.millisecond.toString().padLeft(3, '0')}';

/// Formats an already-sanitized value for display.
String prettyValue(Object? value) {
  if (value == null) return '—';
  try {
    final formatted = const JsonEncoder.withIndent('  ').convert(value);
    const renderLimit = 50000;
    return formatted.length <= renderLimit
        ? formatted
        : '${formatted.substring(0, renderLimit)}\n[display truncated]';
  } catch (_) {
    final fallback = value.toString();
    return fallback.length <= 50000
        ? fallback
        : '${fallback.substring(0, 50000)}\n[display truncated]';
  }
}

/// Formats payload truncation metadata when present.
String formatTruncation(QaPayloadCapture payload) => payload.isTruncated
    ? '\n[Payload truncated: ${payload.capturedSize ?? 0}/${payload.originalSize ?? 0} bytes retained]'
    : '';

/// Formats all already-sanitized fields of [event] for copying.
String formatFullApiDetails(
  QaNetworkEvent event, {
  required String request,
  required String response,
}) =>
    '${event.method} ${event.url}\nRoute: ${formatRoute(event.route)}\nStatus: ${event.statusCode ?? '—'}\n'
    'Outcome: ${event.outcome.name}\nDuration: ${event.duration.inMilliseconds} ms\n'
    'Request headers:\n${prettyValue(event.requestHeaders)}\nRequest query:\n${prettyValue(event.queryParameters)}\n'
    'Request body:\n$request${formatTruncation(event.requestBody)}\nResponse headers:\n${prettyValue(event.responseHeaders)}\n'
    'Response body:\n$response${formatTruncation(event.responseBody)}\nError: '
    '${event.error == null ? 'none' : '${event.error!.type}: ${event.error!.message}'}';
