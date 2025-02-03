import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import '../../aggregate.dart';
import '../../typedefs.dart';
import '../aggregate_repository.dart';
import '../lock.dart';
import 'isar/snapshot_model.dart';

/// Isar implementation of SnapshotStore
class IsarSnapshotStore implements SnapshotStore {
  final Isar _isar;
  final _lock = Lock();

  IsarSnapshotStore._(this._isar);

  static Future<IsarSnapshotStore> create({String? directory}) async {
    final dir = directory ?? path.join(Directory.systemTemp.path, 'eventsource');
    final isar = await Isar.open(
      [SnapshotModelSchema],
      directory: dir,
    );
    return IsarSnapshotStore._(isar);
  }

  @override
  Future<Aggregate?> getLatestSnapshot(ID aggregateId) async {
    return await _lock.synchronized(() async {
      final model = await _isar.snapshotModels.get(fastHash(aggregateId));
      return model?.toAggregate();
    });
  }

  @override
  Future<void> saveSnapshot(Aggregate aggregate) async {
    await _lock.synchronized(() async {
      final model = SnapshotModel.fromAggregate(aggregate);
      await _isar.writeTxn(() async {
        await _isar.snapshotModels.put(model);
      });
    });
  }

  Future<void> dispose() async {
    await _isar.close();
  }
}
