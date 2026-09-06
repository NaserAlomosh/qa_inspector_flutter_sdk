import 'package:flutter/material.dart';

import '../core/qa_inspector_controller.dart';
import 'inspector_shell.dart';

/// The global integration boundary for QA Inspector UI.
class QaInspector extends StatefulWidget {
  /// Creates an inspector above [child] using an externally owned controller.
  const QaInspector({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The controller shared by the SDK collectors.
  final QaInspectorController controller;

  /// The isolated host application subtree.
  final Widget child;

  @override
  State<QaInspector> createState() => _QaInspectorState();
}

class _QaInspectorState extends State<QaInspector> {
  bool _isOpen = false;

  @override
  void didUpdateWidget(QaInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.controller.config.enabled && _isOpen) {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.config.enabled) {
      return widget.child;
    }
    return Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        widget.child,
        if (_isOpen)
          Positioned.fill(
            child: InspectorShell(
              controller: widget.controller,
              onClose: () => setState(() => _isOpen = false),
            ),
          )
        else
          Positioned(
            right: 16,
            bottom: 16 + MediaQueryData.fromView(View.of(context)).padding.bottom,
            child: _QaEntryButton(
              onPressed: () => setState(() => _isOpen = true),
            ),
          ),
      ],
    );
  }
}

class _QaEntryButton extends StatelessWidget {
  const _QaEntryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData.fromView(View.of(context)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(colorSchemeSeed: Colors.deepPurple),
          child: FloatingActionButton.small(
            key: const Key('qa-inspector-button'),
            tooltip: 'Open QA Inspector',
            onPressed: onPressed,
            child: const Text('QA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
