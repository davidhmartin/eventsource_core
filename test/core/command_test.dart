import 'package:eventsource_core/typedefs.dart';
import 'package:test/test.dart';
import 'test_implementations.dart';

void main() {
  group('Command', () {
    final now = DateTime(2025);
    late TestCommand command;

    var aggregateId = newId();

    setUp(() {
      command = TestCommand(
        aggregateId: aggregateId,
        timestamp: now,
        origin: 'test',
        data: 'test-data',
      );
    });

    test('creates with correct values', () {
      expect(command.aggregateId, equals(aggregateId));
      expect(command.timestamp, equals(now));
      expect(command.origin, equals('test'));
      expect(command.type, equals('TestCommand'));
      expect(command.data, equals('test-data'));
    });

    test('validates correctly', () {
      expect(() => command.validate(), returnsNormally);
    });

    test('serializes to json correctly', () {
      final json = command.toJson();
      expect(idFromString(json['aggregateId'].toString()), equals(aggregateId));
      expect(json['timestamp'], equals(now.toIso8601String()));
      expect(json['origin'], equals('test'));
      expect(json['type'], equals('TestCommand'));
      expect(json['data'], equals('test-data'));
    });
  });
}
