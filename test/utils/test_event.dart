import 'package:eventsource_core/event.dart';

/// Test implementation of Event for use in tests
class TestEvent implements Event {
  @override
  final String id;

  @override
  final String aggregateId;

  @override
  final DateTime timestamp;

  @override
  final int version;

  @override
  final String origin;

  @override
  final String eventType;

  final Map<String, dynamic> data;
  final Map<String, dynamic> metadata;

  TestEvent({
    required this.id,
    required this.aggregateId,
    required this.eventType,
    required this.data,
    required this.metadata,
    required this.version,
    required this.timestamp,
    required this.origin,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'aggregateId': aggregateId,
        'eventType': eventType,
        'data': data,
        'metadata': metadata,
        'version': version,
        'timestamp': timestamp.toIso8601String(),
        'origin': origin,
      };

  /// Create a test event from JSON
  factory TestEvent.fromJson(Map<String, dynamic> json) => TestEvent(
        id: json['id'] as String,
        aggregateId: json['aggregateId'] as String,
        eventType: json['eventType'] as String,
        data: json['data'] as Map<String, dynamic>,
        metadata: json['metadata'] as Map<String, dynamic>,
        version: json['version'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        origin: json['origin'] as String,
      );
}
