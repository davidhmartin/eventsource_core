/// A lightweight, flexible event sourcing framework for Dart.
library eventsource_core;

// Core interfaces
export 'aggregate.dart';
export 'command.dart';
export 'event.dart';
// Implementations
export 'src/aggregate_repository.dart';
export 'src/command_processor.dart';
export 'src/command_queue.dart';
export 'src/event_store.dart';
