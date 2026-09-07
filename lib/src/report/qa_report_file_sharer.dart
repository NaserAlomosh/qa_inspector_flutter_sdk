import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Outcome of preparing and presenting a report file.
enum QaReportShareStatus {
  /// The platform accepted the share operation.
  shared,

  /// The user dismissed the share sheet.
  dismissed,

  /// The temporary directory or filename was unavailable.
  preparationFailed,

  /// The PNG could not be written to the temporary directory.
  writeFailed,

  /// The platform share sheet could not be presented.
  shareFailed,
}

/// Non-throwing result returned by [QaReportSharer].
final class QaReportShareResult {
  /// Creates a result with [status].
  const QaReportShareResult(this.status);

  /// Outcome of the share operation.
  final QaReportShareStatus status;

  /// Whether the native share sheet was presented without an SDK failure.
  bool get isSuccess =>
      status == QaReportShareStatus.shared ||
      status == QaReportShareStatus.dismissed;
}

/// Boundary used by the inspector to deliver rendered report bytes.
abstract interface class QaReportSharer {
  /// Prepares and shares one PNG without throwing platform failures.
  Future<QaReportShareResult> share({
    required Uint8List bytes,
    required String filename,
    required Rect sharePositionOrigin,
  });
}

/// Supplies the OS-owned temporary directory.
typedef QaTemporaryDirectoryProvider = Future<Directory> Function();

/// Presents a prepared file through the platform share UI.
typedef QaPlatformFileSharer = Future<ShareResult> Function(ShareParams params);

Future<ShareResult> _shareFile(ShareParams params) =>
    SharePlus.instance.share(params);

/// Delivers an already-rendered report through the platform share sheet.
final class QaReportFileSharer implements QaReportSharer {
  /// Creates a sharer, with replaceable platform boundaries for tests.
  const QaReportFileSharer({
    this.temporaryDirectoryProvider = getTemporaryDirectory,
    this.platformFileSharer = _shareFile,
  });

  /// Resolves the directory used for the temporary PNG.
  final QaTemporaryDirectoryProvider temporaryDirectoryProvider;

  /// Invokes the native share sheet.
  final QaPlatformFileSharer platformFileSharer;

  @override
  Future<QaReportShareResult> share({
    required Uint8List bytes,
    required String filename,
    required Rect sharePositionOrigin,
  }) async {
    final safeFilename = filename.split(RegExp(r'[/\\]')).last;
    if (safeFilename.isEmpty || safeFilename == '.' || safeFilename == '..') {
      return const QaReportShareResult(QaReportShareStatus.preparationFailed);
    }

    late final Directory temporaryDirectory;
    try {
      temporaryDirectory = await temporaryDirectoryProvider();
    } catch (_) {
      return const QaReportShareResult(QaReportShareStatus.preparationFailed);
    }

    final file = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}$safeFilename',
    );
    try {
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      return const QaReportShareResult(QaReportShareStatus.writeFailed);
    }

    try {
      final result = await platformFileSharer(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      final status = switch (result.status) {
        ShareResultStatus.success => QaReportShareStatus.shared,
        ShareResultStatus.dismissed => QaReportShareStatus.dismissed,
        ShareResultStatus.unavailable => QaReportShareStatus.shareFailed,
      };
      return QaReportShareResult(status);
    } catch (_) {
      return const QaReportShareResult(QaReportShareStatus.shareFailed);
    }
  }
}
