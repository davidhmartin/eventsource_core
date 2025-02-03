import '../event.dart';
import '../typedefs.dart';
import 'event_subscription.dart';

/// Interface for event storage
abstract class EventStore {
  /// Append events to the store
  Future<void> appendEvents(
      ID aggregateId, List<Event> events, int expectedVersion);

  /// Retrieves a stream of events for a specific aggregate.
  ///
  /// Returns events as a [Stream] in the order they were appended to the store.
  ///
  /// Parameters:
  /// - [aggregateId] The unique identifier of the aggregate to fetch events for
  /// - [fromVersion] Optional starting version (inclusive) to retrieve events from.
  ///   If omitted, events are retrieved from the beginning
  /// - [toVersion] Optional ending version (inclusive) to retrieve events up to
  /// - [origin] Optional system or component identifier to filter events by their source
  /// - [filter] Optional predicate function to filter events. When provided, only
  ///   events that satisfy the predicate will be included in the stream
  ///
  /// Example:
  /// ```dart
  /// final events = await eventStore.getEvents(
  ///   'order-123',
  ///   fromVersion: 5,
  ///   origin: 'payment-service',
  ///   filter: (event) => event.type == 'PaymentProcessed'
  /// ).toList();
  /// ```
  Stream<Event> getEvents(ID aggregateId,
      {int? fromVersion,
      int? toVersion,
      String? origin,
      bool Function(Event)? filter});

  /// Register a new subscriber to receive events
  void registerSubscriber(EventSubscriber subscriber);
}
