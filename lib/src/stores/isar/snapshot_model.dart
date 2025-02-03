import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../typedefs.dart';

part 'snapshot_model.g.dart';

@Collection()
class SnapshotModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String aggregateId;

  @Index()
  late String type;

  late String state;
  late int version;

  SnapshotModel();

  factory SnapshotModel.create(String aggregateId, String type, JsonMap state) {
    return SnapshotModel()
      ..aggregateId = aggregateId
      ..type = type
      ..state = jsonEncode(state)
      ..version = state['version'] as int;
  }

  JsonMap toJson() {
    return jsonDecode(state) as JsonMap;
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
