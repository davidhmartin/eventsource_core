import 'dart:async';
import 'dart:collection';
import '../../event.dart';
import '../../typedefs.dart';
import '../event_store.dart';
import '../lock.dart';

/// In-memory implementation of EventStore
class InMemoryEventStore implements EventStore {
  final _events = HashMap<ID, List<Event>>();
  final _lock = Lock();

  @override
  Future<void> appendEvents(
      ID aggregateId, List<Event> events, int expectedVersion) async {
    await _lock.synchronized(() {
      final existingEvents = _events[aggregateId] ?? [];
      if (existingEvents.isEmpty) {
        _events[aggregateId] =
            events.toList(); // Create new list if none exists
      } else {
        // Version check
        if (existingEvents.length != expectedVersion) {
          throw ConcurrencyException(
              'Expected version $expectedVersion but found ${existingEvents.length}');
        }
        existingEvents.addAll(events); // Append to existing list
      }
      return Future.value(); // Explicit return for the synchronized callback
    });
  }

  @override
  Stream<Event> getEvents(ID aggregateId,
      {int? fromVersion,
      int? toVersion,
      String? origin,
      bool Function(Event)? filter}) async* {
    List<Event> events = await _lock.synchronized(() {
      List<Event>? events = _events[aggregateId];
      events ??= [];
      return Future.value(List.from(events));
    });

    int from = fromVersion ?? 0;
    int to = toVersion ?? maxInt;
    for (final Event e in events) {
      if (e.version < from ||
          e.version > to ||
          (origin != null && e.origin != origin) ||
          (filter != null && !filter(e))) {
        continue;
      }
      yield e;
    }
  }
}

/// Exception thrown when concurrent modifications conflict
class ConcurrencyException implements Exception {
  final String message;
  ConcurrencyException(this.message);
  @override
  String toString() => message;
}
