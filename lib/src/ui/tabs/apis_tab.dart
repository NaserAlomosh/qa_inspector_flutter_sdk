import 'package:flutter/material.dart';

import '../../events/qa_event.dart';
import '../../events/qa_network_event.dart';
import '../api/api_details.dart';
import '../api/network_tile.dart';
import '../empty_state.dart';
import '../utils/presentation_formatters.dart';

enum _ApiFilter { all, success, failed, cancelled }

/// Displays searchable and filterable network events.
class ApisTab extends StatefulWidget {
  /// Creates the APIs tab.
  const ApisTab({required this.events, super.key});

  /// The current immutable event snapshot.
  final List<QaEvent> events;

  @override
  State<ApisTab> createState() => _ApisTabState();
}

class _ApisTabState extends State<ApisTab> with AutomaticKeepAliveClientMixin {
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
    final routes = <String>{for (final api in allApis) formatRoute(api.route)}.toList()..sort();
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
          (_selectedRoute == null || formatRoute(api.route) == _selectedRoute);
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
              ? const EmptyState('No APIs match the current filters')
              : ListView.builder(
                  key: const Key('qa-api-list'),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => NetworkTile(
                    event: visible[index],
                    onTap: () => openApiDetails(context, visible[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

String _filterLabel(_ApiFilter filter) => switch (filter) {
  _ApiFilter.all => 'All',
  _ApiFilter.success => 'Success',
  _ApiFilter.failed => 'Failed',
  _ApiFilter.cancelled => 'Cancelled',
};
