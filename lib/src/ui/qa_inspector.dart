import 'package:flutter/widgets.dart';

import '../core/qa_inspector_config.dart';

/// The root integration point for QA Inspector.
///
/// Phase 1 does not add UI or collect events, so this widget transparently
/// returns [child]. Future inspector UI will remain isolated above this child.
class QaInspector extends StatelessWidget {
  /// Creates a QA Inspector integration boundary.
  const QaInspector({
    required this.child,
    this.config = const QaInspectorConfig(),
    super.key,
  });

  /// The host application's root widget.
  final Widget child;

  /// Runtime configuration for the SDK.
  final QaInspectorConfig config;

  @override
  Widget build(BuildContext context) => child;
}
