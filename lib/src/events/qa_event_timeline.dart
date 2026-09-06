import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'qa_event.dart';

final class QaEventTimeline extends ChangeNotifier {
  QaEventTimeline({required this.maxEvents})
    : assert(maxEvents > 0, 'maxEvents must be greater than zero.');

  final int maxEvents;

  final List<QaEvent> _events = <QaEvent>[];

  List<QaEvent> get events => UnmodifiableListView<QaEvent>(_events);

  List<QaEvent> snapshot() => List<QaEvent>.unmodifiable(_events);

  void add(QaEvent event) {
    if (_events.length == maxEvents) {
      _events.removeAt(0);
    }

    _events.add(event);
    notifyListeners();
  }

  void clear() {
    if (_events.isEmpty) {
      return;
    }

    _events.clear();
    notifyListeners();
  }
}
