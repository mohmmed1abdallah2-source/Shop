import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Native SQLite storage for Android and Windows clients.
class PlatformStore {
  Database? _database;
  /// Opens the local database and creates version-one tables.
  Future<void> initialize() async {
    if (Platform.isWindows) sqfliteFfiInit();
    final factory = Platform.isWindows ? databaseFactoryFfi : databaseFactory;
    final directory = await getDatabasesPath();
    _database = await factory.openDatabase(path.join(directory, 'shop_erp.db'), options: OpenDatabaseOptions(version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE products(id TEXT PRIMARY KEY, payload TEXT NOT NULL, sync_state TEXT NOT NULL)');
      await db.execute('CREATE TABLE sync_queue(id TEXT PRIMARY KEY, operation TEXT NOT NULL, payload TEXT NOT NULL, state TEXT NOT NULL, created_at TEXT NOT NULL)');
    }));
  }
  /// Saves product cache and pending operation atomically.
  Future<void> saveProduct(String id, String payload, String operationId, String createdAt) async => _database!.transaction((txn) async {
    await txn.insert('products', {'id': id, 'payload': payload, 'sync_state': 'PENDING'}, conflictAlgorithm: ConflictAlgorithm.replace);
    await txn.insert('sync_queue', {'id': operationId, 'operation': 'UPSERT_PRODUCT', 'payload': payload, 'state': 'PENDING', 'created_at': createdAt}, conflictAlgorithm: ConflictAlgorithm.abort);
  });
  /// Marks a product and queue operation synchronized.
  Future<void> markSynced(String operationId, String productId) async => _database!.transaction((txn) async {
    await txn.update('sync_queue', {'state': 'SYNCED'}, where: 'id = ?', whereArgs: [operationId]);
    await txn.update('products', {'sync_state': 'SYNCED'}, where: 'id = ?', whereArgs: [productId]);
  });
  /// Counts pending queue entries.
  Future<int> get pendingCount async => Sqflite.firstIntValue(await _database!.rawQuery("SELECT COUNT(*) FROM sync_queue WHERE state='PENDING'")) ?? 0;
  /// Closes SQLite.
  Future<void> close() async => _database?.close();
}

/// Creates native storage.
PlatformStore createPlatformStore() => PlatformStore();
