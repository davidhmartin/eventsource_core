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
  Future<void> saveSnapshot(Aggregate aggregate) async {
    return _lock.synchronized(() async {
      _snapshots[aggregate.id] = aggregate.toJson();
    });
  }

  @override
  Future<Aggregate?> getLatestSnapshot(ID aggregateId) async {
    return _lock.synchronized(() async {
      final json = _snapshots[aggregateId];
      if (json != null) {
        final state = Aggregate.fromJson(json);
        return Future.value(state);
      }
      return Future.value(null);
    });
  }
}
