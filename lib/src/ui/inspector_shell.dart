import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/qa_inspector_controller.dart';
import '../report/qa_report_builder.dart';
import '../report/qa_report_image_exporter.dart';
import '../report/qa_report_limits.dart';
import '../report/qa_report_text_renderer.dart';
import 'session_message.dart';
import 'session_summary.dart';
import 'tabs/apis_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/routes_tab.dart';
import 'tabs/timeline_tab.dart';
import 'theme/qa_colors.dart';
import 'theme/qa_theme.dart';

/// Hosts the isolated full-screen inspector application.
class InspectorShell extends StatefulWidget {
  const InspectorShell({required this.controller, required this.onClose, super.key});
  final QaInspectorController controller;
  final VoidCallback onClose;

  @override
  State<InspectorShell> createState() => _InspectorShellState();
}

class _InspectorShellState extends State<InspectorShell> {
  late final Locale? _hostLocale = Localizations.maybeLocaleOf(context);
  late final Brightness _hostBrightness = Theme.of(context).brightness;
  late final String _message = selectQaMessage(_hostLocale);

  @override
  Widget build(BuildContext context) {
    final rtl = _hostLocale?.languageCode.toLowerCase() == 'ar';
    return MediaQuery(
      data: MediaQueryData.fromView(View.of(context)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: QaTheme.light(),
        darkTheme: QaTheme.dark(),
        themeMode: _hostBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
        home: _Inspector(controller: widget.controller, onClose: widget.onClose, message: _message),
      ),
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({required this.controller, required this.onClose, required this.message});
  final QaInspectorController controller;
  final VoidCallback onClose;
  final String message;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      key: const Key('qa-inspector-overlay'),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(key: const Key('qa-inspector-close'), onPressed: onClose, icon: const Icon(Icons.close), semanticLabel: 'Close inspector'),
        titleSpacing: 4,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          const Text('QA Inspector'),
          Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: QaColors.success, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('LIVE SESSION', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: QaColors.success)),
          ]),
        ]),
        actions: <Widget>[
          PopupMenuButton<_ReportAction>(
            key: const Key('qa-report-actions'),
            tooltip: 'Report actions',
            onSelected: (action) => _handleReportAction(context, action),
            itemBuilder: (context) => const <PopupMenuEntry<_ReportAction>>[
              PopupMenuItem(key: Key('qa-copy-report'), value: _ReportAction.copy, child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Copy Report'))),
              PopupMenuItem(key: Key('qa-export-png'), value: _ReportAction.exportPng, child: ListTile(leading: Icon(Icons.image_outlined), title: Text('Export PNG'))),
            ],
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Row(children: <Widget>[Icon(Icons.ios_share_outlined, size: 19), SizedBox(width: 4), Text('Report')])),
          ),
          TextButton.icon(key: const Key('qa-clear-session'), onPressed: () => _confirmClear(context), icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Clear')),
        ],
        bottom: const TabBar(
          tabAlignment: TabAlignment.fill,
          tabs: <Widget>[
            Tab(icon: Icon(Icons.timeline, size: 18), text: 'Timeline', height: 52),
            Tab(icon: Icon(Icons.http, size: 18), text: 'APIs', height: 52),
            Tab(icon: Icon(Icons.alt_route, size: 18), text: 'Routes', height: 52),
            Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Notes', height: 52),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: controller.changes,
        builder: (context, _) {
          final events = controller.events;
          return Column(children: <Widget>[
            SessionSummary(events: events, currentRoute: controller.currentRoute),
            QaSessionMessage(message: message),
            const SizedBox(height: 6),
            Expanded(child: TabBarView(children: <Widget>[
              TimelineTab(events: events),
              ApisTab(events: events),
              RoutesTab(events: events),
              NotesTab(controller: controller),
            ])),
          ]);
        },
      ),
    ),
  );

  Future<void> _handleReportAction(BuildContext context, _ReportAction action) async {
    if (!controller.config.enabled) return;
    const limits = QaReportLimits();
    final data = const QaReportBuilder(limits: limits).build(events: controller.events, notes: controller.notes, currentRoute: controller.currentRoute, generatedAt: DateTime.now());
    if (action == _ReportAction.copy) {
      final bounded = const QaReportTextRenderer().renderForClipboard(data, maxCharacters: limits.maxClipboardCharacters);
      try {
        await Clipboard.setData(ClipboardData(text: bounded));
        if (context.mounted) _showMessage(context, 'QA report copied.');
      } catch (_) {
        if (context.mounted) _showMessage(context, 'The QA report could not be copied.');
      }
      return;
    }
    final result = await const QaReportImageExporter(limits: limits).export(context, data);
    if (context.mounted) _showMessage(context, result.isSuccess ? 'PNG report generated: ${result.filename}' : result.errorMessage ?? 'The PNG report could not be generated.');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Clear QA session?'),
      content: const Text('This removes captured routes, API events, and QA notes from the current session.'),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(key: const Key('qa-confirm-clear'), style: FilledButton.styleFrom(backgroundColor: QaColors.failure), onPressed: () => Navigator.pop(context, true), child: const Text('Clear Session')),
      ],
    ));
    if (clear == true) controller.clearSession();
  }
}

enum _ReportAction { copy, exportPng }
