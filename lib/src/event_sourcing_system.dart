import 'package:eventsource_core/eventsource_core.dart';

/// A facade that provides a unified interface to the event sourcing system.
/// This is the primary entry point for applications using the event sourcing framework.
class EventSourcingSystem {
  late final AggregateRepository _aggregateRepository;
  late final CommandProcessor _commandProcessor;
  bool _isStarted = false;
  late final Future<void> _initialized;

  /// Create a new event sourcing system with the specified storage implementations.
  EventSourcingSystem(EventStoreFactory eventStoreFactory,
      SnapshotStoreFactory snapshotStoreFactory) {
    _initialized =
        _initializeComponents(eventStoreFactory, snapshotStoreFactory);
  }

  /// Returns a Future that completes when the system is fully initialized
  Future<void> get initialized => _initialized;

  Future<void> _initializeComponents(
    EventStoreFactory eventStoreFactory,
    SnapshotStoreFactory snapshotStoreFactory,
  ) async {
    final components =
        await _createComponents(eventStoreFactory, snapshotStoreFactory);
    _aggregateRepository = components.repository;
    _commandProcessor = components.processor;
  }

  static Future<
      ({
        AggregateRepository repository,
        CommandProcessor processor,
      })> _createComponents(
    EventStoreFactory eventStoreFactory,
    SnapshotStoreFactory snapshotStoreFactory,
  ) async {
    final eventStore = await eventStoreFactory();
    final snapshotStore = await snapshotStoreFactory();
    final repository = AggregateRepository(eventStore, snapshotStore);
    final processor = CommandProcessor(eventStore, repository);
    return (repository: repository, processor: processor);
  }

  /// Register an aggregate type with the system
  Future<void> registerAggregate<T extends Aggregate>(
      AggregateFactory<T> factory) async {
    await _initialized;
    _aggregateRepository.register<T>(factory);
  }

  /// Start processing commands.
  /// This must be called before any commands can be processed.
  Future<void> start() async {
    await _initialized; // Ensure initialization is complete
    if (!_isStarted) {
      await _commandProcessor.start();
      _isStarted = true;
    }
  }

  /// Stop processing commands and clean up resources.
  Future<void> stop() async {
    if (_isStarted) {
      await _commandProcessor.stop();
      _isStarted = false;
    }
  }

  /// Submit a command for processing and track its lifecycle.
  /// Returns a stream of events that track the command's progress:
  /// 1. CommandPublished - When the command is initially received
  /// 2. CommandHandled - When command handling is complete
  /// 3. EventPublished - When the generated event is stored
  /// 4. ReadModelUpdated - When the read model is updated (if applicable)
  Stream<CommandLifecycleEvent> publish(Command command) async* {
    await _initialized; // Ensure initialization is complete
    if (!_isStarted) {
      throw StateError(
          'EventSourcingSystem must be started before publishing commands');
    }
    yield* _commandProcessor.publish(command);
  }

  /// Get an aggregate by its ID and type
  Future<T> getAggregate<T extends Aggregate>(ID id, String type) async {
    await _initialized; // Ensure initialization is complete
    return _aggregateRepository.getAggregate(id, type) as Future<T>;
  }

  /// Wait for all currently queued commands to be processed
  Future<void> waitForCompletion() => _commandProcessor.waitForCompletion();
}
