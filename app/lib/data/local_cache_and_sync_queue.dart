import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

/// Local SQLite cache and outgoing operation queue.
class LocalCacheAndSyncQueue {
  Database? _db;
  final List<Map<String, Object?>> _browserQueue = [];
  /// Initializes native SQLite or browser-memory storage.
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
  /// Persists a product locally and queues the same payload for remote synchronization.
  Future<void> saveProductAndQueue(ProductDto product, String operationId) async {
    final payload = jsonEncode(product.toJson());
    final now = DateTime.now().toUtc().toIso8601String();
    if (kIsWeb) {
      _browserQueue.add({'id': operationId, 'operation': 'UPSERT_PRODUCT', 'payload': payload, 'state': 'PENDING', 'created_at': now});
      return;
    }
    await _db!.transaction((txn) async {
      await txn.insert('products', {'id': product.id, 'payload': payload, 'sync_state': 'PENDING'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('sync_queue', {'id': operationId, 'operation': 'UPSERT_PRODUCT', 'payload': payload, 'state': 'PENDING', 'created_at': now}, conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }
  /// Marks a queued operation as synchronized.
  Future<void> markSynced(String operationId, String productId) async {
    if (kIsWeb) { _browserQueue.removeWhere((row) => row['id'] == operationId); return; }
    await _db!.transaction((txn) async {
      await txn.update('sync_queue', {'state': 'SYNCED'}, where: 'id = ?', whereArgs: [operationId]);
      await txn.update('products', {'sync_state': 'SYNCED'}, where: 'id = ?', whereArgs: [productId]);
    });
  }
  /// Returns number of pending operations.
  Future<int> get pendingCount async {
    if (kIsWeb) return _browserQueue.where((row) => row['state'] == 'PENDING').length;
    final rows = await _db!.rawQuery(\"SELECT COUNT(*) AS count FROM sync_queue WHERE state='PENDING'\");
    return Sqflite.firstIntValue(rows) ?? 0;
  }
  /// Closes native database.
  Future<void> close() async => _db?.close();
}
