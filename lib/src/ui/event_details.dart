import 'package:flutter/material.dart';

import '../events/qa_event.dart';
import 'utils/presentation_formatters.dart';

/// Opens generic details for an event without a specialized presentation.
Future<void> openEventDetails(BuildContext context, QaEvent event) async {
  await showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Dialog.fullscreen(child: _EventDetails(event: event)),
  );
}

class _EventDetails extends StatelessWidget {
  const _EventDetails({required this.event});
  final QaEvent event;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('qa-event-details'),
    appBar: AppBar(
      leading: IconButton(
        key: const Key('qa-event-details-close'),
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      title: const Text('Event Details'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SelectableText(
          'Type: ${event.type.name.toUpperCase()}\n'
          'Timestamp: ${formatTime(event.timestamp)}\n'
          'Event ID: ${event.id}',
        ),
      ),
    ),
  );
}
