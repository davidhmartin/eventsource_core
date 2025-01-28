import 'dart:async';
import '../command.dart';
import 'lock.dart';

/// A thread-safe queue for processing commands asynchronously
class CommandQueue {
  final _commandController = StreamController<Command>.broadcast();
  final _queue = List<Command>.empty(growable: true);
  final _lock = Lock();
  bool _isProcessing = false;

  /// Get the stream of commands
  Stream<Command> get commandStream => _commandController.stream;

  /// Enqueue a command for processing
  Future<void> enqueue(Command command) async {
    await _lock.synchronized(() async {
      _queue.add(command);
      _commandController.add(command);
    });
  }

  /// Dequeue the next command if available
  Future<Command?> dequeue() async {
    return _lock.synchronized(() async {
      if (_queue.isEmpty) {
        return null;
      }
      return _queue.removeAt(0);
    });
  }

  /// Checks if the queue is empty
  Future<bool> get isEmpty async {
    return _lock.synchronized(() async => _queue.isEmpty);
  }

  /// Get the current size of the queue
  Future<int> get size async {
    return _lock.synchronized(() async => _queue.length);
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _commandController.close();
  }
}
