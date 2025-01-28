import 'event.dart';

/// Interface for event storage
abstract class EventStore {
  /// Append events to the store
  Future<void> appendEvents(
      String aggregateId, List<Event> events, int expectedVersion);

  /// Get events from an aggregate specified by ID.
  /// [fromVersion] - start from this version (inclusive). Omitting fromVersion retrieves all events.
  /// [origin] - filter by origin system/component
  /// [filter] - filter events based on a predicate
  Future<List<Event>> getEvents(String aggregateId,
      {int? fromVersion, String? origin, bool Function(Event)? filter});
}
