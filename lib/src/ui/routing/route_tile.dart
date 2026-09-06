import 'package:flutter/material.dart';

import '../../events/qa_route_event.dart';
import '../theme/qa_colors.dart';
import '../utils/presentation_formatters.dart';

class RouteTile extends StatelessWidget {
  const RouteTile({required this.event, this.showCurrent = false, super.key});
  final QaRouteEvent event;
  final bool showCurrent;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark ? QaColors.navigationDark : QaColors.navigation;
    return Container(
      key: Key('qa-route-${event.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Icon(Icons.alt_route, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(event.action.name.toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text('${formatRoute(event.fromRoute)} → ${formatRoute(event.toRoute)}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text('${showCurrent ? 'Current: ${formatRoute(event.currentRoute)} • ' : ''}${formatTime(event.timestamp)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: QaColors.slate)),
        ]))),
      ]),
    );
  }
}
