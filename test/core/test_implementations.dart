import 'package:eventsource_core/aggregate.dart';
import 'package:eventsource_core/command.dart';
import 'package:eventsource_core/event.dart';

/// Test implementation of an event
class TestEvent extends Event {
  @override
  final String id;

  @override
  final String aggregateId;

  @override
  final DateTime timestamp;

  @override
  final int version;

  @override
  final String origin;

  @override
  final String eventType;

  final String data;

  TestEvent({
    required this.id,
    required this.aggregateId,
    required this.timestamp,
    required this.version,
    required this.origin,
    required this.data,
  }) : eventType = 'TestEvent';

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'aggregateId': aggregateId,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'origin': origin,
        'eventType': eventType,
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
  String get streamId => aggregateId;

  @override
  String get streamType => 'TestStream';
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

  TestCommand({
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
}

/// Test implementation of an aggregate state
class TestState {
  final List<String> appliedData;

  TestState([this.appliedData = const []]);

  TestState addData(String data) => TestState([...appliedData, data]);
}

/// Test implementation of an aggregate
class TestAggregate extends Aggregate<TestState> {
  TestAggregate(String id) : super(id);

  @override
  void applyEventToState(Event event) {
    if (event is TestEvent) {
      state = state.addData(event.data);
    }
  }

  @override
  TestState createEmptyState() {
    return TestState();
  }
}
