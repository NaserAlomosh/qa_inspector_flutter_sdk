import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/qa_inspector_controller.dart';
import '../events/qa_event.dart';
import '../events/qa_network_event.dart';
import '../events/qa_route_event.dart';

/// The global integration boundary for QA Inspector UI.
class QaInspector extends StatefulWidget {
  /// Creates an inspector above [child] using an externally owned controller.
  const QaInspector({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The controller shared by the SDK collectors.
  final QaInspectorController controller;

  /// The isolated host application subtree.
  final Widget child;

  @override
  State<QaInspector> createState() => _QaInspectorState();
}

class _QaInspectorState extends State<QaInspector> {
  bool _isOpen = false;

  @override
  void didUpdateWidget(QaInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.controller.config.enabled && _isOpen) {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.config.enabled) {
      return widget.child;
    }
    return Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        widget.child,
        if (_isOpen)
          Positioned.fill(
            child: _InspectorApplication(
              controller: widget.controller,
              onClose: () => setState(() => _isOpen = false),
            ),
          )
        else
          Positioned(
            right: 16,
            bottom: 16 + MediaQueryData.fromView(View.of(context)).padding.bottom,
            child: _QaEntryButton(
              onPressed: () => setState(() => _isOpen = true),
            ),
          ),
      ],
    );
  }
}

class _QaEntryButton extends StatelessWidget {
  const _QaEntryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData.fromView(View.of(context)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(colorSchemeSeed: Colors.deepPurple),
          child: FloatingActionButton.small(
            key: const Key('qa-inspector-button'),
            tooltip: 'Open QA Inspector',
            onPressed: onPressed,
            child: const Text('QA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _InspectorApplication extends StatelessWidget {
  const _InspectorApplication({required this.controller, required this.onClose});

  final QaInspectorController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData.fromView(View.of(context)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: _Inspector(controller: controller, onClose: onClose),
      ),
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({required this.controller, required this.onClose});

  final QaInspectorController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        key: const Key('qa-inspector-overlay'),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            key: const Key('qa-inspector-close'),
            tooltip: 'Close inspector',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
          title: const Text('QA Inspector'),
          actions: <Widget>[
            IconButton(
              key: const Key('qa-clear-session'),
              tooltip: 'Clear session',
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(text: 'Timeline'),
              Tab(text: 'APIs'),
              Tab(text: 'Routes'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: controller.changes,
          builder: (context, _) {
            final events = controller.events;
            return Column(
              children: <Widget>[
                _SessionSummary(events: events, currentRoute: controller.currentRoute),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      _TimelineTab(events: events),
                      _ApisTab(events: events),
                      _RoutesTab(events: events),
                      _NotesTab(controller: controller),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear current QA session?'),
        content: const Text('This will remove collected events and notes.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            key: const Key('qa-confirm-clear'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear == true) {
      controller.clearSession();
    }
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.events, required this.currentRoute});

  final List<QaEvent> events;
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
            Text('Current: ${_route(currentRoute)}'),
          ],
        ),
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.events});

  final List<QaEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const _EmptyState('No timeline events yet');
    return ListView.builder(
      key: const Key('qa-timeline-list'),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        if (event is QaNetworkEvent) return _NetworkTile(event: event);
        if (event is QaRouteEvent) return _RouteTile(event: event);
        return ListTile(title: Text(event.type.name.toUpperCase()), subtitle: Text(_time(event.timestamp)));
      },
    );
  }
}

enum _ApiFilter { all, success, failed, cancelled }

class _ApisTab extends StatefulWidget {
  const _ApisTab({required this.events});

  final List<QaEvent> events;

  @override
  State<_ApisTab> createState() => _ApisTabState();
}

class _ApisTabState extends State<_ApisTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  _ApiFilter _filter = _ApiFilter.all;
  String? _selectedRoute;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final allApis = widget.events.whereType<QaNetworkEvent>().toList(growable: false);
    final routes = <String>{for (final api in allApis) _route(api.route)}.toList()..sort();
    final query = _searchController.text.trim().toLowerCase();
    final visible = allApis.where((api) {
      final matchesFilter = switch (_filter) {
        _ApiFilter.all => true,
        _ApiFilter.success => api.outcome == QaNetworkOutcome.success,
        _ApiFilter.failed => api.outcome == QaNetworkOutcome.failure,
        _ApiFilter.cancelled => api.outcome == QaNetworkOutcome.cancelled,
      };
      final matchesSearch = query.isEmpty ||
          api.url.toLowerCase().contains(query) ||
          api.path.toLowerCase().contains(query) ||
          api.method.toLowerCase().contains(query);
      return matchesFilter && matchesSearch &&
          (_selectedRoute == null || _route(api.route) == _selectedRoute);
    }).toList(growable: false);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            key: const Key('qa-api-search'),
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search URL, path, or method',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _ApiFilter.values.map((filter) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                key: Key('qa-filter-${filter.name}'),
                label: Text(_filterLabel(filter)),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
            )).toList(),
          ),
        ),
        if (routes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String?>(
              key: const Key('qa-api-route-filter'),
              initialValue: routes.contains(_selectedRoute) ? _selectedRoute : null,
              decoration: const InputDecoration(labelText: 'Originating route', isDense: true),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(value: null, child: Text('All routes')),
                for (final route in routes) DropdownMenuItem<String?>(value: route, child: Text(route)),
              ],
              onChanged: (value) => setState(() => _selectedRoute = value),
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? const _EmptyState('No APIs match the current filters')
              : ListView.builder(
                  key: const Key('qa-api-list'),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => _NetworkTile(
                    event: visible[index],
                    onTap: () => _openApiDetails(context, visible[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RoutesTab extends StatelessWidget {
  const _RoutesTab({required this.events});

  final List<QaEvent> events;

  @override
  Widget build(BuildContext context) {
    final routes = events.whereType<QaRouteEvent>().toList(growable: false);
    if (routes.isEmpty) return const _EmptyState('No route events yet');
    return ListView.builder(
      key: const Key('qa-route-list'),
      itemCount: routes.length,
      itemBuilder: (context, index) => _RouteTile(event: routes[index], showCurrent: true),
    );
  }
}

class _NotesTab extends StatefulWidget {
  const _NotesTab({required this.controller});

  final QaInspectorController controller;

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> with AutomaticKeepAliveClientMixin {
  late final TextEditingController _controller = TextEditingController(text: widget.controller.notes);

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(_NotesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.controller.notes) {
      _controller.value = TextEditingValue(
        text: widget.controller.notes,
        selection: TextSelection.collapsed(offset: widget.controller.notes.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TextField(
        key: const Key('qa-notes-field'),
        controller: _controller,
        minLines: 8,
        maxLines: null,
        maxLength: QaInspectorController.maxNotesLength,
        onChanged: widget.controller.updateNotes,
        decoration: const InputDecoration(
          labelText: 'QA Notes',
          hintText: 'Describe the issue and steps to reproduce it…',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  const _NetworkTile({required this.event, this.onTap});

  final QaNetworkEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (event.outcome) {
      QaNetworkOutcome.success => Colors.green.shade700,
      QaNetworkOutcome.failure => Colors.red.shade700,
      QaNetworkOutcome.cancelled => Colors.orange.shade800,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        key: Key('qa-network-${event.id}'),
        leading: Icon(Icons.http, color: color),
        title: Text('${event.method} ${event.path.isEmpty ? event.url : event.path}'),
        subtitle: Text(
          '${event.statusCode?.toString() ?? event.outcome.name.toUpperCase()} • '
          '${event.duration.inMilliseconds} ms\n'
          '${_route(event.route)} • ${_time(event.startedAt)}',
        ),
        isThreeLine: true,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.event, this.showCurrent = false});

  final QaRouteEvent event;
  final bool showCurrent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        key: Key('qa-route-${event.id}'),
        leading: const Icon(Icons.alt_route),
        title: Text(event.action.name.toUpperCase()),
        subtitle: Text(
          '${_route(event.fromRoute)} → ${_route(event.toRoute)}\n'
          '${showCurrent ? 'Current: ${_route(event.currentRoute)} • ' : ''}${_time(event.timestamp)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)),
  );
}

Future<void> _openApiDetails(BuildContext context, QaNetworkEvent event) async {
  await showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Dialog.fullscreen(child: _ApiDetails(event: event)),
  );
}

class _ApiDetails extends StatelessWidget {
  const _ApiDetails({required this.event});

  final QaNetworkEvent event;

  @override
  Widget build(BuildContext context) {
    final request = _pretty(event.requestBody.data);
    final response = _pretty(event.responseBody.data);
    final details = _fullDetails(event, request: request, response: response);
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
            value: 'Method: ${event.method}\nURL: ${event.url}\nRoute: ${_route(event.route)}\n'
                'Status: ${event.statusCode ?? '—'}\nOutcome: ${event.outcome.name}\n'
                'Started: ${event.startedAt.toIso8601String()}\nCompleted: ${event.completedAt.toIso8601String()}\n'
                'Duration: ${event.duration.inMilliseconds} ms\n'
                'Request truncated: ${event.requestBody.isTruncated}\nResponse truncated: ${event.responseBody.isTruncated}',
            copyKey: const Key('qa-copy-url'),
            copyValue: event.url,
          ),
          _DetailSection(title: 'Headers', value: 'Request\n${_pretty(event.requestHeaders)}\n\nResponse\n${_pretty(event.responseHeaders)}'),
          _DetailSection(
            title: 'Request',
            value: 'Query parameters\n${_pretty(event.queryParameters)}\n\nBody\n$request${_truncation(event.requestBody)}',
            copyKey: const Key('qa-copy-request'),
            copyValue: request,
          ),
          _DetailSection(
            title: 'Response',
            value: '$response${_truncation(event.responseBody)}',
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
  final bounded = value.length <= maxCopyLength ? value : '${value.substring(0, maxCopyLength)}\n[copy truncated]';
  await Clipboard.setData(ClipboardData(text: bounded));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied sanitized data')));
  }
}

String _fullDetails(QaNetworkEvent event, {required String request, required String response}) =>
    '${event.method} ${event.url}\nRoute: ${_route(event.route)}\nStatus: ${event.statusCode ?? '—'}\n'
    'Outcome: ${event.outcome.name}\nDuration: ${event.duration.inMilliseconds} ms\n'
    'Request headers:\n${_pretty(event.requestHeaders)}\nRequest query:\n${_pretty(event.queryParameters)}\n'
    'Request body:\n$request${_truncation(event.requestBody)}\nResponse headers:\n${_pretty(event.responseHeaders)}\n'
    'Response body:\n$response${_truncation(event.responseBody)}\nError: '
    '${event.error == null ? 'none' : '${event.error!.type}: ${event.error!.message}'}';

String _pretty(Object? value) {
  if (value == null) return '—';
  try {
    final formatted = const JsonEncoder.withIndent('  ').convert(value);
    const renderLimit = 50000;
    return formatted.length <= renderLimit
        ? formatted
        : '${formatted.substring(0, renderLimit)}\n[display truncated]';
  } catch (_) {
    final fallback = value.toString();
    return fallback.length <= 50000 ? fallback : '${fallback.substring(0, 50000)}\n[display truncated]';
  }
}

String _truncation(QaPayloadCapture payload) => payload.isTruncated
    ? '\n[Payload truncated: ${payload.capturedSize ?? 0}/${payload.originalSize ?? 0} bytes retained]'
    : '';

String _route(String? route) => route == null || route.trim().isEmpty ? '<unnamed>' : route;

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:'
    '${value.second.toString().padLeft(2, '0')}.${value.millisecond.toString().padLeft(3, '0')}';

String _filterLabel(_ApiFilter filter) => switch (filter) {
  _ApiFilter.all => 'All',
  _ApiFilter.success => 'Success',
  _ApiFilter.failed => 'Failed',
  _ApiFilter.cancelled => 'Cancelled',
};
