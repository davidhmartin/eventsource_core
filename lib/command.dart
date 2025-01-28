/// Base interface for all commands
abstract class Command {
  /// ID of the aggregate this command belongs to
  String get aggregateId;

  /// ID of the user issuing the command
  String get userId;

  /// When the command was issued
  DateTime get timestamp;

  /// Origin system/component that issued the command
  String get origin;
}
