import 'dart:collection';
import '../../snapshot_store.dart';
import '../lock.dart';

/// In-memory implementation of SnapshotStore
class InMemorySnapshotStore<TState> implements SnapshotStore<TState> {
  final _snapshots = HashMap<String, (TState, int)>();
  final _lock = Lock();

  @override
  Future<void> saveSnapshot(
      String aggregateId, TState state, int version) async {
    return _lock.synchronized(() async {
      _snapshots[aggregateId] = (state, version);
    });
  }

  @override
  Future<(TState, int)?> getLatestSnapshot(String aggregateId) async {
    return _lock.synchronized(() async {
      return _snapshots[aggregateId];
    });
  }
}
