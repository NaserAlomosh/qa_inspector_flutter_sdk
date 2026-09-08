import 'package:flutter/material.dart';

import '../../events/qa_network_event.dart';
import '../../report/qa_report_data.dart';

/// Dedicated, theme-isolated report document used by PNG export.
class QaReportWidget extends StatelessWidget {
  /// Creates a report document from immutable [data].
  const QaReportWidget({required this.data, super.key});

  /// Snapshot rendered by this document.
  final QaReportData data;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff334155)),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      child: ColoredBox(
        color: const Color(0xfff8fafc),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xff0f172a),
              fontSize: 13,
              height: 1.35,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'QA REPORT',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _Summary(data: data),
                const SizedBox(height: 16),
                _Box(
                  title: 'ISSUE NOTES',
                  child: Text(
                    data.notes.trim().isEmpty ? 'None' : data.notes.trim(),
                  ),
                ),
                if (data.omittedSteps > 0)
                  _Notice('${data.omittedSteps} additional steps omitted'),
                if (data.omittedApis > 0)
                  _Notice('${data.omittedApis} additional APIs omitted'),
                ...data.steps.map((step) => _StepCard(step: step)),
                if (data.steps.isEmpty)
                  const _Notice('No screen or API activity captured'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data});
  final QaReportData data;
  @override
  Widget build(BuildContext context) => _Box(
    title: 'SUMMARY',
    child: Wrap(
      spacing: 20,
      runSpacing: 8,
      children: <Widget>[
        Text('Generated: ${data.generatedAt.toIso8601String()}'),
        Text('Current Screen: ${data.currentRoute}'),
        Text('Screens: ${data.totalScreens}'),
        Text('APIs: ${data.totalApis}'),
        Text(
          'Failed: ${data.failedApis}',
          style: const TextStyle(
            color: Color(0xffb91c1c),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});
  final QaReportStep step;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: _Box(
      title: 'STEP ${step.number}  •  ${step.screen}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Route: ${step.route}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text('Entered At: ${step.enteredAt?.toIso8601String() ?? 'Unknown'}'),
          Text('Entered From: ${step.enteredFrom ?? 'None'}'),
          Text(
            'Navigation: ${step.enteredBy?.name.toUpperCase() ?? 'Initial'}',
          ),
          const SizedBox(height: 10),
          Text(
            'APIs Triggered: ${step.apis.isEmpty ? 'None' : step.apis.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...step.apis.asMap().entries.map(
            (entry) => _ApiCard(api: entry.value, number: entry.key + 1),
          ),
          if (step.omittedApis > 0)
            _Notice('${step.omittedApis} additional APIs omitted'),
          const SizedBox(height: 12),
          const Text(
            'NEXT ACTION',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            step.nextNavigation == null
                ? 'None\nUser remained on ${step.route}'
                : '${step.nextNavigation!.action.name.toUpperCase()}\n${step.nextNavigation!.fromRoute} → ${step.nextNavigation!.toRoute}',
          ),
        ],
      ),
    ),
  );
}

class _ApiCard extends StatelessWidget {
  const _ApiCard({required this.api, required this.number});
  final QaReportApi api;
  final int number;
  @override
  Widget build(BuildContext context) {
    final failed = api.outcome == QaNetworkOutcome.failure;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: failed ? const Color(0xfffff1f2) : Colors.white,
        border: Border.all(
          color: failed ? const Color(0xffe11d48) : const Color(0xffcbd5e1),
          width: failed ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'API $number${failed ? ' • FAILED' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: failed ? const Color(0xffbe123c) : null,
            ),
          ),
          Text(
            '${api.method} ${api.path}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Status: ${api.statusCode ?? (api.outcome == QaNetworkOutcome.pending ? 'Pending' : api.outcome == QaNetworkOutcome.cancelled ? 'Cancelled' : 'Unavailable')}',
          ),
          Text('Outcome: ${api.outcome.name.toUpperCase()}'),
          Text(
            'Duration: ${api.duration == null ? 'Pending' : '${api.duration!.inMilliseconds} ms'}',
          ),
          const SizedBox(height: 8),
          _Payload(label: 'Query', value: api.queryParameters),
          _Payload(
            label: 'Request',
            value: api.requestBody,
            truncated: api.requestTruncated,
          ),
          _Payload(
            label: 'Response',
            value: api.responseBody,
            truncated: api.responseTruncated,
          ),
          if (api.errorType != null || api.errorMessage != null)
            _Payload(
              label: 'Error',
              value: [
                api.errorType,
                api.errorMessage,
              ].whereType<String>().join(': '),
            ),
        ],
      ),
    );
  }
}

class _Payload extends StatelessWidget {
  const _Payload({
    required this.label,
    required this.value,
    this.truncated = false,
  });
  final String label;
  final String value;
  final bool truncated;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      '$label:\n$value${truncated ? '\n[$label truncated]' : ''}',
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
    ),
  );
}

class _Box extends StatelessWidget {
  const _Box({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffcbd5e1)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      '[$message]',
      style: const TextStyle(
        fontStyle: FontStyle.italic,
        color: Color(0xff92400e),
      ),
    ),
  );
}
