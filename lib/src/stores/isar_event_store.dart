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
  final List<EventSubscriber> _subscribers = [];

  IsarEventStore._(this._isar);

  static Future<IsarEventStore> create({String? directory}) async {
    final dir = directory ?? Directory.systemTemp.path;
    final isar = await Isar.open(
      [EventModelSchema],
      directory: dir,
      name: 'events',
    );
    return IsarEventStore._(isar);
  }

  @override
  Future<void> appendEvents(ID aggregateId, List<Event> events, int expectedVersion) async {
    await _lock.synchronized(() async {
      // Get the latest version for this aggregate
      final latestEvent = await _isar.eventModels
          .filter()
          .aggregateIdEqualTo(aggregateId.toString())
          .sortByVersionDesc()
          .findFirst();

      final currentVersion = latestEvent?.version ?? -1;
      if (currentVersion != expectedVersion) {
        throw ConcurrencyException(
            'Expected version $expectedVersion but found $currentVersion');
      }

      // Convert events to models and store them
      await _isar.writeTxn(() async {
        for (final event in events) {
          final model = EventModel.fromEvent(event);
          await _isar.eventModels.put(model);
          
          // Notify subscribers
          for (final subscriber in _subscribers) {
            subscriber.onEvent(event);
          }
        }
      });
    });
  }

  @override
  Stream<Event> getEvents(ID aggregateId,
      {int? fromVersion,
      int? toVersion,
      String? origin,
      bool Function(Event)? filter}) async* {
    // Build the query
    var query = _isar.eventModels
        .filter()
        .aggregateIdEqualTo(aggregateId.toString());

    if (fromVersion != null) {
      query = query.versionGreaterThan(fromVersion, include: true);
    }
    if (toVersion != null) {
      query = query.versionLessThan(toVersion, include: true);
    }
    if (origin != null) {
      query = query.originEqualTo(origin);
    }

    // Execute query and get results
    final models = await query.sortByVersion().findAll();
    for (final model in models) {
      final event = model.toEvent();
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
