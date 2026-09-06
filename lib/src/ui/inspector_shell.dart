import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/qa_inspector_controller.dart';
import '../report/qa_report_builder.dart';
import '../report/qa_report_data.dart';
import '../report/qa_report_file_sharer.dart';
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
import 'theme/qa_inspector_theme_mode.dart';
import 'theme/qa_theme.dart';

/// Generates a report image from an immutable report snapshot.
typedef QaReportExporter =
    Future<QaReportExportResult> Function(
      BuildContext context,
      QaReportData data,
    );

/// Hosts the isolated full-screen inspector application.
class InspectorShell extends StatefulWidget {
  const InspectorShell({
    required this.controller,
    required this.onClose,
    this.themeMode = QaInspectorThemeMode.dark,
    this.reportSharer = const QaReportFileSharer(),
    this.reportExporter,
    super.key,
  });
  final QaInspectorController controller;
  final VoidCallback onClose;
  final QaInspectorThemeMode themeMode;

  /// Delivers successful PNG exports through the platform share sheet.
  final QaReportSharer reportSharer;

  /// Overrides PNG generation in presentation tests.
  final QaReportExporter? reportExporter;

  @override
  State<InspectorShell> createState() => _InspectorShellState();
}

class _InspectorShellState extends State<InspectorShell> {
  late final Locale? _hostLocale = Localizations.maybeLocaleOf(context);
  late final String _message = selectQaMessage(_hostLocale);

  @override
  Widget build(BuildContext context) {
    final rtl = _hostLocale?.languageCode.toLowerCase() == 'ar';
    return MediaQuery(
      data: MediaQueryData.fromView(View.of(context)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: QaTheme.resolve(widget.themeMode),
        builder: (context, child) => Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
        home: _Inspector(
          controller: widget.controller,
          onClose: widget.onClose,
          message: _message,
          reportSharer: widget.reportSharer,
          reportExporter: widget.reportExporter,
        ),
      ),
    );
  }
}

class _Inspector extends StatefulWidget {
  const _Inspector({
    required this.controller,
    required this.onClose,
    required this.message,
    required this.reportSharer,
    this.reportExporter,
  });
  final QaInspectorController controller;
  final VoidCallback onClose;
  final String message;
  final QaReportSharer reportSharer;
  final QaReportExporter? reportExporter;

  @override
  State<_Inspector> createState() => _InspectorState();
}

class _InspectorState extends State<_Inspector> {
  bool _isExportingPng = false;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      key: const Key('qa-inspector-overlay'),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('qa-inspector-close'),
          onPressed: widget.onClose,
          icon: const Icon(Icons.close),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('QA Inspector'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: QaColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE SESSION',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: QaColors.success),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<_ReportAction>(
            key: const Key('qa-report-actions'),
            tooltip: 'Report actions',
            onSelected: (action) => _handleReportAction(context, action),
            itemBuilder: (context) => <PopupMenuEntry<_ReportAction>>[
              const PopupMenuItem(
                key: Key('qa-copy-report'),
                value: _ReportAction.copy,
                child: ListTile(
                  leading: Icon(Icons.copy_outlined),
                  title: Text('Copy Report'),
                ),
              ),
              PopupMenuItem(
                key: Key('qa-export-png'),
                value: _ReportAction.exportPng,
                enabled: !_isExportingPng,
                child: const ListTile(
                  leading: Icon(Icons.image_outlined),
                  title: Text('Export PNG'),
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: <Widget>[
                  Icon(Icons.ios_share_outlined, size: 19),
                  SizedBox(width: 4),
                  Text('Report'),
                ],
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('qa-clear-session'),
            onPressed: () => _confirmClear(context),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Clear'),
          ),
        ],
        bottom: const TabBar(
          tabAlignment: TabAlignment.fill,
          tabs: <Widget>[
            Tab(
              icon: Icon(Icons.timeline, size: 18),
              text: 'Timeline',
              height: 52,
            ),
            Tab(icon: Icon(Icons.http, size: 18), text: 'APIs', height: 52),
            Tab(
              icon: Icon(Icons.alt_route, size: 18),
              text: 'Routes',
              height: 52,
            ),
            Tab(
              icon: Icon(Icons.edit_note, size: 18),
              text: 'Notes',
              height: 52,
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller.changes,
        builder: (context, _) {
          final events = widget.controller.events;
          return Column(
            children: <Widget>[
              SessionSummary(
                events: events,
                currentRoute: widget.controller.currentRoute,
              ),
              QaSessionMessage(message: widget.message),
              const SizedBox(height: 6),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    TimelineTab(events: events),
                    ApisTab(events: events),
                    RoutesTab(events: events),
                    NotesTab(controller: widget.controller),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _handleReportAction(
    BuildContext context,
    _ReportAction action,
  ) async {
    if (!widget.controller.config.enabled) return;
    const limits = QaReportLimits();
    final data = const QaReportBuilder(limits: limits).build(
      events: widget.controller.events,
      notes: widget.controller.notes,
      currentRoute: widget.controller.currentRoute,
      generatedAt: DateTime.now(),
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
        if (context.mounted) {
          _showMessage(context, 'The QA report could not be copied.');
        }
      }
      return;
    }
    if (_isExportingPng) return;
    setState(() => _isExportingPng = true);
    try {
      final exporter =
          widget.reportExporter ??
          const QaReportImageExporter(limits: limits).export;
      late final QaReportExportResult result;
      try {
        result = await exporter(context, data);
      } catch (_) {
        if (context.mounted) {
          _showMessage(context, 'The PNG report could not be generated.');
        }
        return;
      }
      final bytes = result.bytes;
      final filename = result.filename;
      if (bytes == null || filename == null) {
        if (context.mounted) {
          _showMessage(
            context,
            result.errorMessage ?? 'The PNG report could not be generated.',
          );
        }
        return;
      }
      if (!context.mounted) return;
      final renderObject = context.findRenderObject();
      final origin = renderObject is RenderBox && renderObject.hasSize
          ? renderObject.localToGlobal(Offset.zero) & renderObject.size
          : const Rect.fromLTWH(0, 0, 1, 1);
      late final QaReportShareResult shareResult;
      try {
        shareResult = await widget.reportSharer.share(
          bytes: bytes,
          filename: filename,
          sharePositionOrigin: origin,
        );
      } catch (_) {
        if (context.mounted) {
          _showMessage(context, 'The report could not be shared.');
        }
        return;
      }
      if (!context.mounted || shareResult.isSuccess) return;
      final message = switch (shareResult.status) {
        QaReportShareStatus.preparationFailed ||
        QaReportShareStatus.writeFailed =>
          'The report file could not be prepared.',
        _ => 'The report could not be shared.',
      };
      _showMessage(context, message);
    } finally {
      if (mounted) setState(() => _isExportingPng = false);
    }
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
        title: const Text('Clear QA session?'),
        content: const Text(
          'This removes captured routes, API events, and QA notes from the current session.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('qa-confirm-clear'),
            style: FilledButton.styleFrom(backgroundColor: QaColors.failure),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear Session',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (clear == true) widget.controller.clearSession();
  }
}

enum _ReportAction { copy, exportPng }
