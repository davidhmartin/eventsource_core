import 'package:eventsource_core/eventsource_core.dart';
import 'package:eventsource_core/src/stores/memory_event_store.dart';
import 'package:eventsource_core/src/stores/memory_snapshot_store.dart';
import 'package:eventsource_core/src/stores/sqlite_event_store.dart';
import 'package:eventsource_core/src/stores/sqlite_snapshot_store.dart';

/// Standard event store factories
class EventStores {
  /// Create an in-memory event store
  static EventStoreFactory memory = InMemoryEventStore.new;

  /// Create a SQLite event store at the specified path
  static EventStoreFactory sqlite(String path) =>
      () => SqliteEventStore(path, eventFactory: Event.fromJson);
}

/// Standard snapshot store factories
class SnapshotStores {
  /// Create an in-memory snapshot store
  static SnapshotStoreFactory memory = InMemorySnapshotStore.new;

  /// Create a SQLite snapshot store at the specified path
  static SnapshotStoreFactory sqlite(String path) =>
      () => SqliteSnapshotStore(path);
}
