import 'package:flutter/material.dart';

/// Displays a centered message for an empty inspector section.
class EmptyState extends StatelessWidget {
  /// Creates an empty state with [message].
  const EmptyState(this.message, {super.key});

  /// The message shown to the user.
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)),
  );
}
