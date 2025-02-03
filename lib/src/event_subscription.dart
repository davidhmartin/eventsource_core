import 'package:eventsource_core/eventsource_core.dart';

/// Provides interfaces for event subscription and read model projections.

/// An interface for objects that can subscribe to events.
abstract class EventSubscriber {
  /// Called when an event is published.
  void onEvent(Event event);
}
