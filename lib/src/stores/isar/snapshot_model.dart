import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../aggregate.dart';

part 'snapshot_model.g.dart';

@Collection()
class SnapshotModel {
  Id? id;

  @Index(unique: true, replace: true)
  late String aggregateId;

  @Index()
  late String type;

  late String state;
  late int version;

  SnapshotModel();

  factory SnapshotModel.fromAggregate(Aggregate aggregate) {
    return SnapshotModel()
      ..id = Id(fastHash(aggregate.id))
      ..aggregateId = aggregate.id
      ..type = aggregate.type
      ..state = jsonEncode(aggregate.toJson())
      ..version = aggregate.version;
  }

  Aggregate toAggregate() {
    final jsonMap = jsonDecode(state) as Map<String, dynamic>;
    return Aggregate.fromJson(jsonMap);
  }
}

// FNV-1a 64bit hash function
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
