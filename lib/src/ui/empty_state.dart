import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title, {
    this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });
  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 30, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
