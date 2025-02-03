import 'package:eventsource_core/src/aggregate_repository.dart';
import 'package:eventsource_core/typedefs.dart';

import '../../aggregate.dart';

// Snapshotting the aggregate is an optimization, as the aggregate can always be
// rehydrated from the event store. Using an AggregateStore with a null SnapshotStore
// will result in the aggregate being rehydrated from the event store every time
// an aggregate is requested.
class NullSnapshotStore implements SnapshotStore {
  @override
  Future<void> saveSnapshot(Aggregate aggregate) async {
    // Do nothing
  }

  @override
  Future<Aggregate?> getLatestSnapshot(ID aggregateId) async {
    return Future.value(null);
  }
}
