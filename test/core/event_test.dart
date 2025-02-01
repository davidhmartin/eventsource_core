import 'package:eventsource_core/typedefs.dart';
import 'package:test/test.dart';
import 'test_implementations.dart';

void main() {
  group('Event', () {
    final now = DateTime(2025);

    var eventId = newId();
    var aggregateId = newId();

    TestEvent _createTestEvent(int version) {
      return TestEvent(
        id: eventId,
        aggregateId: aggregateId,
        timestamp: now,
        version: version,
        origin: 'test',
        data: 'test-data',
      );
    }

    test('creates with correct values', () {
      var event = _createTestEvent(1);
      expect(event.id, equals(eventId));
      expect(event.aggregateId, equals(aggregateId));
      expect(event.timestamp, equals(now));
      expect(event.version, equals(1));
      expect(event.origin, equals('test'));
      expect(event.type, equals('TestEvent'));
      expect(event.data, equals('test-data'));
    });

    test('validates correctly', () {
      var event = _createTestEvent(1);
      expect(() => event.validate(), returnsNormally);
    });

    test('validates version greater than 0', () {
      expect(() => _createTestEvent(0), throwsArgumentError);
    });

    test('serializes to json correctly', () {
      var event = _createTestEvent(1);
      final json = event.toJson();
      expect(idFromString(json['id'].toString()), equals(eventId));
      expect(idFromString(json['aggregateId'].toString()), equals(aggregateId));
      expect(json['timestamp'], equals(now.toIso8601String()));
      expect(json['version'], equals(1));
      expect(json['origin'], equals('test'));
      expect(json['type'], equals('TestEvent'));
      expect(json['data'], equals('test-data'));
    });

    test('creates new version correctly', () {
      var event = _createTestEvent(1);
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
