/// Base class for all aggregates
import 'event.dart';

abstract class Aggregate<TState> {
  /// ID of this aggregate
  String get id;

  /// Current version (last applied event sequence number)
  int get version;
  
  /// Current state of the aggregate
  TState get state;

  /// Apply an event to the aggregate by mutating the state
  void applyEvent(Event event);
}
