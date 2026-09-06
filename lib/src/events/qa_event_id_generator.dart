final class QaEventIdGenerator {
  QaEventIdGenerator._();

  static final String _sessionPrefix =
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  static int _sequence = 0;

  static String next() => '$_sessionPrefix-${_sequence++}';
}
