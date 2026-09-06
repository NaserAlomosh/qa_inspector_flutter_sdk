import 'dart:convert';

import '../events/qa_event.dart';
import '../events/qa_network_event.dart';
import '../events/qa_route_event.dart';
import 'qa_report_data.dart';
import 'qa_report_limits.dart';

/// Builds an immutable, bounded report from one captured event snapshot.
final class QaReportBuilder {
  /// Creates a builder with bounded [limits].
  const QaReportBuilder({this.limits = const QaReportLimits()});

  /// Stable route label used when route context is unavailable.
  static const String unknownRoute = '<unknown>';

  /// Limits applied before renderer consumption.
  final QaReportLimits limits;

  /// Builds a report without retaining [events] or any controller state.
  ///
  /// Route events remain in snapshot order. A request at the exact timestamp of
  /// a transition belongs to the new visit when its captured route matches it.
  QaReportData build({
    required Iterable<QaEvent> events,
    required String notes,
    required String? currentRoute,
    required DateTime generatedAt,
    QaReportMetadata? metadata,
  }) {
    final snapshot = List<QaEvent>.of(events, growable: false);
    final routes = <_Visit>[];
    final networks = <_IndexedNetwork>[];
    for (var i = 0; i < snapshot.length; i++) {
      final event = snapshot[i];
      if (event is QaRouteEvent && event.action != QaRouteAction.remove) {
        final destination = event.currentRoute ?? event.toRoute;
        routes.add(
          _Visit(
            route: _route(destination),
            enteredAt: event.timestamp,
            enteredFrom: event.fromRoute,
            enteredBy: event.fromRoute == null ? null : event.action,
          ),
        );
      } else if (event is QaNetworkEvent) {
        networks.add(_IndexedNetwork(event, i));
      }
    }

    if (routes.isEmpty && networks.isNotEmpty) {
      routes.add(
        _Visit(
          route: _route(networks.first.event.route ?? currentRoute),
          enteredAt: null,
          enteredFrom: null,
          enteredBy: null,
        ),
      );
    } else if (routes.isEmpty && currentRoute != null) {
      routes.add(
        _Visit(
          route: _route(currentRoute),
          enteredAt: null,
          enteredFrom: null,
          enteredBy: null,
        ),
      );
    }

    final assignments = List.generate(routes.length, (_) => <_IndexedNetwork>[]);
    for (final network in networks) {
      if (routes.isEmpty) break;
      final index = _visitFor(network.event, routes);
      assignments[index].add(network);
    }
    for (final items in assignments) {
      items.sort((a, b) {
        final time = a.event.startedAt.compareTo(b.event.startedAt);
        return time != 0 ? time : a.sourceIndex.compareTo(b.sourceIndex);
      });
    }

    final totalScreens = routes.length;
    final totalApis = networks.length;
    final failedApis = networks
        .where((item) => item.event.outcome == QaNetworkOutcome.failure)
        .length;
    final visibleVisits = routes.take(limits.maxSteps).toList(growable: false);
    var remainingApis = limits.maxApis;
    var omittedApis = 0;
    final steps = <QaReportStep>[];
    for (var i = 0; i < visibleVisits.length; i++) {
      final visit = visibleVisits[i];
      final allApis = assignments[i];
      final take = remainingApis < allApis.length ? remainingApis : allApis.length;
      final reportApis = allApis.take(take).map((item) => _api(item.event)).toList();
      remainingApis -= take;
      omittedApis += allApis.length - take;
      final next = i + 1 < routes.length ? routes[i + 1] : null;
      steps.add(
        QaReportStep(
          number: i + 1,
          route: visit.route,
          screen: _screenName(visit.route),
          enteredAt: visit.enteredAt,
          enteredFrom: visit.enteredFrom,
          enteredBy: visit.enteredBy,
          apis: reportApis,
          nextNavigation: next == null
              ? null
              : QaReportNavigation(
                  action: next.enteredBy ?? QaRouteAction.push,
                  fromRoute: visit.route,
                  toRoute: next.route,
                ),
          isFinal: i == routes.length - 1,
          omittedApis: allApis.length - take,
        ),
      );
    }
    for (var i = visibleVisits.length; i < routes.length; i++) {
      omittedApis += assignments[i].length;
    }

    return QaReportData(
      generatedAt: generatedAt,
      currentRoute: _route(currentRoute ?? (routes.isEmpty ? null : routes.last.route)),
      notes: _limitText(notes),
      steps: steps,
      totalScreens: totalScreens,
      totalApis: totalApis,
      failedApis: failedApis,
      omittedSteps: totalScreens - visibleVisits.length,
      omittedApis: omittedApis,
      metadata: metadata,
    );
  }

  int _visitFor(QaNetworkEvent event, List<_Visit> visits) {
    final route = _route(event.route);
    final matching = <int>[];
    for (var i = 0; i < visits.length; i++) {
      if (visits[i].route == route) matching.add(i);
    }
    final candidates = matching.isEmpty ? List.generate(visits.length, (i) => i) : matching;
    for (final index in candidates) {
      final start = visits[index].enteredAt;
      final end = index + 1 < visits.length ? visits[index + 1].enteredAt : null;
      final afterStart = start == null || !event.startedAt.isBefore(start);
      final beforeEnd = end == null || event.startedAt.isBefore(end);
      if (afterStart && beforeEnd) return index;
    }
    for (final index in candidates.reversed) {
      final start = visits[index].enteredAt;
      if (start == null || !event.startedAt.isBefore(start)) return index;
    }
    return candidates.first;
  }

  QaReportApi _api(QaNetworkEvent event) => QaReportApi(
    method: event.method,
    url: event.url,
    path: event.path,
    route: _route(event.route),
    startedAt: event.startedAt,
    completedAt: event.completedAt,
    duration: event.duration,
    statusCode: event.statusCode,
    outcome: event.outcome,
    queryParameters: _format(event.queryParameters),
    requestBody: _format(event.requestBody.data),
    responseBody: _format(event.responseBody.data),
    requestTruncated: event.requestBody.isTruncated,
    responseTruncated: event.responseBody.isTruncated,
    errorType: event.error?.type,
    errorMessage: event.error?.message,
  );

  String _format(Object? value) {
    if (value == null) return 'None';
    try {
      return _limitText(
        const JsonEncoder.withIndent('  ').convert(_sorted(value)),
      );
    } catch (_) {
      return _limitText(value.toString());
    }
  }

  String _limitText(String value) {
    if (value.length <= limits.maxTextPayloadCharacters) return value;
    return '${value.substring(0, limits.maxTextPayloadCharacters)}\n[preview limited]';
  }

  Object? _sorted(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _sorted(value.entries.firstWhere((e) => e.key.toString() == key).value),
      };
    }
    if (value is Iterable) return value.map(_sorted).toList(growable: false);
    if (value is num || value is bool || value is String) return value;
    return value.toString();
  }

  String _route(String? value) => value == null || value.trim().isEmpty ? unknownRoute : value;

  String _screenName(String route) {
    if (route == unknownRoute) return route;
    final segments = route.split('/').where((part) => part.isNotEmpty).toList();
    if (segments.isEmpty) return route;
    return segments.last.replaceAll(RegExp(r'[-_]'), ' ');
  }
}

final class _Visit {
  const _Visit({required this.route, required this.enteredAt, required this.enteredFrom, required this.enteredBy});
  final String route;
  final DateTime? enteredAt;
  final String? enteredFrom;
  final QaRouteAction? enteredBy;
}

final class _IndexedNetwork {
  const _IndexedNetwork(this.event, this.sourceIndex);
  final QaNetworkEvent event;
  final int sourceIndex;
}
