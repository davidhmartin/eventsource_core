import '../aggregate.dart';
import '../typedefs.dart';
import 'event_store.dart';
import 'stores/null_snapshot_store.dart';

typedef SnapshotStoreFactory = SnapshotStore Function();

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
    final tempAggregate = factory(ID());
    final aggregateType = tempAggregate.type;

    _factories[aggregateType] = factory;
    _rehydrators[aggregateType] =
        AggregateRehydrator<T>(_eventStore, factory, _snapshotStore);
    return this;
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
class AggregateRehydrator<TAggregate extends Aggregate> {
  final EventStore _eventStore;
  final AggregateFactory<TAggregate> _createEmptyAggregate;
  final SnapshotStore _snapshotStore;

  /// Create a new instance of the aggregate repository
  ///
  /// [eventStore] The event store to use
  /// [createEmptyAggregate] Function to create empty aggregates
  /// [snapshotStore] Optional store to use for snapshots
  AggregateRehydrator(this._eventStore, this._createEmptyAggregate,
      [SnapshotStore? snapshotStore])
      : _snapshotStore = snapshotStore ?? NullSnapshotStore();

  /// Get an aggregate by its ID, using snapshots if available
  Future<Aggregate> getAggregate(ID id, bool create, int toVersion) async {
    // todo do we need "create" at all?

    if (toVersion == 0) {
      return _createEmptyAggregate(id);
    }
    create ??= false;
    // Try to get the latest snapshot if we have a snapshot store
    Aggregate? agg = await _snapshotStore.getLatestSnapshot(id);
    Aggregate aggregate = agg ?? _createEmptyAggregate(id);

    int to = toVersion ?? maxInt;
    int from = aggregate.version;

    if (to == from) {
      return aggregate;
    }

    bool saveSnapshot;

    if (to < from) {
      // The caller has asked for a version of the aggregate, from prior to the
      // snapshot's version. In this case, we need to re-create the aggregate
      // from version 0 up to the requested version.
      aggregate = _createEmptyAggregate(id);
      from = 0;
      saveSnapshot = false; // Don't save a snapshot of the re-created aggregate
    } else {
      saveSnapshot = true;
    }

    // Get any events after the snapshot version
    final events =
        _eventStore.getEvents(id, fromVersion: from + 1, toVersion: to);

    await for (final event in events) {
      aggregate.applyEvent(event);
    }

    if (saveSnapshot) {
      await _snapshotStore.saveSnapshot(aggregate);
    }
    return aggregate;
  }

  /// Create a new empty aggregate with the given ID
  //TAggregate createEmptyAggregate(ID id) => _createEmptyAggregate(id);
}

// SnapshotStore is used by AggregateStore to store and retrieve aggregate
// snapshots.
abstract class SnapshotStore {
  /// Save a snapshot
  Future<void> saveSnapshot(Aggregate aggregate);

  /// Get latest snapshot
  Future<Aggregate?> getLatestSnapshot(ID aggregateId);
}
