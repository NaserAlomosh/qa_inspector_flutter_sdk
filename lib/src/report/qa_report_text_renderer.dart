import '../events/qa_network_event.dart';
import 'qa_report_data.dart';

/// Produces the deterministic plain-text representation of a report snapshot.
final class QaReportTextRenderer {
  /// Creates a deterministic renderer.
  const QaReportTextRenderer();

  /// Renders [data] using the canonical step-oriented format.
  String render(QaReportData data) {
    final out = StringBuffer()
      ..writeln('QA REPORT')
      ..writeln()
      ..writeln('Generated: ${data.generatedAt.toIso8601String()}')
      ..writeln('Current Screen: ${data.currentRoute}')
      ..writeln('Total Screens: ${data.totalScreens}')
      ..writeln('Total APIs: ${data.totalApis}')
      ..writeln('Failed APIs: ${data.failedApis}')
      ..writeln()
      ..writeln('Issue Notes:')
      ..writeln(data.notes.trim().isEmpty ? 'None' : data.notes.trim());
    if (data.omittedSteps > 0) {
      out
        ..writeln()
        ..writeln('[${data.omittedSteps} additional steps omitted]');
    }
    if (data.omittedApis > 0) {
      out
        ..writeln()
        ..writeln('[${data.omittedApis} additional APIs omitted]');
    }
    if (data.steps.isEmpty) {
      out
        ..writeln()
        ..writeln('No screen or API activity captured.');
    }
    for (final step in data.steps) {
      out
        ..writeln()
        ..writeln('==================================================')
        ..writeln('STEP ${step.number}')
        ..writeln('==================================================')
        ..writeln()
        ..writeln('Screen: ${step.screen}')
        ..writeln('Route: ${step.route}')
        ..writeln(
          'Entered At: ${step.enteredAt?.toIso8601String() ?? 'Unknown'}',
        )
        ..writeln('Entered From: ${step.enteredFrom ?? 'None'}')
        ..writeln(
          'Navigation: ${step.enteredBy?.name.toUpperCase() ?? 'Initial'}',
        )
        ..writeln()
        ..writeln(
          'APIs Triggered: ${step.apis.isEmpty ? 'None' : step.apis.length}',
        );
      for (var i = 0; i < step.apis.length; i++) {
        _writeApi(out, step.apis[i], i + 1);
      }
      if (step.omittedApis > 0) {
        out
          ..writeln()
          ..writeln('[${step.omittedApis} additional APIs omitted]');
      }
      out
        ..writeln()
        ..writeln('NEXT ACTION:');
      final navigation = step.nextNavigation;
      if (navigation == null) {
        out
          ..writeln('None')
          ..writeln('User remained on ${step.route}');
      } else {
        out
          ..writeln(navigation.action.name.toUpperCase())
          ..writeln('${navigation.fromRoute} -> ${navigation.toRoute}');
      }
    }
    return out.toString().trimRight();
  }

  /// Renders and safely bounds a report for clipboard use.
  String renderForClipboard(QaReportData data, {required int maxCharacters}) {
    const marker = '\n\n[report truncated for clipboard safety]';
    final text = render(data);
    if (text.length <= maxCharacters) return text;
    final contentLength = maxCharacters - marker.length;
    if (contentLength <= 0) return marker.substring(0, maxCharacters);
    return '${text.substring(0, contentLength)}$marker';
  }

  void _writeApi(StringBuffer out, QaReportApi api, int number) {
    out
      ..writeln()
      ..writeln('API $number${api.isFailure ? ' - FAILED' : ''}')
      ..writeln('${api.method} ${api.path}')
      ..writeln('Status: ${_status(api)}')
      ..writeln('Outcome: ${api.outcome.name.toUpperCase()}')
      ..writeln('Duration: ${api.duration.inMilliseconds} ms')
      ..writeln()
      ..writeln('Query:')
      ..writeln(api.queryParameters)
      ..writeln()
      ..writeln('Request:')
      ..writeln(api.requestBody);
    if (api.requestTruncated) out.writeln('[request truncated]');
    out
      ..writeln()
      ..writeln('Response:')
      ..writeln(api.responseBody);
    if (api.responseTruncated) out.writeln('[response truncated]');
    if (api.errorType != null || api.errorMessage != null) {
      out
        ..writeln()
        ..writeln('Error:')
        ..writeln(
          [api.errorType, api.errorMessage].whereType<String>().join(': '),
        );
    }
  }

  String _status(QaReportApi api) {
    if (api.outcome == QaNetworkOutcome.cancelled) return 'Cancelled';
    return api.statusCode?.toString() ?? 'Unavailable';
  }
}
