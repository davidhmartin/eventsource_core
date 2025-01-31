import 'package:eventsource_core/src/aggregate_store.dart';

import '../../aggregate.dart';

class NullSnapshotStore<TAggregate extends Aggregate>
    implements SnapshotStore<TAggregate> {
  @override
  Future<void> saveSnapshot(TAggregate aggregate) async {
    // Do nothing
  }

  @override
  Future<TAggregate?> getLatestSnapshot(String aggregateId) async {
    return Future.value(null);
  }
}
