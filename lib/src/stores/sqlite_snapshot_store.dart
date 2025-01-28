import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import '../../snapshot_store.dart';
import '../../lock.dart';

/// SQLite implementation of SnapshotStore
class SqliteSnapshotStore<TState> implements SnapshotStore<TState> {
  final Database _db;
  final _lock = Lock();
  final Function(Map<String, dynamic>) _fromJson;
  final Function(TState) _toJson;
  final TState defaultTStateValue;

  SqliteSnapshotStore(
    String path, {
    required Function(Map<String, dynamic>) fromJson,
    required Function(TState) toJson,
    required this.defaultTStateValue,
  })  : _db = sqlite3.open(path),
        _fromJson = fromJson,
        _toJson = toJson {
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
  Future<(TState, int)?> getLatestSnapshot(String aggregateId) async {
    return _lock.synchronized(() {
      final result = _db.select(
        'SELECT state, version FROM snapshots WHERE aggregate_id = ?',
        [aggregateId],
      );

      if (result.isEmpty) {
        // Return a default value instead of null
        return Future.value(null);
      }

      try {
        final row = result.first;
        final state = _fromJson(
                jsonDecode(row['state'] as String) as Map<String, dynamic>)
            as TState;
        final version = row['version'] as int;

        return Future.value((state, version)); // Wrap in Future
      } catch (e) {
        // Handle any parsing errors and return default value
        return Future.value((defaultTStateValue, 0)); // Wrap in Future
      }
    });
  }

  @override
  Future<(TState, int)> saveSnapshot(
      String aggregateId, TState state, int version) {
    return _lock.synchronized(() {
      final stateJson = jsonEncode(_toJson(state));
      _db.execute('''
        INSERT OR REPLACE INTO snapshots (aggregate_id, state, version)
        VALUES (?, ?, ?)
      ''', [aggregateId, stateJson, version]);
      return Future.value((state, version));
    });
  }

  void dispose() {
    _db.dispose();
  }
}
