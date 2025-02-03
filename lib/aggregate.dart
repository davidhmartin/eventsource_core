import 'event.dart';
import 'package:meta/meta.dart';

import 'typedefs.dart';

typedef AggregateType = String;

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

  @protected
  set version(int value) => _version = value;

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

  // Called by toJson. Subclasses override to add aggregate state to the json map.
  void serializeState(JsonMap json);

  // Called by fromJson. Subclasses override to set aggregate state from the json map.
  void deserializeState(JsonMap json);

  /// Apply an event to the aggregate
  /// This is called both when applying new events and when rehydrating from history
  void applyEvent(Event event) {
    if (event.aggregateId != id) {
      throw ArgumentError(
          'Event aggregate ID ${event.aggregateId} does not match aggregate ID $id');
    }

    if (event.version <= _version) {
      throw ArgumentError(
          'Event version ${event.version} is not greater than aggregate version $_version');
    }

    applyEventToState(event);
    _version = event.version;
  }

  /// Apply an event to the aggregate's state
  /// This is called by [applyEvent] after validating the event
  /// Subclasses must override this to apply the event to their state
  void applyEventToState(Event event);
}
