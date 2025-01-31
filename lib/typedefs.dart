import 'package:ulid/ulid.dart';

typedef JsonMap = Map<String, dynamic>;

/// Type alias for ULID to make it clear when we're using IDs
typedef ID = Ulid;

/// Maximum safe integer that works across all platforms (including web)
const int MAX_INT = (1 << 53) - 1; // 2^53 - 1

/// Parse a string into an ID (Ulid)
ID idFromString(String str) => Ulid.parse(str);

/// Create a new ID (Ulid)
ID newId() => Ulid();
