import 'dart:async';
import '../command.dart';
import 'command_queue.dart';
import '../event_store.dart';
import 'aggregate_store.dart';
import '../command_handler.dart';

/// Exception thrown when a command handler is not found
class HandlerNotFoundException implements Exception {
  final Type commandType;
  HandlerNotFoundException(this.commandType);

  @override
  String toString() => 'No handler found for command type: $commandType';
}

/// Exception thrown when command processing fails
class CommandProcessingException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  CommandProcessingException(this.message, [this.error, this.stackTrace]);

  @override
  String toString() =>
      'Command processing failed: $message${error != null ? '\nCaused by: $error' : ''}';
}

/// Processes commands asynchronously with error handling and retries
class CommandProcessor {
  final EventStore _eventStore;
  final AggregateStore _aggregateStore;
  final Map<Type, CommandHandler> _handlers;
  final CommandQueue _queue;

  StreamSubscription? _subscription;
  bool _isProcessing = false;
  final _processingCompleter = Completer<void>();

  CommandProcessor(
      this._eventStore, this._aggregateStore, this._handlers, this._queue);

  /// Submit a command for processing
  Future<void> submit(Command command) => _queue.enqueue(command);

  /// Start processing commands asynchronously
  Future<void> start() async {
    if (_isProcessing) return;

    _isProcessing = true;
    _subscription = _queue.commandStream.listen(_processWithRetry,
        onError: (error, stackTrace) {
      print('Error in command stream: $error');
      print(stackTrace);
    });
  }

  /// Stop processing commands
  Future<void> stop() async {
    _isProcessing = false;
    await _subscription?.cancel();
    _subscription = null;
    if (!_processingCompleter.isCompleted) {
      _processingCompleter.complete();
    }
  }

  /// Process a command with retries on transient failures
  Future<void> _processWithRetry(Command command, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        await _process(command);
        return;
      } catch (e, stackTrace) {
        attempts++;
        if (attempts >= maxRetries) {
          throw CommandProcessingException(
              'Failed to process command after $maxRetries attempts',
              e,
              stackTrace);
        }
        // Wait before retrying, with exponential backoff
        await Future.delayed(Duration(milliseconds: 100 * (1 << attempts)));
      }
    }
  }

  /// Internal method to process a single command
  Future<void> _process(Command command) async {
    final handler = _handlers[command.runtimeType];
    if (handler == null) {
      throw HandlerNotFoundException(command.runtimeType);
    }

    try {
      final aggregate = await _aggregateStore.getAggregate(command.aggregateId);
      if (aggregate == null) {
        throw CommandProcessingException(
            'Aggregate not found: ${command.aggregateId}');
      }

      final event = handler.handle(command, aggregate);
      if (event != null) {
        await _eventStore.appendEvents(
            aggregate.id, [event], aggregate.version);
      }
    } catch (e, stackTrace) {
      if (e is HandlerNotFoundException || e is CommandProcessingException) {
        rethrow;
      }
      throw CommandProcessingException(
          'Error processing command', e, stackTrace);
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await stop();
    await _queue.dispose();
  }
}
