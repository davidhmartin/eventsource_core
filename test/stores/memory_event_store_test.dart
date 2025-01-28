import 'package:test/test.dart';
import 'package:eventsource_core/src/stores/memory_event_store.dart';
import '../utils/test_event.dart';

void main() {
  late InMemoryEventStore store;

  setUp(() {
    store = InMemoryEventStore();
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

  test('should filter events by origin', () async {
    final aggregateId = 'test-4';
    final events = [
      TestEvent(
        id: 'evt-7',
        aggregateId: aggregateId,
        eventType: 'TestEvent',
        data: {'name': 'Test'},
        metadata: {'user': 'tester'},
        version: 0,
        timestamp: DateTime.now(),
        origin: 'system-a',
      ),
      TestEvent(
        id: 'evt-8',
        aggregateId: aggregateId,
        eventType: 'TestEvent',
        data: {'name': 'Test'},
        metadata: {'user': 'tester'},
        version: 1,
        timestamp: DateTime.now(),
        origin: 'system-b',
      ),
    ];

    await store.appendEvents(aggregateId, events, 0);
    final filtered = await store.getEvents(aggregateId, origin: 'system-a');

    expect(filtered.length, equals(1));
    expect(filtered.first.origin, equals('system-a'));
  });
}
