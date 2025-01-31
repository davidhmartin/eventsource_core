import '../command.dart';
import '../event.dart';

/// Represents different states in the command processing lifecycle
sealed class CommandLifecycleEvent {
  final String commandId;
  final DateTime timestamp;
  final Command command;

  CommandLifecycleEvent({
    required this.commandId,
    required this.timestamp,
    required this.command,
  });
}

/// Emitted when the command is initially published to the system
final class CommandPublished extends CommandLifecycleEvent {
  CommandPublished({
    required String commandId,
    required Command command,
  }) : super(
          commandId: commandId,
          timestamp: DateTime.now(),
          command: command,
        );
}

/// Emitted when command handling is complete
final class CommandHandled extends CommandLifecycleEvent {
  final Event? generatedEvent;

  CommandHandled({
    required String commandId,
    required Command command,
    this.generatedEvent,
  }) : super(
          commandId: commandId,
          timestamp: DateTime.now(),
          command: command,
        );
}

/// Emitted when the generated event is published to the event store
final class EventPublished extends CommandLifecycleEvent {
  final Event event;

  EventPublished({
    required String commandId,
    required Command command,
    required this.event,
  }) : super(
          commandId: commandId,
          timestamp: DateTime.now(),
          command: command,
        );
}

/// Emitted when the read model has been updated with the new event
final class ReadModelUpdated extends CommandLifecycleEvent {
  final Event event;

  ReadModelUpdated({
    required String commandId,
    required Command command,
    required this.event,
  }) : super(
          commandId: commandId,
          timestamp: DateTime.now(),
          command: command,
        );
}

/// Emitted if command processing fails at any point
final class CommandFailed extends CommandLifecycleEvent {
  final String reason;
  final Object? error;
  final StackTrace? stackTrace;

  CommandFailed({
    required String commandId,
    required Command command,
    required this.reason,
    this.error,
    this.stackTrace,
  }) : super(
          commandId: commandId,
          timestamp: DateTime.now(),
          command: command,
        );
}
