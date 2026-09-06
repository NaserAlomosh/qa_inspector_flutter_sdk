/// Configuration for sensitive-data masking.
final class QaDataSanitizationConfig {
  /// Creates a sanitization configuration.
  QaDataSanitizationConfig({
    Set<String> sensitiveKeys = const <String>{},
    Set<String> sensitiveHeaders = const <String>{},
    this.includeDefaultSensitiveKeys = true,
    this.includeDefaultSensitiveHeaders = true,
  }) : sensitiveKeys = Set<String>.unmodifiable(sensitiveKeys),
       sensitiveHeaders = Set<String>.unmodifiable(sensitiveHeaders);

  /// Additional structured body and query parameter keys to mask.
  final Set<String> sensitiveKeys;

  /// Additional header names to mask.
  final Set<String> sensitiveHeaders;

  /// Whether the SDK's default sensitive keys remain enabled.
  final bool includeDefaultSensitiveKeys;

  /// Whether the SDK's default sensitive headers remain enabled.
  final bool includeDefaultSensitiveHeaders;
}
