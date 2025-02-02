import 'dart:async';
import 'package:synchronized/synchronized.dart';

import '../command.dart';
import '../event.dart';
import 'command_lifecycle.dart';

/// Manages the lifecycle events for a single command
class CommandLifecycleManager {
  final String commandId;
  final Command command;
  final _controller = StreamController<CommandLifecycleEvent>.broadcast();
  bool _isComplete = false;

  CommandLifecycleManager(this.commandId, this.command) {
    // Emit initial event
    _emit(CommandPublished(
      commandId: commandId,
      command: command,
    ));
  }

  /// Get the stream of lifecycle events
  Stream<CommandLifecycleEvent> get stream => _controller.stream;

  /// Notify that command handling is complete
  Future<void> notifyHandled(Event? generatedEvent) async {
    print('CommandLifecycleManager.notifyHandled: ${generatedEvent?.type}');
    _emit(CommandHandled(
      commandId: commandId,
      command: command,
      generatedEvent: generatedEvent,
    ));
  }

  /// Notify that an event was published
  Future<void> notifyEventPublished(Event event) async {
    print('CommandLifecycleManager.notifyEventPublished: ${event.type}');
    _emit(EventPublished(
      commandId: commandId,
      command: command,
      event: event,
    ));
  }

  /// Notify that the read model was updated
  Future<void> notifyReadModelUpdated(Event event) async {
    print('CommandLifecycleManager.notifyReadModelUpdated: ${event.type}');
    _emit(ReadModelUpdated(
      commandId: commandId,
      command: command,
      event: event,
    ));
    _complete();
  }

  /// Notify that command processing failed
  Future<void> notifyFailed(Object error, StackTrace stackTrace) async {
    print('CommandLifecycleManager.notifyFailed: $error');
    _emit(CommandFailed(
      commandId: commandId,
      command: command,
      reason: error.toString(),
      error: error,
      stackTrace: stackTrace,
    ));
    _complete();
  }

  void _emit(CommandLifecycleEvent event) {
    print('CommandLifecycleManager._emit: ${event.runtimeType}');
    if (!_isComplete) {
      _controller.add(event);
    } else {
      print('Warning: Attempted to emit event after completion');
    }
  }

  void _complete() {
    print('CommandLifecycleManager._complete');
    if (!_isComplete) {
      _isComplete = true;
      _controller.close();
    }
  }
}

/// Manages lifecycle events for all commands
class CommandLifecycleRegistry {
  final _managers = <String, CommandLifecycleManager>{};
  final _lock = Lock();

  /// Get or create a lifecycle manager for a command
  Future<CommandLifecycleManager> getManager(String commandId, Command command) {
    return _lock.synchronized(() {
      return _managers.putIfAbsent(
          commandId, () => CommandLifecycleManager(commandId, command));
    });
  }

  /// Remove a completed lifecycle manager
  Future<void> removeManager(String commandId) {
    return _lock.synchronized(() {
      _managers.remove(commandId);
    });
  }
}
