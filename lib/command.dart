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
  final ID aggregateId;
  final String aggregateType;
  final DateTime timestamp;
  final String origin;
  final bool create;

  Command(this.aggregateId, this.aggregateType, this.timestamp, this.origin, this.create);

  /// The type of the command
  String get type;

  /// Handle the command and return an event if successful
  Event? handle(Aggregate? aggregate);

  /// Convert the command to a JSON map
  JsonMap toJson() {
    final json = <String, dynamic>{
      'aggregateId': aggregateId,
      'aggregateType': aggregateType,
      'timestamp': timestamp.toIso8601String(),
      'origin': origin,
      'create': create,
    };
    serializeState(json);
    return json;
  }

  /// Serialize the command's state to a JSON map
  void serializeState(JsonMap json);

  /// Deserialize the command's state from a JSON map
  void deserializeState(JsonMap json);

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

    Command command = factory(json);
    command.deserializeState(json);
    return command;
  }

  /// Validate that the command is well-formed
  /// Throws [ArgumentError] if validation fails
  void validate() {
    if (type.isEmpty) {
      throw ArgumentError('Command type cannot be empty');
    }
  }
}
