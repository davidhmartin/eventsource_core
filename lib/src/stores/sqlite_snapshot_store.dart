import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import '../../aggregate.dart';
import '../../typedefs.dart';
import '../aggregate_repository.dart';
import '../lock.dart';

/// SQLite implementation of SnapshotStore.
class SqliteSnapshotStore implements SnapshotStore {
  final Database _db;
  final _lock = Lock();

  SqliteSnapshotStore(String path) : _db = sqlite3.open(path) {
    _initializeDatabase();
  }

  void _initializeDatabase() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS snapshots (
        aggregate_id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        state TEXT NOT NULL,
        version INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<Aggregate?> getLatestSnapshot(ID aggregateId) async {
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

      final Aggregate aggregate = Aggregate.fromJson(jsonMap);

      return Future.value(aggregate);
      // } catch (e) {
      //   // Handle any parsing errors and return default value
      //   return Future.value((defaultTStateValue, 0)); // Wrap in Future
      // }
    });
  }

  @override
  Future<void> saveSnapshot(Aggregate aggregate) {
    return _lock.synchronized(() async {
      final stateJson = jsonEncode(aggregate.toJson());
      final version = aggregate.version;
      final aggregateId = aggregate.id;
      final type = aggregate.type;
      _db.execute('''
        INSERT OR REPLACE INTO snapshots (aggregate_id, type, state, version)
        VALUES (?, ?, ?, ?)
      ''', [aggregateId, type, stateJson, version]);
    });
  }

  void dispose() {
    _db.dispose();
  }
}
