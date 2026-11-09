import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

/// Local SQLite cache and browser-memory queue.
class LocalCacheAndSyncQueue {
  Database? _db;
  final List<Map<String, Object?>> _browserQueue = [];
  /// Initializes platform-appropriate storage.
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.windows) sqfliteFfiInit();
    final factory = defaultTargetPlatform == TargetPlatform.windows ? databaseFactoryFfi : databaseFactory;
    final directory = await getDatabasesPath();
    _db = await factory.openDatabase(path.join(directory, 'shop_erp.db'), options: OpenDatabaseOptions(version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE products(id TEXT PRIMARY KEY, payload TEXT NOT NULL, sync_state TEXT NOT NULL)');
      await db.execute('CREATE TABLE sync_queue(id TEXT PRIMARY KEY, operation TEXT NOT NULL, payload TEXT NOT NULL, state TEXT NOT NULL, created_at TEXT NOT NULL)');
    }));
  }
  /// Number of queued operations.
  Future<int> get pendingCount async {
    if (kIsWeb) return _browserQueue.length;
    final rows = await _db!.rawQuery("SELECT COUNT(*) AS count FROM sync_queue WHERE state='PENDING'");
    return Sqflite.firstIntValue(rows) ?? 0;
  }
  /// Closes native database.
  Future<void> close() async => _db?.close();
}
