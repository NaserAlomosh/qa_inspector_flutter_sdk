import 'package:flutter/material.dart';

import '../../events/qa_network_event.dart';
import '../utils/presentation_formatters.dart';

/// Displays a summary of one sanitized network event.
class NetworkTile extends StatelessWidget {
  /// Creates a network event tile.
  const NetworkTile({required this.event, this.onTap, super.key});

  /// The sanitized network event to display.
  final QaNetworkEvent event;
  /// The action invoked when the tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (event.outcome) {
      QaNetworkOutcome.success => Colors.green.shade700,
      QaNetworkOutcome.failure => Colors.red.shade700,
      QaNetworkOutcome.cancelled => Colors.orange.shade800,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        key: Key('qa-network-${event.id}'),
        leading: Icon(Icons.http, color: color),
        title: Text('${event.method} ${event.path.isEmpty ? event.url : event.path}'),
        subtitle: Text(
          '${event.statusCode?.toString() ?? event.outcome.name.toUpperCase()} • '
          '${event.duration.inMilliseconds} ms\n'
          '${formatRoute(event.route)} • ${formatTime(event.startedAt)}',
        ),
        isThreeLine: true,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
