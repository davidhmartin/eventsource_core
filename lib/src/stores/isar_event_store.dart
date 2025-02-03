import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import '../../event.dart';
import '../../typedefs.dart';
import '../event_store.dart';
import '../event_subscription.dart';
import '../exceptions.dart';
import '../lock.dart';
import 'isar/event_model.dart';

/// Isar implementation of EventStore
class IsarEventStore implements EventStore {
  final Isar _isar;
  final _lock = Lock();
  final EventDeserializer _eventFactory;
  final List<EventSubscriber> _subscribers = [];

  IsarEventStore._(this._isar, {EventDeserializer? eventFactory})
      : _eventFactory = eventFactory ?? Event.fromJson;

  static Future<IsarEventStore> create(
      {String? directory, EventDeserializer? eventFactory}) async {
    final dir = directory ?? path.join(Directory.systemTemp.path, 'eventsource');
    final isar = await Isar.open(
      [EventModelSchema],
      directory: dir,
    );
    return IsarEventStore._(isar, eventFactory: eventFactory);
  }

  Future<int> _getCurrentVersion(ID aggregateId) async {
    final lastEvent = await _isar.eventModels
        .filter()
        .aggregateIdEqualTo(aggregateId)
        .sortByVersionDesc()
        .findFirst();
    return lastEvent?.version ?? -1;
  }

  @override
  Future<void> appendEvents(
      ID aggregateId, List<Event> events, int expectedVersion) async {
    return _lock.synchronized(() async {
      final currentVersion = await _getCurrentVersion(aggregateId);
      if (currentVersion != expectedVersion) {
        throw ConcurrencyException(
            'Expected version $expectedVersion but found $currentVersion');
      }

      await _isar.writeTxn(() async {
        for (final event in events) {
          final model = EventModel.fromEvent(event);
          await _isar.eventModels.put(model);
          for (final subscriber in _subscribers) {
            subscriber.onEvent(event);
          }
        }
      });
    });
  }

  @override
  Stream<Event> getEvents(ID aggregateId,
      {int? fromVersion, int? toVersion, String? origin, bool Function(Event)? filter}) async* {
    var query = _isar.eventModels.filter().aggregateIdEqualTo(aggregateId);

    if (fromVersion != null) {
      query = query.versionGreaterThan(fromVersion, include: true);
    }
    if (toVersion != null) {
      query = query.versionLessThan(toVersion, include: true);
    }
    if (origin != null) {
      query = query.originEqualTo(origin);
    }

    final models = await query.sortByVersion().findAll();
    for (final model in models) {
      final event = model.toEvent(_eventFactory);
      if (filter == null || filter(event)) {
        yield event;
      }
    }
  }

  @override
  void registerSubscriber(EventSubscriber subscriber) {
    _subscribers.add(subscriber);
  }

  Future<void> dispose() async {
    await _isar.close();
  }
}
