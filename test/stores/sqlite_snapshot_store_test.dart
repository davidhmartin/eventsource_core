import 'dart:io';
import 'package:test/test.dart';
import 'package:eventsource_core/src/stores/sqlite_snapshot_store.dart';

void main() {
  late SqliteSnapshotStore<TestState> store;
  late String dbPath;

  setUp(() {
    dbPath = 'test_${DateTime.now().millisecondsSinceEpoch}.db';
    store = SqliteSnapshotStore<TestState>(
      dbPath,
      fromJson: TestState.fromJson,
      toJson: (state) => state.toJson(),
      defaultTStateValue: TestState('defaultName',
          0), // Provide a default TestState instance with required parameters
    );
  });

  tearDown(() {
    store.dispose();
    File(dbPath).deleteSync();
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

  test('should handle complex state serialization', () async {
    final aggregateId = 'test-3';
    final state = TestState(
      'Complex State',
      42,
      subStates: [
        TestSubState('Sub 1', true),
        TestSubState('Sub 2', false),
      ],
    );

    await store.saveSnapshot(aggregateId, state, 1);
    final result = await store.getLatestSnapshot(aggregateId);

    expect(result, isNotNull);
    final (retrievedState, _) = result!;
    expect(retrievedState.name, equals('Complex State'));
    expect(retrievedState.count, equals(42));
    expect(retrievedState.subStates?.length, equals(2));
    expect(retrievedState.subStates?[0].name, equals('Sub 1'));
    expect(retrievedState.subStates?[0].active, isTrue);
  });
}

class TestState {
  final String name;
  final int count;
  final List<TestSubState>? subStates;

  TestState(this.name, this.count, {this.subStates});

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
        'subStates': subStates?.map((s) => s.toJson()).toList(),
      };

  static TestState fromJson(Map<String, dynamic> json) => TestState(
        json['name'] as String,
        json['count'] as int,
        subStates: (json['subStates'] as List?)
            ?.map((e) => TestSubState.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TestSubState {
  final String name;
  final bool active;

  TestSubState(this.name, this.active);

  Map<String, dynamic> toJson() => {
        'name': name,
        'active': active,
      };

  static TestSubState fromJson(Map<String, dynamic> json) => TestSubState(
        json['name'] as String,
        json['active'] as bool,
      );
}
