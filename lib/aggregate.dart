import 'event.dart';

/// Base class for all aggregates
///
/// An aggregate is the consistency boundary for a group of domain objects
/// that should be treated as a single unit for data changes.
abstract class Aggregate {
  String _id;
  int _version;

  /// Creates a new aggregate with the given ID
  Aggregate(this._id) : _version = 0;

  /// ID of this aggregate
  String get id => _id;

  /// Current version (last applied event sequence number)
  int get version => _version;

  /// Convert the aggregate to a JSON-compatible Map
  Map<String, dynamic> toJson();

  /// Create a new instance of the aggregate from a JSON-compatible Map
  static Aggregate fromJson(Map<String, dynamic> json) {
    final type = json['_type'] as String;
    final serializer = _serializers[type];
    
    if (serializer == null) {
      throw Exception('Unknown aggregate type: $type');
    }
    
    return serializer(json);
  }

  /// Apply an event to the aggregate
  /// This is called both when applying new events and when rehydrating from history
  void applyEvent(Event event) {
    if (event.aggregateId != id) {
      throw ArgumentError(
          'Event aggregate ID ${event.aggregateId} does not match aggregate ID $id');
    }

    if (event.version != version + 1) {
      throw ArgumentError(
          'Event version ${event.version} is not sequential with aggregate version $version');
    }

    _version = event.version;
    applyEventToState(event);
  }

  /// Internal method that each aggregate must implement to update its state
  /// based on the event type
  void applyEventToState(Event event);


}


class AggregateSerializer {
  // Map<String, Aggregate Function(Map<String, dynamic>)> get serializers => _serializers;
  
  // static Map<String, Aggregate Function(Map<String, dynamic>)> _serializers = {
  //   'BoxAggregate': (json) => BoxAggregate.fromJson(json),
  //   // Add other aggregate types here
  // };

  // an instance variable of type Map<String, Aggregate Function(Map<String, dynamic>)>
  Map<String, Aggregate Function(Map<String, dynamic>)> _serializers = {}

  Aggregate fromJson(Map<String, dynamic> json) {
    final type = json['_type'] as String;
    final serializer = _serializers[type];
    
    if (serializer == null) {
      throw Exception('Unknown aggregate type: $type');
    }
    
    return serializer(json);
  }

  Map<String, dynamic> toJson(Aggregate aggregate) {
    return aggregate.toJson();
  }
}