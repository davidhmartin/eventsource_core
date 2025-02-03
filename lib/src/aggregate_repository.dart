import '../aggregate.dart';
import '../typedefs.dart';
import 'event_store.dart';
import 'snapshot_store.dart';
import 'stores/null_snapshot_store.dart';

/// AggregateRepository is used to retrieve aggregates from the event store.
class AggregateRepository {
  final EventStore _eventStore;
  final Map<String, AggregateRehydrator> _rehydrators = {};
  final Map<String, AggregateFactory> _factories = {};
  final SnapshotStore _snapshotStore;

  AggregateRepository(this._eventStore, this._snapshotStore);

  /// Register a factory for a specific aggregate type
  AggregateRepository register<T extends Aggregate>(
      AggregateFactory<T> factory) {
    final tempAggregate = factory(newId());
    final aggregateType = tempAggregate.type;

    _factories[aggregateType] = factory;
    _rehydrators[aggregateType] =
        AggregateRehydrator<T>(_eventStore, factory, _snapshotStore);
    return this;
  }

  /// Create a new aggregate of the specified type
  Future<Aggregate> createAggregate(ID id, String type) async {
    if (!_factories.containsKey(type)) {
      throw ArgumentError('No factory registered for aggregate type: $type');
    }

    final factory = _factories[type] as AggregateFactory;
    return factory(id);
  }

  /// Get an aggregate by its ID. If not found, a new empty aggregate will be
  /// created.
  ///
  /// [aggregateType] is the unique identifier for the type of aggregate.
  /// [create] Optional flag to indicate whether to create a new aggregate if one
  ///   does not exist. Defaults to false.
  /// [toVersion] Optional version to get the aggregate up to. If not specified, the
  ///   latest version will be returned.
  /// throws [StateError] if no repository is registered for the given aggregate type
  Future<Aggregate> getAggregate(ID id, String aggregateType,
      {bool create = false, int toVersion = maxInt}) async {
    return _getRehydrator(aggregateType).getAggregate(id, create, toVersion);
  }

  /// Save a snapshot of the aggregate's current state
  Future<void> saveSnapshot(Aggregate aggregate) async {
    await _snapshotStore.saveSnapshot(
      aggregate.id,
      aggregate.type,
      aggregate.toJson(),
    );
  }

  /// Get the store for a specific aggregate type
  AggregateRehydrator _getRehydrator(String aggregateType) {
    final store = _rehydrators[aggregateType];
    if (store == null) {
      throw StateError(
          'No repository registered for aggregate type: $aggregateType');
    }
    return store;
  }
}

/// AggregateRepository is used to retrieve aggregates from the event store.
/// Note that it does not directly save aggregate state, as aggregates are
/// always produced by re-playing the events from the event store. However,
/// a snapshot store can be used to optimize the retrieval of aggregates by
/// allowing the store to retrieve the latest snapshot before re-playing
/// events.
class AggregateRehydrator<T extends Aggregate> {
  final EventStore _eventStore;
  final AggregateFactory<T> _factory;
  final SnapshotStore _snapshotStore;

  AggregateRehydrator(this._eventStore, this._factory, this._snapshotStore);

  /// Get an aggregate by its ID, using snapshots if available
  Future<T> getAggregate(ID id, bool create, int toVersion) async {
    // Try to get the latest snapshot if we have a snapshot store
    JsonMap? snapshot = await _snapshotStore.getLatestSnapshot(id);
    T aggregate = _factory(id);

    if (snapshot != null) {
      aggregate.deserializeState(snapshot);
    }

    int from = aggregate.version;
    if (from >= toVersion) {
      return aggregate;
    }

    // Get events from the event store
    final events = await _eventStore.getEvents(id, fromVersion: from).toList();
    if (events.isEmpty) {
      if (create) {
        return aggregate;
      }
      throw StateError('Aggregate not found: $id');
    }

    // Apply events to the aggregate
    for (final event in events) {
      if (event.version > toVersion) {
        break;
      }
      aggregate.applyEvent(event);
    }

    // Save a snapshot if we've applied events
    if (events.isNotEmpty) {
      await _snapshotStore.saveSnapshot(id, aggregate.type, aggregate.toJson());
    }
    return aggregate;
  }
}
