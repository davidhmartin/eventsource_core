import 'event.dart';
import 'package:meta/meta.dart';

import 'typedefs.dart';

/// Factory function for creating a new empty aggregate.
typedef AggregateFactory<TAggregate extends Aggregate> = TAggregate Function(
    ID id);

/// Base class for all aggregates
///
/// An aggregate is the consistency boundary for a group of domain objects
/// that should be treated as a single unit for data changes.
abstract class Aggregate {
  ID _id;
  int _version = 0;

  /// Creates a new aggregate with the given ID
  Aggregate(this._id);

  /// ID of this aggregate
  ID get id => _id;

  /// Current version (last applied event sequence number)
  int get version => _version;

  /// Type identifier for this aggregate. Subclasses must override this to
  /// return a unique type name.
  String get type;

  /// Convert event to JSON for persistence
  @nonVirtual
  JsonMap toJson() {
    JsonMap map = {
      'id': _id.toString(),
      'version': _version,
      'type': type,
    };
    serializeState(map);
    return map;
  }

  /// Create an Aggregate from a JSON map
  /// The JSON must include a 'type' field that matches an aggregate type
  factory Aggregate.fromJson(JsonMap json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('JSON missing required "type" field');
    }

    final factory = _factories[type];
    if (factory == null) {
      throw ArgumentError('Unknown aggregate type: $type');
    }

    Aggregate aggregate = factory(json);
    aggregate.deserializeState(json);
    return aggregate;
  }

  // Called by toJson. Subclasses override to add aggregate state to the json map.
  void serializeState(JsonMap json);

  // Called by fromJson. Subclasses override to set aggregate state from the json map.
  void deserializeState(JsonMap json);

  /// Register a factory for creating aggregates of a specific type
  ///
  /// This method must be called explicitly for each aggregate type before it can be
  /// deserialized from JSON. Typically, this is done during application initialization:
  ///
  /// ```dart
  /// void initializeEventSourcing() {
  ///   Aggregate.registerFactory('UserAggregate', UserAggregate.fromJson);
  ///   Aggregate.registerFactory('OrderAggregate', OrderAggregate.fromJson);
  /// }
  /// ```
  ///
  /// If an aggregate type is not registered, [Aggregate.fromJson] will throw an
  /// [ArgumentError] when attempting to deserialize that type.
  ///
  /// [type] must match the value returned by the aggregate's [type] getter.
  /// [factory] must be a function that takes a JSON map and returns an instance
  /// of the appropriate aggregate type.
  static void registerFactory(
      String type, Aggregate Function(JsonMap) factory) {
    _factories[type] = factory;
  }

  static final Map<String, Aggregate Function(JsonMap)> _factories = {};

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
  // Map<String, Aggregate Function(JsonMap)> get serializers => _serializers;

  // static Map<String, Aggregate Function(JsonMap)> _serializers = {
  //   'BoxAggregate': (json) => BoxAggregate.fromJson(json),
  //   // Add other aggregate types here
  // };

  // an instance variable of type Map<String, Aggregate Function(JsonMap)>
  Map<String, Aggregate Function(JsonMap)> _serializers = {};

  Aggregate fromJson(JsonMap json) {
    final type = json['_type'] as String;
    final serializer = _serializers[type];

    if (serializer == null) {
      throw Exception('Unknown aggregate type: $type');
    }

    return serializer(json);
  }

  JsonMap toJson(Aggregate aggregate) {
    return aggregate.toJson();
  }
}

// class UserAggregate extends Aggregate {
//   final String name;
//   final String email;

//   UserAggregate(ID id, this.name, this.email) : super(id);

//   @override
//   String get type => 'UserAggregate';

//   @override
//   factory UserAggregate.fromJson(JsonMap json) {
//     return UserAggregate._(json);
//   }

//   // Private constructor that uses the base class's fromJsonBase
//   UserAggregate._(JsonMap json)
//       : name = json['name'] as String,
//         email = json['email'] as String,
//         super.fromJsonBase(json);

//   @override
//   JsonMap toJson() => {
//         'type': type,
//         'id': id.toString(),
//         'version': version,
//         'name': name,
//         'email': email,
//       };

//   @override
//   void applyEventToState(Event event) {
//     // TODO: implement applyEventToState
//   }
// }
