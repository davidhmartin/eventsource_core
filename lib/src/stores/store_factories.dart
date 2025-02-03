import 'package:eventsource_core/src/stores/isar_event_store.dart';
import 'package:eventsource_core/src/stores/isar_snapshot_store.dart';
import 'package:eventsource_core/src/stores/memory_event_store.dart';
import 'package:eventsource_core/src/stores/memory_snapshot_store.dart';
import 'package:eventsource_core/src/stores/null_snapshot_store.dart';
import 'package:eventsource_core/typedefs.dart';

/// Create an event store factory for the specified database type
EventStoreFactory isarEventStoreFactory(String path) {
  return () async => IsarEventStore.create(directory: path);
}

/// Create a snapshot store factory for the specified database type
SnapshotStoreFactory isarSnapshotStoreFactory(String path) {
  return () async => IsarSnapshotStore.create(directory: path);
}

/// Create an in-memory event store factory
EventStoreFactory inMemoryEventStoreFactory() {
  return () => Future.value(InMemoryEventStore());
}

/// Create an in-memory snapshot store factory
SnapshotStoreFactory inMemorySnapshotStoreFactory() {
  return () => Future.value(InMemorySnapshotStore());
}

/// Create a null snapshot store factory
SnapshotStoreFactory nullSnapshotStoreFactory() {
  return () => Future.value(NullSnapshotStore());
}
