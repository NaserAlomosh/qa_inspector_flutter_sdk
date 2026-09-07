import 'dart:collection';
import 'dart:typed_data';

import 'qa_data_sanitization_config.dart';

/// Creates sanitized copies of structured diagnostic data.
final class QaDataSanitizer {
  /// Creates a sanitizer using the SDK defaults and optional custom rules.
  QaDataSanitizer({QaDataSanitizationConfig? config})
    : _sensitiveKeys = _effectiveNames(
        custom: config?.sensitiveKeys ?? const <String>{},
        defaults: _defaultSensitiveKeys,
        includeDefaults: config?.includeDefaultSensitiveKeys ?? true,
      ),
      _sensitiveHeaders = _effectiveNames(
        custom: config?.sensitiveHeaders ?? const <String>{},
        defaults: _defaultSensitiveHeaders,
        includeDefaults: config?.includeDefaultSensitiveHeaders ?? true,
      );

  /// Replacement used for values belonging to sensitive names.
  static const String mask = '***';

  /// Safe representation used when sanitization fails.
  static const String sanitizationFailed =
      '[content omitted: sanitization failed]';

  /// Safe representation used for unsupported content.
  static const String unsupportedContent =
      '[content omitted: unsupported type]';

  /// Safe representation used for binary content.
  static const String binaryContent = '[binary content omitted]';

  /// Safe representation used when a circular reference is encountered.
  static const String circularReference =
      '[content omitted: circular reference]';

  /// Safe representation used when structured data is excessively deep.
  static const String recursionLimit =
      '[content omitted: recursion limit exceeded]';

  static const int _maximumDepth = 64;

  static const Set<String> _defaultSensitiveKeys = <String>{
    'password',
    'passcode',
    'pin',
    'otp',
    'token',
    'accessToken',
    'access_token',
    'refreshToken',
    'refresh_token',
    'idToken',
    'id_token',
    'secret',
    'clientSecret',
    'client_secret',
    'sessionId',
    'session_id',
  };

  static const Set<String> _defaultSensitiveHeaders = <String>{
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'api-key',
  };

  final Set<String> _sensitiveKeys;
  final Set<String> _sensitiveHeaders;

  /// Returns a sanitized copy of a request or response body.
  Object? sanitizeBody(Object? body) => _sanitizeSafely(body, _sensitiveKeys);

  /// Returns a sanitized copy of structured query parameters.
  Object? sanitizeQueryParameters(Object? queryParameters) =>
      _sanitizeSafely(queryParameters, _sensitiveKeys);

  /// Returns a sanitized copy of headers while preserving header names.
  Object? sanitizeHeaders(Object? headers) =>
      _sanitizeSafely(headers, _sensitiveHeaders);

  /// Returns a URL whose sensitive query parameter values are masked.
  String sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasQuery) {
        return url;
      }

      final sanitizedParameters = <String, List<String>>{};
      for (final entry in uri.queryParametersAll.entries) {
        sanitizedParameters[entry.key] = _matches(entry.key, _sensitiveKeys)
            ? List<String>.filled(entry.value.length, mask)
            : List<String>.of(entry.value);
      }
      return uri.replace(queryParameters: sanitizedParameters).toString();
    } catch (_) {
      return sanitizationFailed;
    }
  }

  Object? _sanitizeSafely(Object? value, Set<String> sensitiveNames) {
    try {
      return _sanitize(value, sensitiveNames, HashSet<Object>.identity(), 0);
    } catch (_) {
      return sanitizationFailed;
    }
  }

  Object? _sanitize(
    Object? value,
    Set<String> sensitiveNames,
    Set<Object> ancestors,
    int depth,
  ) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is ByteBuffer || value is TypedData) {
      return binaryContent;
    }
    if (depth >= _maximumDepth) {
      return recursionLimit;
    }
    if (value is Map) {
      if (!ancestors.add(value)) {
        return circularReference;
      }
      try {
        final sanitized = <Object?, Object?>{};
        for (final entry in value.entries) {
          final key = entry.key;
          sanitized[key] = key is String && _matches(key, sensitiveNames)
              ? mask
              : _sanitize(entry.value, sensitiveNames, ancestors, depth + 1);
        }
        return sanitized;
      } finally {
        ancestors.remove(value);
      }
    }
    if (value is List) {
      if (!ancestors.add(value)) {
        return circularReference;
      }
      try {
        return <Object?>[
          for (final item in value)
            _sanitize(item, sensitiveNames, ancestors, depth + 1),
        ];
      } finally {
        ancestors.remove(value);
      }
    }
    return unsupportedContent;
  }

  static Set<String> _effectiveNames({
    required Set<String> custom,
    required Set<String> defaults,
    required bool includeDefaults,
  }) => <String>{
    if (includeDefaults) ...defaults.map(_normalize),
    ...custom.map(_normalize),
  };

  static bool _matches(String name, Set<String> sensitiveNames) =>
      sensitiveNames.contains(_normalize(name));

  static String _normalize(String name) => name.trim().toLowerCase();
}
