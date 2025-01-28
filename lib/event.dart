/// Base interface for all events
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
}
