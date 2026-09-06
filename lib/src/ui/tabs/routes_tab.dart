import 'package:flutter/material.dart';

import '../../events/qa_event.dart';
import '../../events/qa_route_event.dart';
import '../empty_state.dart';
import '../routing/route_tile.dart';

/// Displays route events from the current session.
class RoutesTab extends StatelessWidget {
  /// Creates the routes tab.
  const RoutesTab({required this.events, super.key});

  /// The current immutable event snapshot.
  final List<QaEvent> events;

  @override
  Widget build(BuildContext context) {
    final routes = events.whereType<QaRouteEvent>().toList(growable: false);
    if (routes.isEmpty) return const EmptyState('No route events yet');
    return ListView.builder(
      key: const Key('qa-route-list'),
      itemCount: routes.length,
      itemBuilder: (context, index) => RouteTile(event: routes[index], showCurrent: true),
    );
  }
}
