import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import '../../event.dart';
import '../../typedefs.dart';
import '../event_store.dart';
import '../lock.dart';

/// SQLite implementation of EventStore
class SqliteEventStore implements EventStore {
  final Database _db;
  final _lock = Lock();
  final Event Function(JsonMap)? _eventFactory;

  SqliteEventStore._(String path, {Event Function(JsonMap)? eventFactory})
      : _db = sqlite3.open(path),
        _eventFactory = eventFactory;

  static Future<SqliteEventStore> create(String path,
      {Event Function(JsonMap)? eventFactory}) async {
    final store = SqliteEventStore._(path, eventFactory: eventFactory);
    await store._initializeDatabase();
    return store;
  }

  Future<void> _initializeDatabase() async {
    return _lock.synchronized(() async {
      _db.execute('''
        CREATE TABLE IF NOT EXISTS events (
          id TEXT NOT NULL,
          aggregate_id TEXT NOT NULL,
          version INTEGER NOT NULL,
          event_type TEXT NOT NULL,
          data TEXT NOT NULL,
          metadata TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          origin TEXT NOT NULL,
          PRIMARY KEY (aggregate_id, version)
        )
      ''');
    });
  }

  @override
  Future<void> appendEvents(
      String aggregateId, List<Event> events, int expectedVersion) async {
    return _lock.synchronized(() async {
      var inTransaction = false;
      try {
        final currentVersion = _getCurrentVersion(aggregateId);
        if (currentVersion != expectedVersion) {
          throw ConcurrencyException(
              'Expected version $expectedVersion but found $currentVersion');
        }

        _db.execute('BEGIN TRANSACTION');
        inTransaction = true;

        for (final event in events) {
          final json = event.toJson();
          _db.execute(
            'INSERT INTO events (id, aggregate_id, version, event_type, data, metadata, timestamp, origin) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              event.id,
              event.aggregateId,
              event.version,
              json['eventType'],
              jsonEncode(json['data']),
              jsonEncode(json['metadata']),
              event.timestamp.millisecondsSinceEpoch,
              event.origin,
            ],
          );
        }
        _db.execute('COMMIT');
        inTransaction = false;
      } catch (e) {
        if (inTransaction) {
          try {
            _db.execute('ROLLBACK');
          } catch (rollbackError) {
            // Log rollback error but throw original error
            print('Error during rollback: $rollbackError');
          }
        }
        rethrow;
      }
    });
  }

  @override
  Stream<Event> getEvents(String aggregateId,
      {int? fromVersion,
      int? toVersion,
      String? origin,
      bool Function(Event)? filter}) async* {
    // Build the query with parameters
    var query = 'SELECT * FROM events WHERE aggregate_id = ?';
    List<Object> params = [aggregateId];

    if (fromVersion != null) {
      query += ' AND version >= ?';
      params.add(fromVersion);
    }

    if (toVersion != null) {
      query += ' AND version <= ?';
      params.add(toVersion);
    }

    if (origin != null) {
      query += ' AND origin = ?';
      params.add(origin);
    }

    query += ' ORDER BY version ASC';

    // Use a prepared statement for better performance
    final stmt = _db.prepare(query);
    try {
      final results = stmt.select(params);
      
      for (final row in results) {
        if (_eventFactory == null) {
          throw StateError('No event factory provided to deserialize events');
        }
        
        final event = _eventFactory({
          'id': row['id'] as String,
          'aggregateId': row['aggregate_id'] as String,
          'eventType': row['event_type'] as String,
          'data': jsonDecode(row['data'] as String),
          'metadata': jsonDecode(row['metadata'] as String),
          'version': row['version'] as int,
          'timestamp': DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
          'origin': row['origin'] as String,
        });
        
        if (filter == null || filter(event)) {
          yield event;
        }
      }
    } finally {
      stmt.dispose();
    }
  }

  int _getCurrentVersion(String aggregateId) {
    try {
      final result = _db.select(
        'SELECT COUNT(*) as count FROM events WHERE aggregate_id = ?',
        [aggregateId],
      ).first;
      return result['count'] as int;
    } catch (e) {
      // Ensure any failed transaction is rolled back
      try {
        _db.execute('ROLLBACK');
      } catch (rollbackError) {
        // Ignore rollback errors on read operations
      }
      rethrow;
    }
  }

  Future<void> dispose() async {
    return _lock.synchronized(() async {
      try {
        // Attempt to rollback any pending transactions
        try {
          _db.execute('ROLLBACK');
        } catch (_) {
          // Ignore rollback errors during dispose
        }

        _db.dispose();
        await Future.delayed(
            Duration(milliseconds: 50)); // Allow resources to be released
      } catch (e) {
        print('Error disposing database: $e');
        rethrow;
      }
    });
  }
}

/// Exception thrown when concurrent modifications conflict
class ConcurrencyException implements Exception {
  final String message;
  ConcurrencyException(this.message);

  @override
  String toString() => 'ConcurrencyException: $message';
}
