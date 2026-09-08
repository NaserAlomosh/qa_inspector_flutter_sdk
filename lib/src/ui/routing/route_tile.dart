import 'package:flutter/material.dart';

import '../../events/qa_route_event.dart';
import '../theme/qa_theme.dart';
import '../utils/presentation_formatters.dart';

class RouteTile extends StatelessWidget {
  const RouteTile({
    required this.event,
    this.showCurrent = false,
    this.onTap,
    super.key,
  });

  final QaRouteEvent event;
  final bool showCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QaTheme.colorsOf(context);
    final color = colors.navigation;
    return Semantics(
      label:
          '${event.action.name} from ${formatRoute(event.fromRoute)} to ${formatRoute(event.toRoute)}',
      button: onTap != null,
      child: InkWell(
        key: Key('qa-route-${event.id}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.border),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.alt_route, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.action.name.toUpperCase(),
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatRoute(event.fromRoute)} → ${formatRoute(event.toRoute)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${showCurrent ? 'Current: ${formatRoute(event.currentRoute)} • ' : ''}${formatTime(event.timestamp)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
