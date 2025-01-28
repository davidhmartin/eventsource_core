import 'dart:io';
import 'package:test/test.dart';
import 'package:eventsource_core/src/stores/sqlite_event_store.dart';
import '../utils/test_event.dart';

void main() {
  late SqliteEventStore store;
  late String dbPath;

  setUp(() async {
    dbPath = 'test_${DateTime.now().millisecondsSinceEpoch}.db';
    store =
        await SqliteEventStore.create(dbPath, eventFactory: TestEvent.fromJson);
  });

  tearDown(() async {
    try {
      await store.dispose();
    } catch (e) {
      print('Error disposing store: $e');
    }

    // Add a small delay to ensure resources are released
    await Future.delayed(Duration(milliseconds: 100));

    try {
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error cleaning up test database: $e');
    }

    // Add another small delay after cleanup
    await Future.delayed(Duration(milliseconds: 100));
  });

  test('should append and retrieve events', () async {
    final aggregateId = 'test-1';
    final events = [
      TestEvent(
        id: 'evt-1',
        aggregateId: aggregateId,
        eventType: 'TestCreated',
        data: {'name': 'Test 1'},
        metadata: {'user': 'tester'},
        version: 0,
        timestamp: DateTime.now(),
        origin: 'test',
      ),
      TestEvent(
        id: 'evt-2',
        aggregateId: aggregateId,
        eventType: 'TestUpdated',
        data: {'name': 'Test 1 Updated'},
        metadata: {'user': 'tester'},
        version: 1,
        timestamp: DateTime.now(),
        origin: 'test',
      ),
    ];

    await store.appendEvents(aggregateId, events, 0);
    final retrieved = await store.getEvents(aggregateId);

    expect(retrieved.length, equals(2));
    expect((retrieved[0] as TestEvent).eventType, equals('TestCreated'));
    expect((retrieved[1] as TestEvent).eventType, equals('TestUpdated'));
    expect((retrieved[0] as TestEvent).data['name'], equals('Test 1'));
    expect((retrieved[1] as TestEvent).data['name'], equals('Test 1 Updated'));
  });

  test('should throw concurrency exception on version mismatch', () async {
    final aggregateId = 'test-2';
    final event = TestEvent(
      id: 'evt-3',
      aggregateId: aggregateId,
      eventType: 'TestCreated',
      data: {'name': 'Test 2'},
      metadata: {'user': 'tester'},
      version: 0,
      timestamp: DateTime.now(),
      origin: 'test',
    );

    await store.appendEvents(aggregateId, [event], 0);

    expect(
      () => store.appendEvents(aggregateId, [event], 0),
      throwsA(isA<ConcurrencyException>()),
    );
  });

  test('should filter events by version', () async {
    final aggregateId = 'test-3';
    final events = List.generate(
        3,
        (i) => TestEvent(
              id: 'evt-${4 + i}',
              aggregateId: aggregateId,
              eventType: 'TestEvent',
              data: {'index': i},
              metadata: {'user': 'tester'},
              version: i,
              timestamp: DateTime.now(),
              origin: 'test',
            ));

    await store.appendEvents(aggregateId, events, 0);
    final filtered = await store.getEvents(aggregateId, fromVersion: 1);

    expect(filtered.length, equals(2));
    expect(filtered.first.version, equals(1));
  });

  test('should handle JSON serialization correctly', () async {
    final aggregateId = 'test-4';
    final timestamp = DateTime.now();
    final event = TestEvent(
      id: 'evt-7',
      aggregateId: aggregateId,
      eventType: 'ComplexEvent',
      data: {
        'numbers': [1, 2, 3],
        'nested': {'key': 'value'},
        'nullValue': null,
      },
      metadata: {'timestamp': timestamp.toIso8601String()},
      version: 0,
      timestamp: timestamp,
      origin: 'test',
    );

    await store.appendEvents(aggregateId, [event], 0);
    final retrieved = await store.getEvents(aggregateId);

    expect(retrieved.length, equals(1));
    final retrievedEvent = retrieved[0] as TestEvent;
    expect(retrievedEvent.data['numbers'], equals([1, 2, 3]));
    expect(retrievedEvent.data['nested']['key'], equals('value'));
    expect(retrievedEvent.data['nullValue'], isNull);
    expect(retrievedEvent.metadata['timestamp'],
        equals(timestamp.toIso8601String()));
  });
}
