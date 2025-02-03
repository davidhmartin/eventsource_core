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

  late String eventType;
  late String data;
  late String metadata;

  @Index()
  late int timestamp;

  @Index()
  late String origin;

  EventModel();

  factory EventModel.fromEvent(Event event) {
    return EventModel()
      ..eventId = event.id
      ..aggregateId = event.aggregateId
      ..version = event.version
      ..eventType = event.type
      ..data = jsonEncode(event.data)
      ..metadata = jsonEncode(event.metadata)
      ..timestamp = event.timestamp.millisecondsSinceEpoch
      ..origin = event.origin;
  }

  Event toEvent(EventDeserializer eventFactory) {
    final json = {
      'id': eventId,
      'aggregateId': aggregateId,
      'version': version,
      'eventType': eventType,
      'data': jsonDecode(data),
      'metadata': jsonDecode(metadata),
      'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
      'origin': origin,
    };
    return eventFactory(json);
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
