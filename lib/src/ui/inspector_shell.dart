import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/qa_inspector_controller.dart';
import '../report/qa_report_builder.dart';
import '../report/qa_report_image_exporter.dart';
import '../report/qa_report_limits.dart';
import '../report/qa_report_text_renderer.dart';
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
            PopupMenuButton<_ReportAction>(
              key: const Key('qa-report-actions'),
              tooltip: 'Report actions',
              onSelected: (action) => _handleReportAction(context, action),
              itemBuilder: (context) => const <PopupMenuEntry<_ReportAction>>[
                PopupMenuItem(
                  key: Key('qa-copy-report'),
                  value: _ReportAction.copy,
                  child: Text('Copy Report'),
                ),
                PopupMenuItem(
                  key: Key('qa-export-png'),
                  value: _ReportAction.exportPng,
                  child: Text('Export PNG'),
                ),
              ],
            ),
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

  Future<void> _handleReportAction(BuildContext context, _ReportAction action) async {
    if (!controller.config.enabled) return;
    const limits = QaReportLimits();
    final events = controller.events;
    final notes = controller.notes;
    final currentRoute = controller.currentRoute;
    final generatedAt = DateTime.now();
    final data = const QaReportBuilder(limits: limits).build(
      events: events,
      notes: notes,
      currentRoute: currentRoute,
      generatedAt: generatedAt,
    );
    if (action == _ReportAction.copy) {
      final bounded = const QaReportTextRenderer().renderForClipboard(
        data,
        maxCharacters: limits.maxClipboardCharacters,
      );
      try {
        await Clipboard.setData(ClipboardData(text: bounded));
        if (context.mounted) _showMessage(context, 'QA report copied.');
      } catch (_) {
        if (context.mounted) _showMessage(context, 'The QA report could not be copied.');
      }
      return;
    }
    final result = await const QaReportImageExporter(limits: limits).export(context, data);
    if (!context.mounted) return;
    _showMessage(
      context,
      result.isSuccess
          ? 'PNG report generated: ${result.filename}'
          : result.errorMessage ?? 'The PNG report could not be generated.',
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

enum _ReportAction { copy, exportPng }
