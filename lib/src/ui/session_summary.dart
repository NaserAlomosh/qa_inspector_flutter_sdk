import 'package:flutter/material.dart';

import '../events/qa_event.dart';
import '../events/qa_network_event.dart';
import '../events/qa_route_event.dart';
import 'theme/qa_colors.dart';
import 'utils/presentation_formatters.dart';

class SessionSummary extends StatelessWidget {
  const SessionSummary({
    required this.events,
    required this.currentRoute,
    super.key,
  });
  final List<QaEvent> events;
  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    final apis = events.whereType<QaNetworkEvent>();
    final failed = apis
        .where((event) => event.outcome == QaNetworkOutcome.failure)
        .length;
    final routes = events.whereType<QaRouteEvent>().length;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Semantics(
        label:
            'Session summary. $routes screens, ${apis.length} APIs, $failed failed.',
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'CURRENT ROUTE',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: QaColors.slate),
              ),
              const SizedBox(height: 3),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  formatRoute(currentRoute),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _Metric(label: 'Screens', value: '$routes'),
                  _Metric(label: 'APIs', value: '${apis.length}'),
                  _Metric(
                    label: 'Failed',
                    value: '$failed',
                    color: failed > 0 ? QaColors.failure : null,
                  ),
                  _Metric(label: 'Events', value: '${events.length}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: <Widget>[
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: QaColors.slate),
        ),
      ],
    ),
  );
}
