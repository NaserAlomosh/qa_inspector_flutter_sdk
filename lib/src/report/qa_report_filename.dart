/// Returns a stable PNG filename derived from [generatedAt].
String qaReportPngFilename(DateTime generatedAt) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'qa_report_${generatedAt.year}${two(generatedAt.month)}${two(generatedAt.day)}_'
      '${two(generatedAt.hour)}${two(generatedAt.minute)}${two(generatedAt.second)}.png';
}
