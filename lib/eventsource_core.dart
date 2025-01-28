/// A lightweight, flexible event sourcing framework for Dart.
library eventsource_core;

// Core interfaces
export 'aggregate.dart';
export 'command.dart';
export 'event.dart';
export 'event_store.dart';
export 'snapshot_store.dart';

// Implementations
export 'src/aggregate_store.dart';
export 'src/command_queue.dart';
export 'src/command_processor.dart';
