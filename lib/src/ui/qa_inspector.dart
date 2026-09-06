import 'package:flutter/widgets.dart';

import '../core/qa_inspector_controller.dart';

/// The root integration point for QA Inspector.
///
/// This phase does not add UI, so the widget transparently returns [child].
/// Future inspector UI will remain isolated above this child.
class QaInspector extends StatelessWidget {
  /// Creates a QA Inspector integration boundary.
  const QaInspector({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The externally owned controller shared by SDK collectors.
  ///
  /// QA Inspector does not dispose this controller.
  final QaInspectorController controller;

  /// The host application's root widget.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
