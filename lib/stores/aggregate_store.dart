import '../aggregate.dart';
import '../event.dart';
import '../event_store.dart';
import '../snapshot_store.dart';

/// Interface for storing and retrieving aggregates
///
/// The aggregate store efficiently manages aggregates using a combination of
/// snapshots and events. It coordinates between the event store and snapshot
/// store to provide optimal performance when loading aggregates.
abstract class AggregateStore<TAggregate extends Aggregate<TState>, TState> {
  /// Get an aggregate by its ID
  ///
  /// Returns null if the aggregate doesn't exist
  Future<TAggregate?> getAggregate(String id);

  /// Save any uncommitted events for the aggregate
  ///
  /// This will append the events to the event store and optionally
  /// create a new snapshot if the snapshot frequency is met.
  Future<void> save(TAggregate aggregate);
}

/// Default implementation of [AggregateStore]
class DefaultAggregateStore<TAggregate extends Aggregate<TState>, TState>
    implements AggregateStore<TAggregate, TState> {
  final EventStore _eventStore;
  final SnapshotStore<TState>? _snapshotStore;
  final TAggregate Function(String) _aggregateFactory;
  final int _snapshotFrequency;

  /// Creates a new aggregate store
  ///
  /// [eventStore] - Required store for aggregate events
  /// [snapshotStore] - Optional store for aggregate snapshots
  /// [aggregateFactory] - Function to create new aggregates with a given ID
  /// [snapshotFrequency] - How often to take snapshots (event count). Default is 100.
  DefaultAggregateStore(
    this._eventStore,
    this._aggregateFactory, {
    SnapshotStore<TState>? snapshotStore,
    int snapshotFrequency = 100,
  })  : _snapshotStore = snapshotStore,
        _snapshotFrequency = snapshotFrequency;

  @override
  Future<TAggregate?> getAggregate(String id) async {
    // Try to get the latest snapshot if we have a snapshot store
    TAggregate? aggregate;
    int fromVersion = 0;

    if (_snapshotStore != null) {
      final snapshot = await _snapshotStore!.getLatestSnapshot(id);
      if (snapshot != null) {
        aggregate = _aggregateFactory(id);
        aggregate.loadFromSnapshot(snapshot.$1, snapshot.$2);
        fromVersion = snapshot.$2;
      }
    }

    // Get any events after the snapshot version
    final events = await _eventStore.getEvents(id, fromVersion: fromVersion);
    if (events.isEmpty && aggregate == null) {
      return null;
    }

    // Either create a new aggregate or apply events to snapshot
    aggregate ??= _aggregateFactory(id);
    for (final event in events) {
      aggregate.applyEvent(event);
    }

    return aggregate;
  }

  @override
  Future<void> save(TAggregate aggregate) async {
    final events = aggregate.uncommittedEvents;
    if (events.isEmpty) {
      return;
    }

    // Save the events
    await _eventStore.appendEvents(
        aggregate.id, events, aggregate.version - events.length);

    // Create a snapshot if needed
    if (_snapshotStore != null && aggregate.version % _snapshotFrequency == 0) {
      await _snapshotStore!
          .saveSnapshot(aggregate.id, aggregate.state, aggregate.version);
    }

    // Clear the uncommitted events
    aggregate.clearUncommittedEvents();
  }
}
