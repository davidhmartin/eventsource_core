import 'dart:async';

import 'package:eventsource_core/aggregate.dart';

import '../command.dart';
import '../event.dart';
import '../typedefs.dart';
import 'command_queue.dart';
import 'event_store.dart';
import 'aggregate_repository.dart';
import 'command_lifecycle.dart';
import 'command_lifecycle_manager.dart';

/// Exception thrown when a command handler is not found
class HandlerNotFoundException implements Exception {
  final Type commandType;

  HandlerNotFoundException(this.commandType);

  @override
  String toString() => 'No handler found for command type: $commandType';
}

/// Exception thrown when an aggregate is not found
class AggregateNotFoundException implements Exception {
  final ID aggregateId;

  AggregateNotFoundException(this.aggregateId);

  @override
  String toString() => 'Aggregate not found: $aggregateId';
}

/// Processes commands and maintains command state
class CommandProcessor {
  final EventStore _eventStore;
  final AggregateRepository _aggregates;
  final CommandQueue _queue;
  final CommandLifecycleRegistry _lifecycleRegistry;

  StreamSubscription? _subscription;
  bool _isProcessing = false;
  final _processingCompleter = Completer<void>();

  CommandProcessor(
    this._eventStore,
    this._aggregates,
    this._queue,
  ) : _lifecycleRegistry = CommandLifecycleRegistry();

  /// Submit a command for processing
  Future<void> submit(Command command) => _queue.enqueue(command);

  /// Publish a command. This is called by the application to submit a
  /// command to the system. The command will be processed asynchronously.
  ///
  /// Returns a stream of [CommandLifecycleEvent]s that can be used to track
  /// the progress of command processing. The stream will emit events in the
  /// following order:
  /// 1. [CommandPublished] - When the command is initially received
  /// 2. [CommandHandled] - When command handling is complete
  /// 3. [EventPublished] - When the generated event is stored
  /// 4. [ReadModelUpdated] - When the read model is updated
  ///
  /// If an error occurs at any point, a [CommandFailed] event will be emitted
  /// and the stream will complete.
  Stream<CommandLifecycleEvent> publish(Command command) {
    final commandId = DateTime.now().toIso8601String(); // Simple ID generation
    final manager = _lifecycleRegistry.getManager(commandId, command);

    // Start processing the command
    submit(command).then((_) {
      // Command completed successfully
    }).catchError((Object error, StackTrace stackTrace) {
      manager.notifyFailed(error, stackTrace);
      _lifecycleRegistry.removeManager(commandId);
    });

    // Return the lifecycle event stream
    return manager.stream;
  }

  /// Start processing commands asynchronously
  Future<void> start() async {
    if (_isProcessing) return;
    _isProcessing = true;

    _subscription = _queue.commandStream.listen(
      (command) => _process(command).onError((error, stackTrace) {
        // Log error but continue processing
        print('Error processing command: $error\n$stackTrace');
      }),
      onError: (Object error) {
        print('Error in command stream: $error');
        _processingCompleter.completeError(error);
      },
      onDone: () {
        _isProcessing = false;
        _processingCompleter.complete();
      },
    );
  }

  /// Stop processing commands
  Future<void> stop() async {
    if (!_isProcessing) return;
    await _subscription?.cancel();
    _subscription = null;
    await _processingCompleter.future;
  }

  /// Wait for all commands to be processed
  Future<void> waitForCompletion() => _processingCompleter.future;

  /// Internal method to process a single command
  Future<void> _process(Command command) async {
    final commandId =
        command.hashCode.toString(); // Simple ID for existing commands
    final manager = _lifecycleRegistry.getManager(commandId, command);

    try {
      Aggregate? aggregate = await _aggregates.getAggregate(
          command.aggregateId, command.aggregateType);

      final event = command.handle(aggregate);
      manager.notifyHandled(event);

      if (event != null) {
        await _eventStore.appendEvents(
            aggregate.id, [event], aggregate.version);
        manager.notifyEventPublished(event);

        // TODO: When read model projection is implemented:
        // await _projectionHandler.handleEvent(event);
        // manager.notifyReadModelUpdated(event);
      }

      _lifecycleRegistry.removeManager(commandId);
    } catch (error, stackTrace) {
      manager.notifyFailed(error, stackTrace);
      _lifecycleRegistry.removeManager(commandId);
      rethrow;
    }
  }
}
