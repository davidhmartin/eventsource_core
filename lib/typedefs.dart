import 'package:ulid/ulid.dart';

import 'event.dart';
import 'aggregate.dart';
import 'src/event_store.dart';

/// Type alias for JSON maps
typedef JsonMap = Map<String, dynamic>;

/// Type alias for event deserializer functions
typedef EventDeserializer = Event Function(JsonMap json);

/// Type alias for aggregate deserializer functions
typedef AggregateDeserializer = Aggregate Function(JsonMap json);

/// Type alias for IDs
typedef ID = String;

/// Maximum safe integer that works across all platforms (including web)
const int maxInt = (1 << 53) - 1; // 2^53 - 1

/// Create a new unique ID
String newId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}

/// Convert a string to an ID
ID idFromString(String str) => str;

/// Factory function for creating an EventStore
typedef EventStoreFactory = EventStore Function();
