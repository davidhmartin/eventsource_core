import 'package:eventsource_core/aggregate.dart';
import 'package:eventsource_core/command.dart';
import 'package:eventsource_core/event.dart';
import 'package:eventsource_core/typedefs.dart';

/// Test implementation of an event
class TestEvent extends Event {
  String data;

  TestEvent({
    required ID id,
    required ID aggregateId,
    required DateTime timestamp,
    required int version,
    required String origin,
    required this.data,
  }) : super(id, aggregateId, timestamp, version, origin);

  @override
  void serializeState(JsonMap jsonMap) {
    jsonMap['data'] = data;
  }

  @override
  void deserializeState(JsonMap jsonMap) {
    data = jsonMap['data'] as String;
  }

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
  final String data;

  TestCommand(
    super._aggregateId,
    super._timestamp,
    super._origin,
    super._type, {
    required this.aggregateId,
    required this.timestamp,
    required this.origin,
    required this.data,
  }) : commandType = 'TestCommand';

  @override
  Map<String, dynamic> toJson() => {
        'aggregateId': aggregateId,
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
