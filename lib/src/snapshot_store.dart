import '../typedefs.dart';

/// Interface for storing and retrieving aggregate snapshots
abstract class SnapshotStore {
  /// Save a snapshot of an aggregate's state
  Future<void> saveSnapshot(ID aggregateId, String type, JsonMap state);

  /// Get the latest snapshot for an aggregate
  Future<JsonMap?> getLatestSnapshot(ID aggregateId);
}
