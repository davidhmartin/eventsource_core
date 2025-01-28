/// Efficiently retrieves aggregates using snapshots and events
import '../event_store.dart';
import '../snapshot_store.dart';
import '../aggregate.dart';

abstract class AggregateStore<TAggregate extends Aggregate> {
  final EventStore _eventStore;
  final SnapshotStore<TAggregate>? _snapshotStore;

  AggregateStore(this._eventStore, [this._snapshotStore]);

  /// Get an aggregate by its ID, using snapshots if available
  Future<TAggregate?> getAggregate(String id) async {
    // Try to get the latest snapshot if we have a snapshot store
    TAggregate? aggregate;
    int fromVersion = 0;

    if (_snapshotStore != null) {
      final snapshot = await _snapshotStore.getLatestSnapshot(id);
      if (snapshot != null) {
        aggregate = snapshot.$1;
        fromVersion = snapshot.$2;
      }
    }

    // Get any events after the snapshot version
    final events = await _eventStore.getEvents(id, fromVersion: fromVersion);
    if (events.isEmpty && aggregate == null) {
      return null;
    }

    // Either create a new aggregate or apply events to snapshot
    aggregate ??= createEmptyAggregate(id);
    for (final event in events) {
      aggregate.applyEvent(event);
    }

    return aggregate;
  }

  /// Create a new empty aggregate with the given ID
  TAggregate createEmptyAggregate(String id);
}
