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

  /// Replaces the event with [event.id] without changing its position.
  ///
  /// Returns whether a matching event was present in this session.
  bool replace(QaEvent event) {
    final index = _events.indexWhere((existing) => existing.id == event.id);
    if (index < 0) {
      return false;
    }
    _events[index] = event;
    notifyListeners();
    return true;
  }

  void clear() {
    if (_events.isEmpty) {
      return;
    }

    _events.clear();
    notifyListeners();
  }
}
