import 'package:flutter/widgets.dart';

import '../core/qa_inspector_config.dart';
import '../core/qa_inspector_runtime.dart';

/// The root integration point for QA Inspector.
///
/// This phase does not add UI, so the widget transparently returns [child].
/// Future inspector UI will remain isolated above this child.
class QaInspector extends StatefulWidget {
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
  State<QaInspector> createState() => _QaInspectorState();
}

class _QaInspectorState extends State<QaInspector> {
  late QaInspectorRuntime _runtime;

  @override
  void initState() {
    super.initState();
    _runtime = QaInspectorRuntime(widget.config);
  }

  @override
  void didUpdateWidget(QaInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.enabled == widget.config.enabled &&
        oldWidget.config.maxEvents == widget.config.maxEvents) {
      return;
    }

    _runtime.dispose();
    _runtime = QaInspectorRuntime(widget.config);
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
