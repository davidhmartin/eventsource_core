import 'package:eventsource_core/event.dart';
import 'package:eventsource_core/src/stores/isar_event_store.dart';
import 'package:eventsource_core/src/stores/isar_snapshot_store.dart';
import '../event_store.dart';
import '../snapshot_store.dart';

/// Factory function for creating an EventStore
typedef EventStoreFactory = Future<EventStore> Function();

/// Factory function for creating a SnapshotStore
typedef SnapshotStoreFactory = Future<SnapshotStore> Function();

/// Create an event store factory for the specified database type
EventStoreFactory createEventStoreFactory(String path) {
  return () => IsarEventStore.create(directory: path);
}

/// Create a snapshot store factory for the specified database type
SnapshotStoreFactory createSnapshotStoreFactory(String path) {
  return () => IsarSnapshotStore.create(directory: path);
}
