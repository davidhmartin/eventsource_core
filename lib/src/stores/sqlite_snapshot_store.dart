import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import '../../aggregate.dart';
import '../../typedefs.dart';
import '../aggregate_store.dart';
import '../lock.dart';

/// SQLite implementation of SnapshotStore
class SqliteSnapshotStore<TAggregate extends Aggregate>
    implements SnapshotStore<TAggregate> {
  final Database _db;
  final _lock = Lock();

  SqliteSnapshotStore(String path) : _db = sqlite3.open(path) {
    _initializeDatabase();
  }

  void _initializeDatabase() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS snapshots (
        aggregate_id TEXT PRIMARY KEY,
        state TEXT NOT NULL,
        version INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<TAggregate?> getLatestSnapshot(String aggregateId) async {
    return _lock.synchronized(() {
      final result = _db.select(
        'SELECT state, version FROM snapshots WHERE aggregate_id = ?',
        [aggregateId],
      );

      if (result.isEmpty) {
        // Return a default value instead of null
        return Future.value(null);
      }

      // try {
      final row = result.first;
      final jsonMap = jsonDecode(row['state'] as String) as JsonMap;
      final version = row['version'] as int;

      final TAggregate aggregate = Aggregate.fromJson(jsonMap) as TAggregate;

      return Future.value(aggregate);
      // } catch (e) {
      //   // Handle any parsing errors and return default value
      //   return Future.value((defaultTStateValue, 0)); // Wrap in Future
      // }
    });
  }

  @override
  Future<void> saveSnapshot(TAggregate aggregate) {
    return _lock.synchronized(() async {
      final stateJson = jsonEncode(aggregate.toJson());
      final version = aggregate.version;
      final aggregateId = aggregate.id;
      _db.execute('''
        INSERT OR REPLACE INTO snapshots (aggregate_id, state, version)
        VALUES (?, ?, ?)
      ''', [aggregateId, stateJson, version]);
    });
  }

  void dispose() {
    _db.dispose();
  }
}
