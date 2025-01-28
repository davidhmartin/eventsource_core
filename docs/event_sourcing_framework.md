# Event Sourcing Framework Design Document

## Overview
This document outlines the design for a Dart-based event sourcing framework that provides the core building blocks for implementing event sourcing in applications. The framework aims to be flexible, extensible, and framework-agnostic while providing a robust foundation for event-sourced systems.

## Core Concepts

### 1. Events
Events are immutable records of facts that have occurred in the system. They represent state transitions and are the source of truth for the system's state.

```dart
/// Base interface for all events
abstract class Event {
  /// Unique identifier for the event
  String get id;
  
  /// ID of the aggregate this event belongs to
  String get aggregateId;
  
  /// When the event occurred
  DateTime get timestamp;
  
  /// Sequence number within the aggregate
  int get version;
  
  /// Origin system/component that generated the event
  String get origin;
  
  /// Convert event to JSON for persistence
  Map<String, dynamic> toJson();
}
```

### 2. Commands
Commands represent user intentions and are used to validate and process requests for state changes. 

```dart
/// Base interface for all commands
abstract class Command {
  /// ID of the aggregate this command belongs to
  String get aggregateId;

  /// ID of the user issuing the command
  String get userId;
  
  /// When the command was issued
  DateTime get timestamp;
  
  /// Origin system/component that issued the command
  String get origin;
}
```

### 3. Aggregates
Aggregates are the consistency boundaries for the domain model, ensuring that business rules are enforced.

```dart
/// Base class for all aggregates
abstract class Aggregate<TState> {
  /// ID of this aggregate
  String get id;

  /// Current version (last applied event sequence number)
  int get version;
  
  /// Current state of the aggregate
  TState get state;

  /// Apply an event to the aggregate by mutating the state
  void applyEvent(Event event);
}
```

### 4. Event Store
The event store is responsible for persisting and retrieving events. It is the source of truth for the system's state.

```dart
/// Interface for event storage
abstract class EventStore {
  /// Append events to the store
  Future<void> appendEvents(String aggregateId, List<Event> events, int expectedVersion);
  
  /// Get events from an aggregate specified by ID. 
  /// [fromVersion] - start from this version (inclusive). Omitting fromVersion retrieves all events.
  /// [origin] - filter by origin system/component
  /// [filter] - filter events based on a predicate
  Future<List<Event>> getEvents(String aggregateId, {int? fromVersion, String? origin, bool Function(Event)? filter});
}
```

### 5. Snapshot Store
The snapshot store provides optional optimization for aggregate retrieval by storing aggregate state at specific versions.

```dart
/// Interface for snapshot storage
abstract class SnapshotStore<TState> {
  /// Save a snapshot
  Future<void> saveSnapshot(String aggregateId, TState state, int version);
  
  /// Get latest snapshot
  Future<(TState, int)?> getLatestSnapshot(String aggregateId);
}
```

### 6. Aggregate Store
The aggregate store efficiently retrieves aggregates using a combination of snapshots and events.

```dart
/// Efficiently retrieves aggregates using snapshots and events
abstract class AggregateStore<TAggregate extends Aggregate> {
  final EventStore _eventStore;
  final SnapshotStore<TAggregate>? _snapshotStore;
  
  AggregateStore(this._eventStore, [this._snapshotStore]);

  /// Get an aggregate by its ID, using snapshots if available
  Future<TAggregate?> getAggregate(String id) async {
    // Try to get the latest snapshot if we have a snapshot store
    TAggregate? aggregate;
    int fromVersion = 0;
    
    if (_snapshotStore != null) {
      final snapshot = await _snapshotStore.getLatestSnapshot(id);
      if (snapshot != null) {
        aggregate = snapshot.$1;
        fromVersion = snapshot.$2;
      }
    }
    
    // Get any events after the snapshot version
    final events = await _eventStore.getEvents(id, fromVersion: fromVersion);
    if (events.isEmpty && aggregate == null) {
      return null;
    }
    
    // Either create a new aggregate or apply events to snapshot
    aggregate ??= createEmptyAggregate(id);
    for (final event in events) {
      aggregate.applyEvent(event);
    }
    
    return aggregate;
  }

  /// Create a new empty aggregate with the given ID
  TAggregate createEmptyAggregate(String id);
}
```

### 7. Command Handlers
Command handlers validate commands against the current aggregate state and produce resulting events.

```dart
/// Base interface for command handlers
abstract class CommandHandler<TCommand extends Command, TAggregate extends Aggregate> {
  /// Validates the command against current state and produces resulting event
  /// Returns null if command results in no state change
  /// Throws ValidationError if command is invalid
  Event? handle(TCommand command, TAggregate aggregate);
}

// Example implementation
class CreateBoxCommandHandler implements CommandHandler<CreateBoxCommand, Box> {
  @override
  Event? handle(CreateBoxCommand command, Box box) {
    // Validate command against current state
    if (box.state.isArchived) {
      throw ValidationError('Cannot modify an archived box');
    }
    
    // If valid, return the event
    return BoxCreatedEvent(
      aggregateId: box.id,
      name: command.name,
      // ...other fields
    );
  }
}

class CommandProcessor {
  final EventStore _eventStore;
  final AggregateStore _aggregateStore;
  final Map<Type, CommandHandler> _handlers;
  final CommandQueue _queue;

  /// Submit a command for processing
  Future<void> submit(Command command) => _queue.enqueue(command);

  /// Internal method to process a single command
  Future<void> process(Command command) async {
    final handler = _handlers[command.runtimeType];
    
    final aggregate = await _aggregateStore.getAggregate(command.aggregateId) 
        ?? _createNewAggregate(command.aggregateId);
    
    final event = handler.handle(command, aggregate);
    
    if (event != null) {
      await _eventStore.appendEvents(aggregate.id, [event], aggregate.version);
    }
  }
}

### 8. Command Queue
The command queue ensures commands for each aggregate are processed serially while allowing parallel processing across different aggregates.

```dart
/// In-memory queue for processing commands
abstract class CommandQueue {
  /// Enqueue a command for processing
  /// Returns a Future that completes when the command has been processed
  Future<void> enqueue(Command command);
}

/// Default implementation using per-aggregate queues
class DefaultCommandQueue implements CommandQueue {
  final CommandProcessor _processor;
  final Map<String, Queue<Command>> _queues = {};
  final Map<String, Future<void>> _processing = {};

  @override
  Future<void> enqueue(Command command) async {
    final aggregateId = command.aggregateId;
    
    // Get or create queue for this aggregate
    _queues.putIfAbsent(aggregateId, () => Queue<Command>());
    _queues[aggregateId]!.add(command);
    
    // If no processing is happening for this aggregate, start it
    if (!_processing.containsKey(aggregateId)) {
      _processing[aggregateId] = _processQueue(aggregateId);
    }
    
    // Wait for all commands ahead of this one
    await _processing[aggregateId];
  }
  
  Future<void> _processQueue(String aggregateId) async {
    try {
      while (_queues[aggregateId]!.isNotEmpty) {
        final command = _queues[aggregateId]!.removeFirst();
        await _processor.process(command);
      }
    } finally {
      _queues.remove(aggregateId);
      _processing.remove(aggregateId);
    }
  }
}

## Framework Features

### 1. Event Store Implementations
The framework will provide:
- In-memory event store (for testing)
- SQL-based event store
- Interface for custom implementations

### 2. Snapshot Store Implementations
The framework will provide:
- In-memory snapshot store (for testing)
- SQL-based snapshot store
- Interface for custom implementations

### 3. Event Bus
```dart
/// Event publication and subscription
abstract class EventBus {
  /// Publish an event
  Future<void> publish(Event event);
  
  /// Subscribe to events
  Stream<Event> subscribe<TEvent extends Event>();
}
```

### 4. Optimistic Concurrency
Built-in support for detecting and handling concurrent modifications through version checking in the EventStore.

### 5. Event Versioning
Support for event schema evolution and versioning.

### 6. Validation Framework
```dart
/// Validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
}

/// Validation context
class ValidationContext {
  Future<bool> exists(String aggregateId);
  Future<bool> isUnique(String field, String value);
}
```

## Usage Example

```dart
// Define an aggregate
class UserAggregate extends Aggregate<UserState> {
  @override
  void applyEvent(Event event) {
    if (event is UserCreatedEvent) {
      _state = UserState(event.userId, event.name, event.email);
    }
  }
}

// Define a command handler
class CreateUserCommandHandler extends CommandHandler<CreateUserCommand, UserAggregate> {
  @override
  Event? handle(CreateUserCommand command, UserAggregate aggregate) {
    // Check if user exists
    final existing = await _aggregateStore.getAggregate(command.userId);
    if (existing != null) {
      throw ValidationError('User already exists');
    }
    
    // Generate and store events
    final events = [UserCreatedEvent(...)];
    await _eventStore.appendEvents(command.userId, events, 0);
  }
}
```

## Implementation Guidelines

### 1. Error Handling
- Clear error types for different failure scenarios
- Consistent error handling patterns
- Error recovery mechanisms

### 2. Testing Support
- Test helpers and utilities
- Mock implementations
- Testing best practices

### 3. Performance Considerations
- Efficient event storage and retrieval
- Snapshot strategies
- Caching recommendations

### 4. Security
- Event encryption support
- Audit logging
- Access control patterns

## Framework Extension Points

### 1. Custom Event Stores
Instructions for implementing custom event storage solutions.

### 2. Custom Serialization
Support for different serialization formats and strategies.

### 3. Middleware
Hook points for adding cross-cutting concerns:
- Logging
- Metrics
- Authorization
- Custom behaviors

## Package Structure
```
lib/
  ├── src/
  │   ├── aggregates/
  │   ├── commands/
  │   ├── events/
  │   ├── repositories/
  │   ├── storage/
  │   ├── validation/
  │   └── bus/
  └── event_sourcing.dart
```

## Dependencies
- json_serializable: For JSON serialization
- meta: For annotations
- uuid: For unique identifiers
- clock: For testable time dependencies

## Future Considerations

### 1. Event Upcasting
Support for evolving event schemas over time.

### 2. Event Store Partitioning
Guidelines for handling large event stores.

### 3. Read Models
Support for efficient read-side projections.

### 4. Distributed Systems
- Event store clustering
- Distributed command handling
- Eventual consistency patterns

## Migration Guide
Instructions for migrating existing event-sourced systems to this framework.

## Best Practices
- Event design guidelines
- Aggregate design patterns
- Command validation patterns
- Testing strategies
- Performance optimization tips

This design document serves as a blueprint for implementing the event sourcing framework. It provides a solid foundation while remaining flexible enough to accommodate various use cases and implementation details.
