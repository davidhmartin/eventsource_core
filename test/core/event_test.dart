import 'package:test/test.dart';
import 'test_implementations.dart';

void main() {
  group('Event', () {
    final now = DateTime(2025);
    late TestEvent event;

    setUp(() {
      event = TestEvent(
        id: 'event-1',
        aggregateId: 'test-1',
        timestamp: now,
        version: 1,
        origin: 'test',
        data: 'test-data',
      );
    });

    test('creates with correct values', () {
      expect(event.id, equals('event-1'));
      expect(event.aggregateId, equals('test-1'));
      expect(event.timestamp, equals(now));
      expect(event.version, equals(1));
      expect(event.origin, equals('test'));
      expect(event.type, equals('TestEvent'));
      expect(event.data, equals('test-data'));
    });

    test('validates correctly', () {
      expect(() => event.validate(), returnsNormally);
    });

    test('validates id not empty', () {
      event = TestEvent(
        id: '',
        aggregateId: 'test-1',
        timestamp: now,
        version: 1,
        origin: 'test',
        data: 'test-data',
      );
      expect(() => event.validate(), throwsArgumentError);
    });

    test('validates aggregateId not empty', () {
      event = TestEvent(
        id: 'event-1',
        aggregateId: '',
        timestamp: now,
        version: 1,
        origin: 'test',
        data: 'test-data',
      );
      expect(() => event.validate(), throwsArgumentError);
    });

    test('validates version greater than 0', () {
      event = TestEvent(
        id: 'event-1',
        aggregateId: 'test-1',
        timestamp: now,
        version: 0,
        origin: 'test',
        data: 'test-data',
      );
      expect(() => event.validate(), throwsArgumentError);
    });

    test('validates origin not empty', () {
      event = TestEvent(
        id: 'event-1',
        aggregateId: 'test-1',
        timestamp: now,
        version: 1,
        origin: '',
        data: 'test-data',
      );
      expect(() => event.validate(), throwsArgumentError);
    });

    test('serializes to json correctly', () {
      final json = event.toJson();
      expect(json['id'], equals('event-1'));
      expect(json['aggregateId'], equals('test-1'));
      expect(json['timestamp'], equals(now.toIso8601String()));
      expect(json['version'], equals(1));
      expect(json['origin'], equals('test'));
      expect(json['eventType'], equals('TestEvent'));
      expect(json['data'], equals('test-data'));
    });

    test('creates new version correctly', () {
      final newEvent = event.withVersion(2) as TestEvent;
      expect(newEvent.version, equals(2));
      // Other fields should remain the same
      expect(newEvent.id, equals(event.id));
      expect(newEvent.aggregateId, equals(event.aggregateId));
      expect(newEvent.timestamp, equals(event.timestamp));
      expect(newEvent.origin, equals(event.origin));
      expect(newEvent.data, equals(event.data));
    });
  });
}
