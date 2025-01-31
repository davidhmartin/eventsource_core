import 'event_store.dart';
import '../aggregate.dart';
import 'stores/null_snapshot_store.dart';
import '../typedefs.dart';
import '../event.dart';

abstract class AggregateStore<TAggregate extends Aggregate> {
  final EventStore _eventStore;
  final AggregateFactory<TAggregate> _createEmptyAggregate;
  final SnapshotStore<TAggregate> _snapshotStore;

  /// Create a new instance of the aggregate store
  ///
  /// [eventStore] The event store to use
  /// [createEmptyAggregate] Function to create empty aggregates
  /// [snapshotStore] Optional store to use for snapshots
  AggregateStore(this._eventStore, this._createEmptyAggregate,
      [SnapshotStore<TAggregate>? snapshotStore])
      : _snapshotStore = snapshotStore ?? NullSnapshotStore<TAggregate>();

  /// Get an aggregate by its ID, using snapshots if available
  Future<TAggregate> getAggregate(ID id, {int? toVersion}) async {
    // Try to get the latest snapshot if we have a snapshot store
    TAggregate? agg = await _snapshotStore.getLatestSnapshot(id);
    TAggregate aggregate = agg ?? _createEmptyAggregate(id);

    int to = toVersion ?? MAX_INT;
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

    events.forEach((event) {
      aggregate.applyEvent(event);
    }).then((_) {
      if (saveSnapshot) {
        _snapshotStore.saveSnapshot(aggregate);
      }
    });
    return aggregate;
  }
}

abstract class SnapshotStore<TAggregate extends Aggregate> {
  /// Save a snapshot
  Future<void> saveSnapshot(TAggregate aggregate);

  /// Get latest snapshot
  Future<TAggregate?> getLatestSnapshot(ID aggregateId);
}
