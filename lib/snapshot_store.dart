/// Interface for snapshot storage
abstract class SnapshotStore<TState> {
  /// Save a snapshot
  Future<void> saveSnapshot(String aggregateId, TState state, int version);
  
  /// Get latest snapshot
  Future<(TState, int)?> getLatestSnapshot(String aggregateId);
}
