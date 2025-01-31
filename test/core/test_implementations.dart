import 'package:eventsource_core/aggregate.dart';
import 'package:eventsource_core/command.dart';
import 'package:eventsource_core/event.dart';

/// Test implementation of an event
class TestEvent extends Event {
  final String data;

  TestEvent({
    required String id,
    required String aggregateId,
    required DateTime timestamp,
    required int version,
    required String origin,
    required this.data,
  }) : super(id, aggregateId, timestamp, version, origin);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'aggregateId': aggregateId,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'origin': origin,
        'type': type,
        'data': data,
      };

  @override
  void validate() {
    super.validate();
  }

  @override
  Event withVersion(int newVersion) {
    return TestEvent(
      id: id,
      aggregateId: aggregateId,
      timestamp: timestamp,
      version: newVersion,
      origin: origin,
      data: data,
    );
  }

  @override
  String get type => 'TestEvent';
}

/// Test implementation of a command
class TestCommand extends Command {
  @override
  final String aggregateId;

  @override
  final String userId;

  @override
  final DateTime timestamp;

  @override
  final String origin;

  @override
  final String commandType;

  final String data;

  TestCommand(
    super._aggregateId,
    super._userId,
    super._timestamp,
    super._origin,
    super._type, {
    required this.aggregateId,
    required this.userId,
    required this.timestamp,
    required this.origin,
    required this.data,
  }) : commandType = 'TestCommand';

  @override
  Map<String, dynamic> toJson() => {
        'aggregateId': aggregateId,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'origin': origin,
        'commandType': commandType,
        'data': data,
      };

  @override
  Event handle(Aggregate aggregate) {
    return TestEvent(
      id: aggregate.id,
      aggregateId: aggregateId,
      timestamp: timestamp,
      version: 1,
      origin: origin,
      data: data,
    );
  }
}

/// Test implementation of an aggregate state
class TestState {
  final List<String> appliedData;

  TestState([this.appliedData = const []]);

  TestState addData(String data) => TestState([...appliedData, data]);
}

/// Test implementation of an aggregate
class TestAggregate extends Aggregate {
  TestAggregate(String id) : super(id);

  @override
  void applyEventToState(Event event) {
    if (event is TestEvent) {
      // Update state handling as needed
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
    };
  }

  @override
  String get type => 'TestAggregate';
}
