import 'package:ulid/ulid.dart';

import 'event.dart';
import 'src/event_store.dart';

typedef JsonMap = Map<String, dynamic>;

/// Type alias for ULID to make it clear when we're using IDs
typedef ID = Ulid;

/// Maximum safe integer that works across all platforms (including web)
const int maxInt = (1 << 53) - 1; // 2^53 - 1

/// Create a new ID (Ulid)
ID newId() => Ulid();

/// Parse a string into an ID (Ulid)
ID idFromString(String str) => Ulid.parse(str);

/// Factory function for creating an EventStore
typedef EventStoreFactory = EventStore Function();

/// Factory function for deserializing events from JSON
typedef EventDeserializer = Event Function(JsonMap);
