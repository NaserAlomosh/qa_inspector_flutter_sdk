import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../events/qa_network_event.dart';
import '../utils/presentation_formatters.dart';

/// Opens the details view for a sanitized network event.
Future<void> openApiDetails(BuildContext context, QaNetworkEvent event) async {
  await showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Dialog.fullscreen(child: ApiDetails(event: event)),
  );
}

/// Displays all captured details for a sanitized network event.
class ApiDetails extends StatelessWidget {
  /// Creates an API details view.
  const ApiDetails({required this.event, super.key});

  /// The sanitized network event to display and copy.
  final QaNetworkEvent event;

  @override
  Widget build(BuildContext context) {
    final request = prettyValue(event.requestBody.data);
    final response = prettyValue(event.responseBody.data);
    final details = formatFullApiDetails(event, request: request, response: response);
    return Scaffold(
      key: const Key('qa-api-details'),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('qa-api-details-close'),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: Text('${event.method} ${event.path}'),
        actions: <Widget>[
          IconButton(
            key: const Key('qa-copy-api-details'),
            tooltip: 'Copy full API details',
            onPressed: () => _copy(context, details),
            icon: const Icon(Icons.copy_all),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          _DetailSection(
            title: 'General',
            value: 'Method: ${event.method}\nURL: ${event.url}\nRoute: ${formatRoute(event.route)}\n'
                'Status: ${event.statusCode ?? '—'}\nOutcome: ${event.outcome.name}\n'
                'Started: ${event.startedAt.toIso8601String()}\nCompleted: ${event.completedAt.toIso8601String()}\n'
                'Duration: ${event.duration.inMilliseconds} ms\n'
                'Request truncated: ${event.requestBody.isTruncated}\nResponse truncated: ${event.responseBody.isTruncated}',
            copyKey: const Key('qa-copy-url'),
            copyValue: event.url,
          ),
          _DetailSection(
            title: 'Headers',
            value: 'Request\n${prettyValue(event.requestHeaders)}\n\nResponse\n${prettyValue(event.responseHeaders)}',
          ),
          _DetailSection(
            title: 'Request',
            value:
                'Query parameters\n${prettyValue(event.queryParameters)}\n\nBody\n$request${formatTruncation(event.requestBody)}',
            copyKey: const Key('qa-copy-request'),
            copyValue: request,
          ),
          _DetailSection(
            title: 'Response',
            value: '$response${formatTruncation(event.responseBody)}',
            copyKey: const Key('qa-copy-response'),
            copyValue: response,
          ),
          _DetailSection(
            title: 'Error',
            value: event.error == null
                ? 'No error metadata'
                : 'Type: ${event.error!.type}\nMessage: ${event.error!.message}',
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.value, this.copyKey, this.copyValue});

  final String title;
  final String value;
  final Key? copyKey;
  final String? copyValue;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              if (copyValue != null)
                IconButton(
                  key: copyKey,
                  tooltip: 'Copy $title',
                  onPressed: () => _copy(context, copyValue!),
                  icon: const Icon(Icons.copy),
                ),
            ],
          ),
          SelectableText(value),
        ],
      ),
    ),
  );
}

Future<void> _copy(BuildContext context, String value) async {
  const maxCopyLength = 100000;
  final bounded = value.length <= maxCopyLength
      ? value
      : '${value.substring(0, maxCopyLength)}\n[copy truncated]';
  await Clipboard.setData(ClipboardData(text: bounded));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied sanitized data')));
  }
}
