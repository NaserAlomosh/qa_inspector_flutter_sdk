import 'package:flutter/material.dart';

import '../../events/qa_route_event.dart';
import '../utils/presentation_formatters.dart';

/// Displays a summary of one route event.
class RouteTile extends StatelessWidget {
  /// Creates a route event tile.
  const RouteTile({required this.event, this.showCurrent = false, super.key});

  /// The route event to display.
  final QaRouteEvent event;
  /// Whether to include the event's current route.
  final bool showCurrent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        key: Key('qa-route-${event.id}'),
        leading: const Icon(Icons.alt_route),
        title: Text(event.action.name.toUpperCase()),
        subtitle: Text(
          '${formatRoute(event.fromRoute)} → ${formatRoute(event.toRoute)}\n'
          '${showCurrent ? 'Current: ${formatRoute(event.currentRoute)} • ' : ''}${formatTime(event.timestamp)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
