import 'dart:async';
import 'dart:collection';
import '../../event.dart';
import '../../typedefs.dart';
import '../event_store.dart';
import '../event_subscription.dart';
import '../exceptions.dart';
import '../lock.dart';

/// In-memory implementation of EventStore
class InMemoryEventStore implements EventStore {
  final _events = HashMap<ID, List<Event>>();
  final _lock = Lock();
  final List<EventSubscriber> _subscribers = [];

  @override
  Future<void> appendEvents(
      ID aggregateId, List<Event> events, int expectedVersion) async {
    await _lock.synchronized(() {
      final currentEvents = _events[aggregateId] ?? [];
      if (currentEvents.isEmpty) {
        _events[aggregateId] =
            events.toList(); // Create new list if none exists
      } else {
        // Version check
        if (currentEvents.length != expectedVersion) {
          throw ConcurrencyException(
              'Expected version $expectedVersion but found ${currentEvents.length}');
        }
        currentEvents.addAll(events); // Append to existing list
      }
      for (final subscriber in _subscribers) {
        for (final event in events) {
          subscriber.onEvent(event);
        }
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

  @override
  void registerSubscriber(EventSubscriber subscriber) {
    _subscribers.add(subscriber);
  }
}

/// Exception thrown when concurrent modifications conflict
class ConcurrencyException implements Exception {
  final String message;
  ConcurrencyException(this.message);
  @override
  String toString() => message;
}
