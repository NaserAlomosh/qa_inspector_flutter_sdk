/// Immutable runtime configuration for QA Inspector.
final class QaInspectorConfig {
  /// Creates QA Inspector configuration.
  const QaInspectorConfig({
    this.enabled = false,
    this.maxEvents = defaultMaxEvents,
  }) : assert(maxEvents > 0, 'maxEvents must be greater than zero.');

  /// The default maximum number of events retained by the SDK.
  static const int defaultMaxEvents = 200;

  /// Whether QA Inspector is active.
  final bool enabled;

  /// The maximum number of events the SDK may retain.
  final int maxEvents;
}
