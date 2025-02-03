import 'dart:io';
import 'package:eventsource_core/eventsource_core.dart';
import 'package:eventsource_core/src/stores/isar_event_store.dart';
import 'package:eventsource_core/src/stores/isar_snapshot_store.dart';
import 'package:eventsource_core/src/exceptions.dart';
import 'package:isar/isar.dart';
import 'package:test/test.dart';
import '../core/test_implementations.dart';

void main() {
  late Directory tempDir;
  late IsarEventStore eventStore;
  late IsarSnapshotStore snapshotStore;
  late AggregateRepository repository;

  setUpAll(() async {
    // Initialize Isar for Flutter environment
    await Isar.initializeIsarCore(download: true);
    // Register test event factory
    Event.registerFactory('TestEvent', (json) {
      return TestEvent(
        id: idFromString(json['id'] as String),
        aggregateId: idFromString(json['aggregateId'] as String),
        version: json['version'] as int,
        data: json['data'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        origin: json['origin'] as String,
      );
    });
  });

  setUp(() async {
    // Create a temporary directory for the test database
    tempDir = await Directory.systemTemp.createTemp('isar_test_');
    eventStore = await IsarEventStore.create(directory: tempDir.path);
    snapshotStore = await IsarSnapshotStore.create(directory: tempDir.path);
    repository = AggregateRepository(eventStore, snapshotStore)
      ..register((id) => TestAggregate(id));
  });

  tearDown(() async {
    await eventStore.dispose();
    await snapshotStore.dispose();
    await tempDir.delete(recursive: true);
  });

  test('Event store should store and retrieve events', () async {
    final aggregateId = 'test-1';
    final events = [
      TestEvent(
        id: newId(),
        aggregateId: aggregateId,
        version: 1,
        data: 'test1',
        timestamp: DateTime.now(),
        origin: 'test',
      ),
      TestEvent(
        id: newId(),
        aggregateId: aggregateId,
        version: 2,
        data: 'test2',
        timestamp: DateTime.now(),
        origin: 'test',
      ),
      TestEvent(
        id: newId(),
        aggregateId: aggregateId,
        version: 3,
        data: 'test3',
        timestamp: DateTime.now(),
        origin: 'test',
      ),
    ];

    // Store events
    await eventStore.appendEvents(aggregateId, events, -1);

    // Retrieve all events
    final retrievedEvents = await eventStore.getEvents(aggregateId).toList();
    expect(retrievedEvents.length, equals(3));
    expect(retrievedEvents[0].version, equals(1));
    expect(retrievedEvents[1].version, equals(2));
    expect(retrievedEvents[2].version, equals(3));
    expect((retrievedEvents[0] as TestEvent).data, equals('test1'));
    expect((retrievedEvents[1] as TestEvent).data, equals('test2'));
    expect((retrievedEvents[2] as TestEvent).data, equals('test3'));

    // Retrieve events from version 2
    final laterEvents =
        await eventStore.getEvents(aggregateId, fromVersion: 2).toList();
    expect(laterEvents.length, equals(2));
    expect(laterEvents[0].version, equals(2));
    expect(laterEvents[1].version, equals(3));

    // Retrieve events up to version 2
    final earlierEvents =
        await eventStore.getEvents(aggregateId, toVersion: 2).toList();
    expect(earlierEvents.length, equals(2));
    expect(earlierEvents[0].version, equals(1));
    expect(earlierEvents[1].version, equals(2));
  });

  test('Event store should enforce optimistic concurrency', () async {
    final aggregateId = 'test-2';
    final event = TestEvent(
      id: newId(),
      aggregateId: aggregateId,
      version: 1,
      data: 'test',
      timestamp: DateTime.now(),
      origin: 'test',
    );

    // Store first event
    await eventStore.appendEvents(aggregateId, [event], -1);

    // Try to store another event with wrong version
    expect(
      () => eventStore.appendEvents(aggregateId, [event], -1),
      throwsA(isA<ConcurrencyException>()),
    );
  });

  test('Snapshot store should store and retrieve snapshots', () async {
    final aggregateId = 'test-1';
    final aggregate = TestAggregate(aggregateId);

    // Apply some events to set the state and version
    final events = [
      TestEvent(
        id: newId(),
        aggregateId: aggregateId,
        version: 1,
        data: 'test1',
        timestamp: DateTime.now(),
        origin: 'test',
      ),
      TestEvent(
        id: newId(),
        aggregateId: aggregateId,
        version: 2,
        data: 'test2',
        timestamp: DateTime.now(),
        origin: 'test',
      ),
    ];

    for (final event in events) {
      aggregate.applyEvent(event);
    }

    // Store snapshot
    await repository.saveSnapshot(aggregate);

    // Retrieve snapshot
    final retrievedAggregate = await repository.getAggregate(
      aggregateId,
      'TestAggregate',
      create: true,
    );
    expect(retrievedAggregate, isNotNull);
    expect(retrievedAggregate.id, equals(aggregateId));
    expect(retrievedAggregate.version, equals(2));
    expect((retrievedAggregate as TestAggregate).data, equals('test2'));
  });
}
