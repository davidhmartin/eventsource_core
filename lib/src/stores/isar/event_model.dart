import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../event.dart';
import '../../../typedefs.dart';

part 'event_model.g.dart';

@Collection()
class EventModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  @Index()
  late String aggregateId;

  @Index()
  late int version;

  @Index()
  late String type;

  @Index()
  late int timestamp;

  @Index()
  late String origin;

  /// The complete serialized event
  late String eventJson;

  EventModel();

  factory EventModel.fromEvent(Event event) {
    final json = event.toJson();
    return EventModel()
      ..eventId = event.id.toString()
      ..aggregateId = event.aggregateId.toString()
      ..version = event.version
      ..type = event.type
      ..timestamp = event.timestamp.millisecondsSinceEpoch
      ..origin = event.origin
      ..eventJson = jsonEncode(json);
  }

  Event toEvent() {
    final json = jsonDecode(eventJson) as JsonMap;
    return Event.fromJson(json);
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
