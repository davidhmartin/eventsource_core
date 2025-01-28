import '../event.dart';
import '../aggregate.dart';
import '../command.dart';

/// Base interface for command handlers
abstract class CommandHandler<TCommand extends Command,
    TAggregate extends Aggregate> {
  /// Validates the command against current state and produces resulting event
  /// Returns null if command results in no state change
  /// Throws ValidationError if command is invalid
  Event? handle(TCommand command, TAggregate aggregate);
}
