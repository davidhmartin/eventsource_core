/// Base interface for all commands
///
/// Commands represent user intentions and are used to validate and process
/// requests for state changes. Unlike events, commands are not persisted and
/// may be rejected.
abstract class Command {
  /// ID of the aggregate this command belongs to
  String get aggregateId;

  /// ID of the user issuing the command
  String get userId;

  /// When the command was issued
  DateTime get timestamp;

  /// Origin system/component that issued the command
  String get origin;

  /// Returns a string unique to the type of the command
  String get commandType;

  /// Validate that the command is well-formed
  /// Throws [ArgumentError] if validation fails
  void validate() {
    if (aggregateId.isEmpty) {
      throw ArgumentError('Aggregate ID cannot be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    if (origin.isEmpty) {
      throw ArgumentError('Origin cannot be empty');
    }
    if (commandType.isEmpty) {
      throw ArgumentError('Command type cannot be empty');
    }
  }

  /// Convert command to JSON for logging or debugging
  Map<String, dynamic> toJson();
}
