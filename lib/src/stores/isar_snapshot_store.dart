import 'package:eventsource_core/typedefs.dart';
import 'package:isar/isar.dart';
import '../snapshot_store.dart';
import 'isar/snapshot_model.dart';

/// Isar implementation of SnapshotStore
class IsarSnapshotStore implements SnapshotStore {
  final Isar _isar;

  IsarSnapshotStore._(this._isar);

  static Future<IsarSnapshotStore> create({String? directory}) async {
    final isar = await Isar.open(
      [SnapshotModelSchema],
      directory: directory ?? '.',
    );
    return IsarSnapshotStore._(isar);
  }

  @override
  Future<void> saveSnapshot(ID aggregateId, String type, JsonMap state) async {
    final snapshot = SnapshotModel.create(aggregateId, type, state);
    await _isar.writeTxn(() async {
      await _isar.snapshotModels.put(snapshot);
    });
  }

  @override
  Future<JsonMap?> getLatestSnapshot(ID aggregateId) async {
    final snapshot = await _isar.snapshotModels
        .where()
        .aggregateIdEqualTo(aggregateId)
        .findFirst();
    return snapshot?.toJson();
  }

  Future<void> dispose() async {
    await _isar.close();
  }
}
