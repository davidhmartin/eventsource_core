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
  String data;

  TestCommand({
    required ID aggregateId,
    required DateTime timestamp,
    required String origin,
    required this.data,
  }) : super(aggregateId, timestamp, origin);

  @override
  Event handle(Aggregate aggregate) {
    return TestEvent(
      id: aggregate.id,
      aggregateId: aggregateId,
      timestamp: timestamp,
      version: aggregate.version + 1,
      origin: origin,
      data: data,
    );
  }

  @override
  // TODO: implement type
  String get type => 'TestCommand';

  @override
  void deserializeState(JsonMap json) {
    data = json['data'] as String;
  }

  @override
  void serializeState(JsonMap json) {
    json['data'] = data;
  }
}

/// Test implementation of an aggregate
class TestAggregate extends Aggregate {
  String data = '';

  TestAggregate(ID id) : super(id);

  @override
  void applyEventToState(Event event) {
    if (event is TestEvent) {
      data = event.data;
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

  @override
  void deserializeState(JsonMap json) {
    data = json['data'] as String? ?? '';
  }

  @override
  void serializeState(JsonMap json) {
    json['data'] = data;
  }
}
