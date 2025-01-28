/// Base interface for all events
///
/// Events are immutable records of facts that have occurred in the system.
/// They represent state transitions and are the source of truth for the system's state.
abstract class Event {
  /// Unique identifier for the event
  String get id;

  /// ID of the aggregate this event belongs to
  String get aggregateId;

  /// When the event occurred
  DateTime get timestamp;

  /// Sequence number within the aggregate
  int get version;

  /// Origin system/component that generated the event
  String get origin;

  /// Returns a string unique to the type of the event
  String get eventType;

  /// Convert event to JSON for persistence
  Map<String, dynamic> toJson();

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
    if (eventType.isEmpty) {
      throw ArgumentError('Event type cannot be empty');
    }
  }

  /// Create a copy of this event with a new version
  Event withVersion(int newVersion);
}
