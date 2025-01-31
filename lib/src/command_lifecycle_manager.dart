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
  void notifyHandled(Event? generatedEvent) {
    _emit(CommandHandled(
      commandId: commandId,
      command: command,
      generatedEvent: generatedEvent,
    ));
  }

  /// Notify that an event was published
  void notifyEventPublished(Event event) {
    _emit(EventPublished(
      commandId: commandId,
      command: command,
      event: event,
    ));
  }

  /// Notify that the read model was updated
  void notifyReadModelUpdated(Event event) {
    _emit(ReadModelUpdated(
      commandId: commandId,
      command: command,
      event: event,
    ));
    _complete();
  }

  /// Notify that command processing failed
  void notifyFailed(Object error, StackTrace stackTrace) {
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
    if (!_isComplete) {
      _controller.add(event);
    }
  }

  void _complete() {
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
  CommandLifecycleManager getManager(String commandId, Command command) {
    _lock.synchronized(() {
      return _managers.putIfAbsent(
          commandId, () => CommandLifecycleManager(commandId, command));
    });
    throw Exception('Failed to get or create a CommandLifecycleManager for the given commandId.');
  }

  /// Remove a completed lifecycle manager
  void removeManager(String commandId) {
    _lock.synchronized(() {
      _managers.remove(commandId);
    });
  }
}
