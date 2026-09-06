import 'package:flutter/material.dart';

import '../../events/qa_route_event.dart';
import '../utils/presentation_formatters.dart';

/// Opens route details on QA Inspector's internal navigator.
Future<void> openRouteDetails(BuildContext context, QaRouteEvent event) async {
  await showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Dialog.fullscreen(child: RouteDetails(event: event)),
  );
}

/// Displays the captured fields of a route event.
class RouteDetails extends StatelessWidget {
  /// Creates route details for [event].
  const RouteDetails({required this.event, super.key});

  /// The immutable event being presented.
  final QaRouteEvent event;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('qa-route-details'),
    appBar: AppBar(
      leading: IconButton(
        key: const Key('qa-route-details-close'),
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      title: const Text('Navigation Event'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _RouteField(label: 'Action', value: event.action.name.toUpperCase()),
        _RouteField(label: 'From', value: formatRoute(event.fromRoute)),
        _RouteField(label: 'To', value: formatRoute(event.toRoute)),
        _RouteField(
          label: 'Current route',
          value: formatRoute(event.currentRoute),
        ),
        _RouteField(label: 'Timestamp', value: formatTime(event.timestamp)),
        _RouteField(label: 'Event ID', value: event.id),
      ],
    ),
  );
}

class _RouteField extends StatelessWidget {
  const _RouteField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 5),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
      ],
    ),
  );
}
