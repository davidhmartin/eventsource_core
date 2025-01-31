import 'package:test/test.dart';
import 'test_implementations.dart';

void main() {
  group('Aggregate', () {
    late TestAggregate aggregate;
    final now = DateTime(2025);

    setUp(() {
      aggregate = TestAggregate('test-1');
    });

    test('initializes with correct id and version', () {
      expect(aggregate.id, equals('test-1'));
      expect(aggregate.version, equals(0));
    });

    test('applies single event correctly', () {
      final event = TestEvent(
        id: 'event-1',
        aggregateId: 'test-1',
        timestamp: now,
        version: 1,
        origin: 'test',
        data: 'test-data',
      );

      aggregate.applyEvent(event);

      expect(aggregate.version, equals(1));
    });

    test('applies multiple events in sequence', () {
      final events = [
        TestEvent(
          id: 'event-1',
          aggregateId: 'test-1',
          timestamp: now,
          version: 1,
          origin: 'test',
          data: 'data-1',
        ),
        TestEvent(
          id: 'event-2',
          aggregateId: 'test-1',
          timestamp: now,
          version: 2,
          origin: 'test',
          data: 'data-2',
        ),
      ];

      events.forEach(aggregate.applyEvent);

      expect(aggregate.version, equals(2));
      expect(aggregate.data, equals('data-2'));
    });

    test('throws on non-sequential version', () {
      final event = TestEvent(
        id: 'event-1',
        aggregateId: 'test-1',
        timestamp: now,
        version: 2, // Should be 1
        origin: 'test',
        data: 'test-data',
      );

      expect(
        () => aggregate.applyEvent(event),
        throwsArgumentError,
      );
    });

    test('throws on wrong aggregate id', () {
      final event = TestEvent(
        id: 'event-1',
        aggregateId: 'wrong-id',
        timestamp: now,
        version: 1,
        origin: 'test',
        data: 'test-data',
      );

      expect(
        () => aggregate.applyEvent(event),
        throwsArgumentError,
      );
    });

    test('loads from snapshot correctly', () {
      aggregate.loadFromSnapshot(5);

      expect(aggregate.version, equals(5));

      // Should be able to apply new events from snapshot version
      final event = TestEvent(
        id: 'event-1',
        aggregateId: 'test-1',
        timestamp: now,
        version: 6,
        origin: 'test',
        data: 'new-data',
      );

      aggregate.applyEvent(event);
      expect(aggregate.version, equals(6));
    });
  });
}
