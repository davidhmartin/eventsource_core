import 'package:meta/meta.dart';

import 'typedefs.dart';

/// Base class for all events
///
/// Events are immutable records of facts that have occurred in the system.
/// They represent state transitions and are the source of truth for the system's state.
abstract class Event {
  final String _id;
  final String _aggregateId;
  final DateTime _timestamp;
  final int _version;
  final String _origin;

  /// Protected constructor for use by event implementations
  Event(
    this._id,
    this._aggregateId,
    this._timestamp,
    this._version,
    this._origin,
  ) {
    validate();
  }

  /// Protected constructor for use by fromJson implementations
  @protected
  Event.fromJsonBase(JsonMap json)
      : _id = json['id'] as String,
        _aggregateId = json['aggregateId'] as String,
        _timestamp = DateTime.parse(json['timestamp'] as String),
        _version = json['version'] as int,
        _origin = json['origin'] as String {
    // todo validate the type from the json matches this object's type.
    validate();
  }

  /// Unique identifier for the event
  String get id => _id;

  /// ID of the aggregate this event belongs to
  String get aggregateId => _aggregateId;

  /// When the event occurred
  DateTime get timestamp => _timestamp;

  /// Sequence number within the aggregate
  int get version => _version;

  /// Origin system/component that generated the event
  String get origin => _origin;

  /// Type identifier for this event
  String get type;

  /// Convert event to JSON for persistence
  JsonMap toJson();

  /// Create an Event from a JSON map
  /// The JSON must include a 'type' field that matches a registered event type
  factory Event.fromJson(JsonMap json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('JSON missing required "type" field');
    }

    final factory = _factories[type];
    if (factory == null) {
      throw ArgumentError('Unknown event type: $type');
    }

    return factory(json);
  }

  /// Register a factory for creating events of a specific type
  ///
  /// This method must be called explicitly for each event type before it can be
  /// deserialized from JSON. Typically, this is done during application initialization:
  ///
  /// ```dart
  /// void initializeEventSourcing() {
  ///   Event.registerFactory('UserCreated', UserCreatedEvent.fromJson);
  ///   Event.registerFactory('EmailChanged', EmailChangedEvent.fromJson);
  /// }
  /// ```
  ///
  /// If an event type is not registered, [Event.fromJson] will throw an
  /// [ArgumentError] when attempting to deserialize that type.
  ///
  /// [type] must match the value returned by the event's [type] getter.
  /// [factory] must be a function that takes a JSON map and returns an instance
  /// of the appropriate event type.
  static void registerFactory(String type, Event Function(JsonMap) factory) {
    _factories[type] = factory;
  }

  static final Map<String, Event Function(JsonMap)> _factories = {};

  /// Validate that the event is well-formed
  /// Throws [ArgumentError] if validation fails
  void validate() {
    if (id.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    if (aggregateId.isEmpty) {
      throw ArgumentError('Aggregate ID cannot be empty');
    }
    if (version < 1) {
      throw ArgumentError('Version must be greater than 0');
    }
    if (origin.isEmpty) {
      throw ArgumentError('Origin cannot be empty');
    }
    if (type.isEmpty) {
      throw ArgumentError('Event type cannot be empty');
    }
  }

  /// Create a copy of this event with a new version
  Event withVersion(int newVersion);
}
