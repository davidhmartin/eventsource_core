import 'package:test/test.dart';
import 'test_implementations.dart';

void main() {
  group('Command', () {
    final now = DateTime(2025);
    late TestCommand command;

    setUp(() {
      command = TestCommand(
        id: 'test-1',
        userId: 'user-1',
        timestamp: now,
        origin: 'test',
        data: 'test-data',
      );
    });

    test('creates with correct values', () {
      expect(command.aggregateId, equals('test-1'));
      expect(command.userId, equals('user-1'));
      expect(command.timestamp, equals(now));
      expect(command.origin, equals('test'));
      expect(command.commandType, equals('TestCommand'));
      expect(command.data, equals('test-data'));
    });

    test('validates correctly', () {
      expect(() => command.validate(), returnsNormally);
    });

    test('validates aggregateId not empty', () {
      command = TestCommand(
        id: '',
        timestamp: now,
        origin: 'test',
        data: 'test-data',
      );
      expect(() => command.validate(), throwsArgumentError);
    });

    test('validates userId not empty', () {
      command = TestCommand(
        aggregateId: 'test-1',
        userId: '',
        timestamp: now,
        origin: 'test',
        data: 'test-data',
      );
      expect(() => command.validate(), throwsArgumentError);
    });

    test('validates origin not empty', () {
      command = TestCommand(
        aggregateId: 'test-1',
        userId: 'user-1',
        timestamp: now,
        origin: '',
        data: 'test-data',
      );
      expect(() => command.validate(), throwsArgumentError);
    });

    test('serializes to json correctly', () {
      final json = command.toJson();
      expect(json['aggregateId'], equals('test-1'));
      expect(json['userId'], equals('user-1'));
      expect(json['timestamp'], equals(now.toIso8601String()));
      expect(json['origin'], equals('test'));
      expect(json['commandType'], equals('TestCommand'));
      expect(json['data'], equals('test-data'));
    });
  });
}
