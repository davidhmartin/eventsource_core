import 'dart:collection';

import 'package:eventsource_core/typedefs.dart';

import '../../aggregate.dart';
import '../aggregate_repository.dart';
import '../lock.dart';

/// In-memory implementation of SnapshotStore.
class InMemorySnapshotStore implements SnapshotStore {
  final _snapshots = HashMap<ID, JsonMap>();
  final _lock = Lock();

  @override
  Future<void> saveSnapshot(ID aggregateId, String type, JsonMap state) async {
    return _lock.synchronized(() async {
      _snapshots[aggregateId] = state;
    });
  }

  @override
  Future<JsonMap?> getLatestSnapshot(ID aggregateId) async {
    return _lock.synchronized(() async {
      return Future.value(_snapshots[aggregateId]);
    });
  }
}
