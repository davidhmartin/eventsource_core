import 'dart:collection';
import '../../event.dart';
import '../../event_store.dart';
import '../../lock.dart';

/// In-memory implementation of EventStore
class InMemoryEventStore implements EventStore {
  final _events = HashMap<String, List<Event>>();
  final _lock = Lock();

  @override
  Future<void> appendEvents(
      String aggregateId, List<Event> events, int expectedVersion) async {
    return _lock.synchronized(() async {
      final existingEvents = _events[aggregateId] ?? [];

      // Version check
      if (existingEvents.length != expectedVersion) {
        throw ConcurrencyException(
            'Expected version $expectedVersion but found ${existingEvents.length}');
      }

      _events[aggregateId] = [...existingEvents, ...events];
    });
  }

  @override
  Future<List<Event>> getEvents(String aggregateId,
      {int? fromVersion, String? origin, bool Function(Event)? filter}) async {
    return _lock.synchronized(() async {
      var events = _events[aggregateId] ?? [];

      if (fromVersion != null) {
        events = events.where((e) => e.version >= fromVersion).toList();
      }

      if (origin != null) {
        events = events.where((e) => e.origin == origin).toList();
      }

      if (filter != null) {
        events = events.where(filter).toList();
      }

      return events;
    });
  }
}

/// Exception thrown when concurrent modifications conflict
class ConcurrencyException implements Exception {
  final String message;
  ConcurrencyException(this.message);

  @override
  String toString() => 'ConcurrencyException: $message';
}
