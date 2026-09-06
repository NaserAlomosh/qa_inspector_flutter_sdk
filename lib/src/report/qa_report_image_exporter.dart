import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../ui/report/qa_report_widget.dart';
import 'qa_report_data.dart';
import 'qa_report_filename.dart';
import 'qa_report_limits.dart';

/// Result of a non-throwing PNG report export.
final class QaReportExportResult {
  const QaReportExportResult._({this.bytes, this.filename, this.errorMessage});

  /// Creates a successful export result.
  factory QaReportExportResult.success(Uint8List bytes, String filename) =>
      QaReportExportResult._(bytes: bytes, filename: filename);

  /// Creates a safe export failure.
  factory QaReportExportResult.failure(String message) =>
      QaReportExportResult._(errorMessage: message);

  /// Encoded PNG bytes on success.
  final Uint8List? bytes;
  /// Suggested deterministic filename on success.
  final String? filename;
  /// User-readable failure message.
  final String? errorMessage;

  /// Whether PNG generation succeeded.
  bool get isSuccess => bytes != null;
}

/// Renders the dedicated report document into bounded PNG bytes.
final class QaReportImageExporter {
  /// Creates an exporter with bounded [limits].
  const QaReportImageExporter({this.limits = const QaReportLimits()});

  /// Image allocation limits.
  final QaReportLimits limits;

  /// Generates PNG bytes without reading live inspector state.
  Future<QaReportExportResult> export(
    BuildContext context,
    QaReportData data,
  ) async {
    if (limits.pixelRatio <= 0 || limits.pixelRatio > 3) {
      return QaReportExportResult.failure('PNG export settings are unsafe.');
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return QaReportExportResult.failure('PNG export is unavailable in this view.');
    }

    final key = GlobalKey();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 0,
        top: 0,
        width: limits.maxImageWidth,
        child: IgnorePointer(
          child: UnconstrainedBox(
            constrainedAxis: Axis.horizontal,
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: RepaintBoundary(
                key: key,
                child: QaReportWidget(data: data),
              ),
            ),
          ),
        ),
      ),
    );
    try {
      overlay.insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      final boundary = key.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || !boundary.hasSize) {
        return QaReportExportResult.failure('The PNG report could not be rendered.');
      }
      final size = boundary.size;
      if (size.width > limits.maxImageWidth || size.height > limits.maxImageHeight) {
        return QaReportExportResult.failure(
          'The report is too large to export safely. Reduce the session size and try again.',
        );
      }
      final pixelCount = size.width * size.height * limits.pixelRatio * limits.pixelRatio;
      final maxPixels = limits.maxImageWidth * limits.maxImageHeight * limits.pixelRatio * limits.pixelRatio;
      if (pixelCount > maxPixels) {
        return QaReportExportResult.failure('The PNG report dimensions are unsafe.');
      }
      final image = await boundary.toImage(pixelRatio: limits.pixelRatio);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          return QaReportExportResult.failure('PNG encoding failed.');
        }
        return QaReportExportResult.success(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          qaReportPngFilename(data.generatedAt),
        );
      } finally {
        image.dispose();
      }
    } catch (_) {
      return QaReportExportResult.failure('The PNG report could not be generated safely.');
    } finally {
      entry.remove();
      entry.dispose();
    }
  }
}
