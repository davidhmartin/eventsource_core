import 'package:eventsource_core/typedefs.dart';

import '../snapshot_store.dart';

/// A snapshot store that does nothing. Used when no snapshot store is provided.
class NullSnapshotStore implements SnapshotStore {
  const NullSnapshotStore();

  @override
  Future<void> saveSnapshot(ID aggregateId, String type, JsonMap state) async {
    // Do nothing
  }

  @override
  Future<JsonMap?> getLatestSnapshot(ID aggregateId) async {
    return null;
  }
}
