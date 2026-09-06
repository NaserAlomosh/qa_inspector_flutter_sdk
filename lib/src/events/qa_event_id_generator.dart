final class QaEventIdGenerator {
  QaEventIdGenerator()
    : _sessionPrefix = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  final String _sessionPrefix;
  int _sequence = 0;

  String next() => '$_sessionPrefix-${_sequence++}';
}
