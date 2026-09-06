import 'package:flutter/material.dart';

import '../core/qa_inspector_controller.dart';
import 'session_summary.dart';
import 'tabs/apis_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/routes_tab.dart';
import 'tabs/timeline_tab.dart';

/// Hosts the isolated full-screen inspector application.
class InspectorShell extends StatelessWidget {
  /// Creates the inspector shell.
  const InspectorShell({required this.controller, required this.onClose, super.key});

  /// The source of inspector session state.
  final QaInspectorController controller;
  /// Closes the inspector without changing host navigation.
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
                SessionSummary(events: events, currentRoute: controller.currentRoute),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      TimelineTab(events: events),
                      ApisTab(events: events),
                      RoutesTab(events: events),
                      NotesTab(controller: controller),
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
