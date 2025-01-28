import 'package:test/test.dart';
import 'package:eventsource_core/stores/memory_snapshot_store.dart';

void main() {
  late InMemorySnapshotStore<TestState> store;

  setUp(() {
    store = InMemorySnapshotStore<TestState>();
  });

  test('should save and retrieve snapshot', () async {
    final aggregateId = 'test-1';
    final state = TestState('Test 1', 42);

    await store.saveSnapshot(aggregateId, state, 1);
    final result = await store.getLatestSnapshot(aggregateId);

    expect(result, isNotNull);
    final (retrievedState, version) = result!;
    expect(retrievedState.name, equals('Test 1'));
    expect(retrievedState.count, equals(42));
    expect(version, equals(1));
  });

  test('should return null for non-existent snapshot', () async {
    final result = await store.getLatestSnapshot('non-existent');
    expect(result, isNull);
  });

  test('should update existing snapshot', () async {
    final aggregateId = 'test-2';
    final initialState = TestState('Initial', 0);
    final updatedState = TestState('Updated', 1);

    await store.saveSnapshot(aggregateId, initialState, 1);
    await store.saveSnapshot(aggregateId, updatedState, 2);

    final result = await store.getLatestSnapshot(aggregateId);
    expect(result, isNotNull);

    final (state, version) = result!;
    expect(state.name, equals('Updated'));
    expect(state.count, equals(1));
    expect(version, equals(2));
  });
}

class TestState {
  final String name;
  final int count;

  TestState(this.name, this.count);
}
