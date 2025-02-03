import 'dart:io';
import 'package:eventsource_core/event.dart';
import 'package:eventsource_core/aggregate.dart';
import 'package:eventsource_core/src/stores/isar_event_store.dart';
import 'package:eventsource_core/src/stores/isar_snapshot_store.dart';
import 'package:eventsource_core/typedefs.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late IsarEventStore eventStore;
  late IsarSnapshotStore snapshotStore;

  setUp(() async {
    // Create a temporary directory for the test database
    tempDir = await Directory.systemTemp.createTemp('isar_test_');
    eventStore = await IsarEventStore.create(directory: tempDir.path);
    snapshotStore = await IsarSnapshotStore.create(directory: tempDir.path);

    // Register test event factory
    Event.registerFactory('TestEvent', TestEvent.fromJson);
    // Register test aggregate factory
    Aggregate.registerFactory('TestAggregate', TestAggregate.fromJson);
  });

  tearDown(() async {
    await eventStore.dispose();
    await snapshotStore.dispose();
    await tempDir.delete(recursive: true);
  });

  test('Event store should store and retrieve events', () async {
    final aggregateId = 'test-1';
    final events = [
      TestEvent(
        id: newId().toString(),
        aggregateId: aggregateId,
        version: 0,
        value: 'test1',
        metadata: {'user': 'tester'},
        timestamp: DateTime.now(),
        origin: 'test',
      ),
      TestEvent(
        id: newId().toString(),
        aggregateId: aggregateId,
        version: 1,
        value: 'test2',
        metadata: {'user': 'tester'},
        timestamp: DateTime.now(),
        origin: 'test',
      ),
    ];

    // Store events
    await eventStore.appendEvents(aggregateId, events, -1);

    // Retrieve events
    final retrievedEvents = await eventStore.getEvents(aggregateId).toList();
    expect(retrievedEvents.length, equals(2));
    expect(retrievedEvents[0].version, equals(0));
    expect(retrievedEvents[1].version, equals(1));
    expect((retrievedEvents[0] as TestEvent).value, equals('test1'));
    expect((retrievedEvents[1] as TestEvent).value, equals('test2'));
  });

  test('Snapshot store should store and retrieve snapshots', () async {
    final aggregateId = 'test-1';
    final aggregate = TestAggregate(id: aggregateId);
    
    // Apply some events to set the state and version
    final events = [
      TestEvent(
        id: newId().toString(),
        aggregateId: aggregateId,
        version: 1,
        value: 'test-value',
        metadata: {'user': 'tester'},
        timestamp: DateTime.now(),
        origin: 'test',
      ),
    ];
    
    for (final event in events) {
      aggregate.applyEvent(event);
    }

    // Store snapshot
    await snapshotStore.saveSnapshot(aggregate);

    // Retrieve snapshot
    final retrievedSnapshot = await snapshotStore.getLatestSnapshot(aggregateId);
    expect(retrievedSnapshot, isNotNull);
    expect(retrievedSnapshot!.id, equals(aggregateId));
    expect(retrievedSnapshot.version, equals(1));
    expect((retrievedSnapshot as TestAggregate).value, equals('test-value'));
  });
}

class TestEvent extends Event {
  final String value;
  final Map<String, dynamic> _metadata;

  TestEvent({
    required String id,
    required String aggregateId,
    required int version,
    required this.value,
    required Map<String, dynamic> metadata,
    required DateTime timestamp,
    required String origin,
  })  : _metadata = metadata,
        super(id, aggregateId, timestamp, version, origin);

  @override
  String get type => 'TestEvent';

  @override
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);

  factory TestEvent.fromJson(JsonMap json) {
    return TestEvent(
      id: json['id'] as String,
      aggregateId: json['aggregateId'] as String,
      version: json['version'] as int,
      value: json['data']['value'] as String,
      metadata: json['metadata'] as JsonMap,
      timestamp: DateTime.parse(json['timestamp'].toString()),
      origin: json['origin'] as String,
    );
  }

  @override
  void serializeState(JsonMap json) {
    json['value'] = value;
  }

  @override
  void deserializeState(JsonMap json) {
    // No need to implement since we use the factory constructor
  }

  @override
  void validate() {
    // Allow version 0 in tests
  }

  @override
  Event withVersion(int newVersion) {
    return TestEvent(
      id: id.toString(),
      aggregateId: aggregateId.toString(),
      version: newVersion,
      value: value,
      metadata: Map.from(_metadata),
      timestamp: timestamp,
      origin: origin,
    );
  }
}

class TestAggregate extends Aggregate {
  String? _value;

  TestAggregate({required String id}) : super(id);

  String get value => _value ?? '';

  @override
  String get type => 'TestAggregate';

  @override
  void applyEventToState(Event event) {
    if (event is TestEvent) {
      _value = event.value;
    }
  }

  @override
  void serializeState(JsonMap json) {
    json['value'] = value;
  }

  @override
  void deserializeState(JsonMap json) {
    _value = json['value'] as String?;
  }

  factory TestAggregate.fromJson(JsonMap json) {
    final aggregate = TestAggregate(id: json['id'] as String);
    aggregate.deserializeState(json);
    return aggregate;
  }
}
