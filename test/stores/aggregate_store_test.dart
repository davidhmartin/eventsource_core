import 'package:test/test.dart';
import 'package:eventsource_core/stores/aggregate_store.dart';
import 'package:eventsource_core/stores/memory_event_store.dart';
import 'package:eventsource_core/stores/memory_snapshot_store.dart';
import '../core/test_implementations.dart';
import 'package:eventsource_core/event.dart';
import 'package:eventsource_core/event_store.dart';
import 'package:eventsource_core/snapshot_store.dart';

void main() {
  group('DefaultAggregateStore', () {
    late MockEventStore eventStore;
    late MockSnapshotStore snapshotStore;
    late DefaultAggregateStore<TestAggregate, TestState> store;
    final now = DateTime(2025);

    TestAggregate createAggregate(String id) => TestAggregate(id);

    setUp(() {
      eventStore = MockEventStore();
      snapshotStore = MockSnapshotStore();
      store = DefaultAggregateStore<TestAggregate, TestState>(
        eventStore,
        createAggregate,
        snapshotStore: snapshotStore,
        snapshotFrequency: 2,
      );
    });

    test('loads new aggregate when no events exist', () async {
      eventStore.events = [];
      snapshotStore.snapshot = null;

      final aggregate = await store.getAggregate('test-1');
      expect(aggregate, isNull);
    });

    test('loads aggregate from events without snapshot', () async {
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
      eventStore.events = events;
      snapshotStore.snapshot = null;

      final aggregate = await store.getAggregate('test-1');
      expect(aggregate, isNotNull);
      expect(aggregate!.version, equals(2));
      expect(aggregate.state.appliedData, equals(['data-1', 'data-2']));
    });

    test('loads aggregate from snapshot and events', () async {
      final existingState = TestState(['existing']);
      snapshotStore.snapshot = (existingState, 1);

      final events = [
        TestEvent(
          id: 'event-2',
          aggregateId: 'test-1',
          timestamp: now,
          version: 2,
          origin: 'test',
          data: 'new-data',
        ),
      ];
      eventStore.events = events;

      final aggregate = await store.getAggregate('test-1');
      expect(aggregate, isNotNull);
      expect(aggregate!.version, equals(2));
      expect(
        aggregate.state.appliedData,
        equals(['existing', 'new-data']),
      );
    });

    test('saves uncommitted events', () async {
      final aggregate = TestAggregate('test-1');
      final event = TestEvent(
        id: 'event-1',
        aggregateId: 'test-1',
        timestamp: now,
        version: 1,
        origin: 'test',
        data: 'test-data',
      );
      aggregate.applyEvent(event);

      await store.save(aggregate);

      expect(eventStore.savedEvents, equals([event]));
      expect(aggregate.uncommittedEvents, isEmpty);
    });

    test('creates snapshot at frequency', () async {
      final aggregate = TestAggregate('test-1');
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

      for (final event in events) {
        aggregate.applyEvent(event);
      }

      await store.save(aggregate);

      expect(snapshotStore.savedSnapshot, isNotNull);
      expect(snapshotStore.savedVersion, equals(2));
      expect(
        (snapshotStore.savedSnapshot as TestState).appliedData,
        equals(['data-1', 'data-2']),
      );
    });
  });
}

class MockEventStore implements EventStore {
  List<Event> events = [];
  List<Event>? savedEvents;
  String? savedAggregateId;
  int? expectedVersion;

  @override
  Future<void> appendEvents(
      String aggregateId, List<Event> events, int expectedVersion) async {
    savedEvents = events;
    savedAggregateId = aggregateId;
    this.expectedVersion = expectedVersion;
  }

  @override
  Future<List<Event>> getEvents(String aggregateId,
      {int? fromVersion, String? origin, bool Function(Event)? filter}) async {
    if (fromVersion != null) {
      return events.where((e) => e.version > fromVersion).toList();
    }
    return events;
  }
}

class MockSnapshotStore implements SnapshotStore<TestState> {
  (TestState, int)? snapshot;
  TestState? savedSnapshot;
  String? savedAggregateId;
  int? savedVersion;

  @override
  Future<(TestState, int)?> getLatestSnapshot(String aggregateId) async {
    return snapshot;
  }

  @override
  Future<void> saveSnapshot(String aggregateId, TestState snapshot, int version) async {
    savedSnapshot = snapshot;
    savedAggregateId = aggregateId;
    savedVersion = version;
  }
}
