import 'event.dart';

/// Base class for all aggregates
///
/// An aggregate is the consistency boundary for a group of domain objects
/// that should be treated as a single unit for data changes.
///
/// Type parameter [TState] represents the state type of the aggregate.
abstract class Aggregate<TState> {
  String _id;
  int _version;
  late TState state;
  final List<Event> _uncommittedEvents = [];

  /// Creates a new aggregate with the given ID
  Aggregate(this._id) : _version = 0 {
    state = createEmptyState();
  }

  /// ID of this aggregate
  String get id => _id;

  /// Current version (last applied event sequence number)
  int get version => _version;

  /// Get any new events that haven't been committed to the event store
  List<Event> get uncommittedEvents => List.unmodifiable(_uncommittedEvents);

  /// Clear the list of uncommitted events after they've been persisted
  void clearUncommittedEvents() {
    _uncommittedEvents.clear();
  }

  /// Apply an event to the aggregate by mutating the state
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
    _uncommittedEvents.add(event);
  }

  /// Apply multiple events in sequence to rebuild aggregate state
  void applyEvents(Iterable<Event> events) {
    for (final event in events) {
      applyEvent(event);
    }
  }

  /// Internal method that each aggregate must implement to update its state
  /// based on the event type
  void applyEventToState(Event event);

  /// Load aggregate state from a snapshot
  void loadFromSnapshot(TState snapshotState, int snapshotVersion) {
    state = snapshotState;
    _version = snapshotVersion;
  }

  /// Create an empty state for the aggregate. This is called when the aggregate
  /// is created or when rehydrating from history
  TState createEmptyState();
}
