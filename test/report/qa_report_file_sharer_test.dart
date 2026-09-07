import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qa_inspector/src/report/qa_report_file_sharer.dart';

void main() {
  test('writes exact PNG bytes using only the filename basename', () async {
    final directory = await Directory.systemTemp.createTemp(
      'qa-report-share-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final bytes = Uint8List.fromList(<int>[137, 80, 78, 71, 1, 2, 3]);
    late String sharedPath;
    String? sharedMimeType;
    final sharer = QaReportFileSharer(
      temporaryDirectoryProvider: () async => directory,
      platformFileSharer: (params) async {
        sharedPath = params.files!.single.path;
        sharedMimeType = params.files!.single.mimeType;
        throw StateError('Stop before invoking a platform channel.');
      },
    );

    final result = await sharer.share(
      bytes: bytes,
      filename: '../../../qa_report_20260906_232000.png',
      sharePositionOrigin: const Rect.fromLTWH(1, 1, 10, 10),
    );

    expect(result.status, QaReportShareStatus.shareFailed);
    expect(
      sharedPath,
      '${directory.path}${Platform.pathSeparator}qa_report_20260906_232000.png',
    );
    expect(sharedMimeType, 'image/png');
    expect(await File(sharedPath).readAsBytes(), bytes);
  });

  test('isolates temporary directory and file write failures', () async {
    final preparationResult =
        await QaReportFileSharer(
          temporaryDirectoryProvider: () =>
              Future<Directory>.error(StateError('unavailable')),
        ).share(
          bytes: Uint8List(0),
          filename: 'report.png',
          sharePositionOrigin: const Rect.fromLTWH(1, 1, 10, 10),
        );
    final writeResult =
        await QaReportFileSharer(
          temporaryDirectoryProvider: () async =>
              Directory('/missing/qa-report-directory'),
        ).share(
          bytes: Uint8List(0),
          filename: 'report.png',
          sharePositionOrigin: const Rect.fromLTWH(1, 1, 10, 10),
        );

    expect(preparationResult.status, QaReportShareStatus.preparationFailed);
    expect(writeResult.status, QaReportShareStatus.writeFailed);
  });
}
