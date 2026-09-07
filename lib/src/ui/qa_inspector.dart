import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/qa_inspector_controller.dart';
import 'inspector_shell.dart';
import 'theme/qa_inspector_theme_mode.dart';
import 'theme/qa_theme.dart';

/// The global integration boundary for QA Inspector UI.
class QaInspector extends StatelessWidget {
  const QaInspector({
    required this.controller,
    required this.child,
    this.themeMode = QaInspectorThemeMode.dark,
    super.key,
  });

  final QaInspectorController controller;
  final Widget child;
  final QaInspectorThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    if (!controller.config.enabled) {
      return child;
    }

    return Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        child,
        _QaInspectorOverlay(controller: controller, themeMode: themeMode),
      ],
    );
  }
}

class _QaInspectorOverlay extends StatefulWidget {
  const _QaInspectorOverlay({
    required this.controller,
    required this.themeMode,
  });

  final QaInspectorController controller;
  final QaInspectorThemeMode themeMode;

  @override
  State<_QaInspectorOverlay> createState() => _QaInspectorOverlayState();
}

class _QaInspectorOverlayState extends State<_QaInspectorOverlay> {
  bool _isOpen = false;
  Offset? _buttonPosition;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: _isOpen
          ? InspectorShell(
              controller: widget.controller,
              themeMode: widget.themeMode,
              onClose: () {
                setState(() => _isOpen = false);
              },
            )
          : _QaEntryOverlay(
              initialPosition: _buttonPosition,
              themeMode: widget.themeMode,
              onPositionChanged: (position) {
                _buttonPosition = position;
              },
              onPressed: () {
                setState(() => _isOpen = true);
              },
            ),
    );
  }
}

class _QaEntryOverlay extends StatefulWidget {
  const _QaEntryOverlay({
    required this.initialPosition,
    required this.onPositionChanged,
    required this.onPressed,
    required this.themeMode,
  });

  final Offset? initialPosition;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onPressed;
  final QaInspectorThemeMode themeMode;

  @override
  State<_QaEntryOverlay> createState() => _QaEntryOverlayState();
}

class _QaEntryOverlayState extends State<_QaEntryOverlay> {
  static const _size = Size(64, 42);
  static const _margin = 16.0;
  static const _snapDuration = Duration(milliseconds: 180);

  Offset? _position;
  Size? _lastViewport;
  bool _dragging = false;
  bool _snapping = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final padding = MediaQueryData.fromView(View.of(context)).padding;
      final viewport = Size(constraints.maxWidth, constraints.maxHeight);
      final bounds = _bounds(viewport, padding);
      var position =
          _position ??
          widget.initialPosition ??
          Offset(bounds.right, bounds.bottom);
      position = _clamp(position, bounds);
      _position = position;
      if (_lastViewport != viewport) {
        _lastViewport = viewport;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onPositionChanged(_position!);
        });
      }
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          AnimatedPositioned(
            duration: _snapping ? _snapDuration : Duration.zero,
            curve: Curves.easeOutCubic,
            left: position.dx,
            top: position.dy,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              onPanStart: (_) {
                HapticFeedback.selectionClick();
                setState(() {
                  _dragging = true;
                  _snapping = false;
                });
              },
              onPanUpdate: (details) => setState(() {
                _position = _clamp(_position! + details.delta, bounds);
              }),
              onPanEnd: (_) {
                final current = _clamp(_position!, bounds);
                final snappedX =
                    current.dx - bounds.left < bounds.right - current.dx
                    ? bounds.left
                    : bounds.right;
                setState(() {
                  _position = Offset(snappedX, current.dy);
                  _dragging = false;
                  _snapping = !MediaQuery.disableAnimationsOf(context);
                });
                widget.onPositionChanged(_position!);
                HapticFeedback.selectionClick();
              },
              onPanCancel: () => setState(() => _dragging = false),
              child: _QaEntryButton(
                dragging: _dragging,
                onPressed: widget.onPressed,
                themeMode: widget.themeMode,
              ),
            ),
          ),
        ],
      );
    },
  );

  Rect _bounds(Size viewport, EdgeInsets padding) {
    final left = padding.left + _margin;
    final top = padding.top + _margin;
    return Rect.fromLTRB(
      left,
      top,
      (viewport.width - padding.right - _margin - _size.width)
          .clamp(left, double.infinity)
          .toDouble(),
      (viewport.height - padding.bottom - _margin - _size.height)
          .clamp(top, double.infinity)
          .toDouble(),
    );
  }

  Offset _clamp(Offset value, Rect bounds) => Offset(
    value.dx.clamp(bounds.left, bounds.right).toDouble(),
    value.dy.clamp(bounds.top, bounds.bottom).toDouble(),
  );
}

class _QaEntryButton extends StatelessWidget {
  const _QaEntryButton({
    required this.dragging,
    required this.onPressed,
    required this.themeMode,
  });

  final bool dragging;
  final VoidCallback onPressed;
  final QaInspectorThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final colors = QaTheme.colors(themeMode);
    return Semantics(
      label: 'Open QA Inspector',
      hint: 'Tap to open. Drag to reposition.',
      button: true,
      onTap: onPressed,
      child: AnimatedScale(
        scale: dragging ? 1.04 : 1,
        duration: const Duration(milliseconds: 150),
        child: Material(
          key: const Key('qa-inspector-button'),
          color: colors.accent,
          elevation: dragging ? 10 : 6,
          shadowColor: colors.shadow,
          shape: StadiumBorder(side: BorderSide(color: colors.buttonBorder)),
          child: SizedBox(
            width: 64,
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.bug_report_outlined,
                  size: 17,
                  color: colors.buttonForeground,
                ),
                const SizedBox(width: 5),
                Text(
                  'QA',
                  style: TextStyle(
                    color: colors.buttonForeground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
