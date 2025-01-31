import 'package:meta/meta.dart';
import 'eventsource_core.dart';
import 'typedefs.dart';

export 'src/command_lifecycle.dart';

/// Base class for all commands
///
/// Commands represent user intentions and are used to validate and process
/// requests for state changes. Unlike events, commands are not persisted and
/// may be rejected.
abstract class Command {
  final ID _aggregateId;
  final DateTime _timestamp;
  final String _origin;

  Command(
    this._aggregateId,
    this._timestamp,
    this._origin,
  ) {
    validate();
  }

  /// Protected constructor for use by fromJson implementations
  @protected
  Command.fromJsonBase(JsonMap json)
      : _aggregateId = idFromString(json['aggregateId'] as String),
        _timestamp = DateTime.parse(json['timestamp'] as String),
        _origin = json['origin'] as String {
    validate();
  }

  /// ID of the aggregate this command belongs to
  ID get aggregateId => _aggregateId;

  /// When the command was issued
  DateTime get timestamp => _timestamp;

  /// Origin system/component that issued the command
  String get origin => _origin;

  /// Type identifier for this command
  String get type;

  /// Convert command to JSON for logging or debugging
  JsonMap toJson() {
    return {
      'aggregateId': _aggregateId.toString(),
      'timestamp': _timestamp.toIso8601String(),
      'origin': _origin,
    };
  }

  /// Create a Command from a JSON map
  /// The JSON must include a 'type' field that matches a registered command type
  factory Command.fromJson(JsonMap json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('JSON missing required "type" field');
    }

    final factory = _factories[type];
    if (factory == null) {
      throw ArgumentError('Unknown command type: $type');
    }

    return factory(json);
  }

  /// Register a factory for creating commands of a specific type
  ///
  /// This method must be called explicitly for each command type before it can be
  /// deserialized from JSON. Typically, this is done during application initialization:
  ///
  /// ```dart
  /// void initializeEventSourcing() {
  ///   Command.registerFactory('CreateUser', CreateUserCommand.fromJson);
  ///   Command.registerFactory('ChangeEmail', ChangeEmailCommand.fromJson);
  /// }
  /// ```
  ///
  /// If a command type is not registered, [Command.fromJson] will throw an
  /// [ArgumentError] when attempting to deserialize that type.
  ///
  /// [type] must match the value returned by the command's [type] getter.
  /// [factory] must be a function that takes a JSON map and returns an instance
  /// of the appropriate command type.
  static void registerFactory(String type, Command Function(JsonMap) factory) {
    _factories[type] = factory;
  }

  static final Map<String, Command Function(JsonMap)> _factories = {};

  /// Validate that the command is well-formed
  /// Throws [ArgumentError] if validation fails
  void validate() {
    if (type.isEmpty) {
      throw ArgumentError('Command type cannot be empty');
    }
  }

  /// Handle this command against the given aggregate
  /// Returns an event if the command results in a state change, null otherwise
  /// Throws [ArgumentError] if the command is invalid for the current state
  Event? handle(Aggregate aggregate);
}
