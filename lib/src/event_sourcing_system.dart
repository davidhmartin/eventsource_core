import 'package:eventsource_core/eventsource_core.dart';
import 'package:eventsource_core/src/aggregate_repository.dart';
import 'package:eventsource_core/typedefs.dart';
import 'package:eventsource_core/src/snapshot_store.dart';

/// A facade that provides a unified interface to the event sourcing system.
/// This is the primary entry point for applications using the event sourcing framework.
class EventSourcingSystem {
  final AggregateRepository _aggregateRepository;
  final CommandProcessor _commandProcessor;
  bool _isStarted = false;

  /// Create a new event sourcing system with the specified storage implementations.
  EventSourcingSystem({
    required EventStoreFactory eventStoreFactory,
    required SnapshotStore snapshotStore,
  }) : this._(eventStoreFactory, snapshotStore);

  EventSourcingSystem._(
    EventStoreFactory eventStoreFactory,
    SnapshotStore snapshotStore,
  ) : this.__(_createComponents(eventStoreFactory, snapshotStore));

  EventSourcingSystem.__(
    ({AggregateRepository repository, CommandProcessor processor}) components,
  )   : _aggregateRepository = components.repository,
        _commandProcessor = components.processor;

  static ({
    AggregateRepository repository,
    CommandProcessor processor,
  }) _createComponents(
    EventStoreFactory eventStoreFactory,
    SnapshotStore snapshotStore,
  ) {
    final eventStore = eventStoreFactory();
    final repository = AggregateRepository(eventStore, snapshotStore);
    final processor = CommandProcessor(eventStore, repository);
    return (repository: repository, processor: processor);
  }

  /// Register an aggregate type with the system
  void registerAggregate<T extends Aggregate>(AggregateFactory<T> factory) {
    _aggregateRepository.register<T>(factory);
  }

  /// Start processing commands.
  /// This must be called before any commands can be processed.
  Future<void> start() async {
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
  Stream<CommandLifecycleEvent> publish(Command command) {
    if (!_isStarted) {
      throw StateError(
          'EventSourcingSystem must be started before publishing commands');
    }
    return _commandProcessor.publish(command);
  }

  /// Get an aggregate by its ID and type
  Future<T> getAggregate<T extends Aggregate>(ID id, String type) {
    return _aggregateRepository.getAggregate(id, type) as Future<T>;
  }

  /// Wait for all currently queued commands to be processed
  Future<void> waitForCompletion() => _commandProcessor.waitForCompletion();
}
