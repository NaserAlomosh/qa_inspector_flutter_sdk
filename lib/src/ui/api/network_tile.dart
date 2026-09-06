import 'package:flutter/material.dart';

import '../../events/qa_network_event.dart';
import '../theme/qa_colors.dart';
import '../utils/presentation_formatters.dart';

class NetworkTile extends StatelessWidget {
  const NetworkTile({required this.event, this.onTap, super.key});
  final QaNetworkEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (event.outcome) {
      QaNetworkOutcome.success => dark ? QaColors.successDark : QaColors.success,
      QaNetworkOutcome.failure => dark ? QaColors.failureDark : QaColors.failure,
      QaNetworkOutcome.cancelled => dark ? QaColors.cancelledDark : QaColors.cancelled,
    };
    final status = event.statusCode?.toString() ?? event.outcome.name.toUpperCase();
    final path = event.path.isEmpty ? event.url : event.path;
    return Semantics(
      label: '${event.outcome.name} API, ${event.method}, $path, status $status',
      button: onTap != null,
      child: InkWell(
        key: Key('qa-network-${event.id}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Container(width: 4, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 10),
            Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Row(children: <Widget>[
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(5)), child: Text(event.method, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color))),
                const SizedBox(width: 7),
                Expanded(child: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)),
              ]),
              const SizedBox(height: 5),
              Text('$status • ${event.duration.inMilliseconds} ms', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
              Text('${formatRoute(event.route)} • ${formatTime(event.startedAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: QaColors.slate)),
            ]))),
            if (onTap != null) const Icon(Icons.chevron_right, size: 20),
          ]),
        ),
      ),
    );
  }
}
