import 'package:flutter/material.dart';

import '../events/qa_event.dart';
import '../events/qa_network_event.dart';
import '../events/qa_route_event.dart';
import 'utils/presentation_formatters.dart';

/// Displays summary counts derived from the current event snapshot.
class SessionSummary extends StatelessWidget {
  /// Creates the session summary.
  const SessionSummary({required this.events, required this.currentRoute, super.key});

  /// The current immutable event snapshot.
  final List<QaEvent> events;
  /// The route active in the host application.
  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    var apiCount = 0;
    var failedCount = 0;
    var routeCount = 0;
    for (final event in events) {
      if (event is QaNetworkEvent) {
        apiCount++;
        if (event.outcome == QaNetworkOutcome.failure) failedCount++;
      } else if (event is QaRouteEvent) {
        routeCount++;
      }
    }
    return Semantics(
      label: 'Session summary',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Wrap(
          spacing: 16,
          runSpacing: 4,
          children: <Widget>[
            Text('${events.length} events'),
            Text('$apiCount APIs'),
            Text('$failedCount failed'),
            Text('$routeCount routes'),
            Text('Current: ${formatRoute(currentRoute)}'),
          ],
        ),
      ),
    );
  }
}
