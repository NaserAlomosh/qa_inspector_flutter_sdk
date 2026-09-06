import 'package:flutter/material.dart';

import '../../events/qa_event.dart';
import '../../events/qa_network_event.dart';
import '../../events/qa_route_event.dart';
import '../api/api_details.dart';
import '../api/network_tile.dart';
import '../empty_state.dart';
import '../event_details.dart';
import '../routing/route_details.dart';
import '../routing/route_tile.dart';
import '../utils/presentation_formatters.dart';

/// Displays all session events in insertion order.
class TimelineTab extends StatelessWidget {
  /// Creates the timeline tab.
  const TimelineTab({required this.events, super.key});

  /// The current immutable event snapshot.
  final List<QaEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const EmptyState('No events yet', message: 'Use the app and activity will appear here.', icon: Icons.timeline);
    return ListView.builder(
      key: const Key('qa-timeline-list'),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        if (event is QaNetworkEvent) {
          return NetworkTile(
            event: event,
            onTap: () => openApiDetails(context, event),
          );
        }
        if (event is QaRouteEvent) {
          return RouteTile(
            event: event,
            onTap: () => openRouteDetails(context, event),
          );
        }
        return ListTile(
          key: Key('qa-event-${event.id}'),
          onTap: () => openEventDetails(context, event),
          title: Text(event.type.name.toUpperCase()),
          subtitle: Text(formatTime(event.timestamp)),
          trailing: const Icon(Icons.chevron_right, size: 20),
        );
      },
    );
  }
}
