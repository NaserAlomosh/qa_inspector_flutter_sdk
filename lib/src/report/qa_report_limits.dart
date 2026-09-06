/// Safety limits applied while building and exporting QA reports.
final class QaReportLimits {
  /// Creates bounded report limits.
  const QaReportLimits({
    this.maxSteps = 50,
    this.maxApis = 50,
    this.maxTextPayloadCharacters = 12000,
    this.maxClipboardCharacters = 100000,
    this.maxImageWidth = 1200,
    this.maxImageHeight = 12000,
    this.pixelRatio = 1.5,
  }) : assert(maxSteps > 0),
       assert(maxApis > 0),
       assert(maxTextPayloadCharacters > 0),
       assert(maxClipboardCharacters > 100),
       assert(maxImageWidth > 0),
       assert(maxImageHeight > 0),
       assert(pixelRatio > 0 && pixelRatio <= 3);

  /// Maximum screen visits retained in one report.
  final int maxSteps;

  /// Maximum APIs retained across the report.
  final int maxApis;

  /// Maximum characters retained for each formatted payload field.
  final int maxTextPayloadCharacters;

  /// Maximum characters copied to the system clipboard.
  final int maxClipboardCharacters;

  /// Maximum logical image width.
  final double maxImageWidth;

  /// Maximum logical image height.
  final double maxImageHeight;

  /// Pixel ratio used for PNG generation.
  final double pixelRatio;
}
