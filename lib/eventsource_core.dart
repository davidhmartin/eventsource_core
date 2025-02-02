/// Core event sourcing functionality
library eventsource_core;

// Core abstractions
export 'aggregate.dart';
export 'command.dart';
export 'event.dart';
// Implementations
export 'src/aggregate_repository.dart' show AggregateRepository, SnapshotStoreFactory;
export 'src/command_processor.dart' show CommandProcessor;
export 'src/event_store.dart' show EventStore;
export 'src/event_sourcing_system.dart' show EventSourcingSystem;
export 'src/stores/store_factories.dart' show EventStores, SnapshotStores;
export 'typedefs.dart';
