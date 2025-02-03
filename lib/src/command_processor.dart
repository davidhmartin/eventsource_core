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
  final CommandQueue _queue = CommandQueue();
  final CommandLifecycleRegistry _lifecycleRegistry;

  StreamSubscription? _subscription;
  bool _isProcessing = false;
  final _processingCompleter = Completer<void>();

  CommandProcessor(
    this._eventStore,
    this._aggregates,
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
    final commandId = command.hashCode.toString(); // Use same ID as process
    final controller = StreamController<CommandLifecycleEvent>();

    // Emit initial event
    controller.add(CommandPublished(
      commandId: commandId,
      command: command,
    ));

    () async {
      try {
        final manager = await _lifecycleRegistry.getManager(commandId, command);

        // Start processing the command
        submit(command).then((_) {
          // Command completed successfully
        }).catchError((Object error, StackTrace stackTrace) {
          manager.notifyFailed(error, stackTrace);
          _lifecycleRegistry.removeManager(commandId);
        });

        // // Subscribe to manager's stream first
        // final subscription = manager.stream.listen(
        //   (event) {
        //     print('Forwarding event: ${event.runtimeType}');
        //     if (event is CommandLifecycleEvent) {
        //       controller.add(event);
        //     } else {
        //       print('Unexpected event type: ${event.runtimeType}');
        //     }
        //   },
        //   onError: (Object error, StackTrace stackTrace) {
        //     print('Error in manager stream: $error\n$stackTrace');
        //     controller.addError(error, stackTrace);
        //   },
        //   onDone: () {
        //     print('Manager stream done');
        //     controller.close();
        //   },
        // );

        // // Then start processing the command
        // await submit(command);
      } catch (error, stackTrace) {
        print('Error in publish: $error\n$stackTrace');
        final manager = await _lifecycleRegistry.getManager(commandId, command);
        await manager.notifyFailed(error, stackTrace);
        await _lifecycleRegistry.removeManager(commandId);
        controller.close();
      }
    }();

    return controller.stream;
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
      onError: (Object error, StackTrace stackTrace) {
        print('Error in command stream: $error\n$stackTrace');
        _processingCompleter.completeError(error, stackTrace);
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
    final commandId = command.hashCode.toString(); // Simple ID for existing commands
    final manager = await _lifecycleRegistry.getManager(commandId, command);

    try {
      print('Processing command: ${command.type}');
      
      // Get or create the aggregate based on the command's create flag
      Aggregate aggregate;
      if (command.create) {
        aggregate = await _aggregates.createAggregate(command.aggregateId, command.aggregateType);
      } else {
        aggregate = await _aggregates.getAggregate(command.aggregateId, command.aggregateType);
      }
      print('Got aggregate: ${aggregate.id}');

      final event = command.handle(aggregate);
      print('Generated event: ${event?.type}');
      await manager.notifyHandled(event);
      print('Notified handled');

      if (event != null) {
        await _eventStore.appendEvents(aggregate.id, [event], aggregate.version);
        await manager.notifyEventPublished(event);
        print('Notified event published');

        // TODO: When read model projection is implemented:
        // await _projectionHandler.handleEvent(event);
        // manager.notifyReadModelUpdated(event);
      }

      await _lifecycleRegistry.removeManager(commandId);
      print('Removed lifecycle manager');
    } catch (error, stackTrace) {
      print('Error processing command: $error\n$stackTrace');
      await manager.notifyFailed(error, stackTrace);
      await _lifecycleRegistry.removeManager(commandId);
      rethrow;
    }
  }
}
