import 'dart:convert';
import 'dart:io';
import 'package:core_contracts/core_contracts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Native SQLite storage for Android and Windows clients.
class PlatformStore {
  Database? _database;
  /// Opens the local database and creates version-one tables.
  Future<void> initialize() async {
    if (Platform.isWindows) sqfliteFfiInit();
    final factory = Platform.isWindows ? databaseFactoryFfi : databaseFactory;
    final String directory;
    if (Platform.isWindows) {
      final supportDirectory = await getApplicationSupportDirectory();
      directory = path.join(supportDirectory.path, 'databases');
      await Directory(directory).create(recursive: true);
    } else {
      directory = await getDatabasesPath();
    }
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
  /// Caches a server product without creating an outgoing operation.
  Future<void> cacheProduct(String id, String payload) async => _database!.insert('products', {'id': id, 'payload': payload, 'sync_state': 'SYNCED'}, conflictAlgorithm: ConflictAlgorithm.replace);
  /// Loads all locally cached products.
  Future<List<ProductDto>> listProducts() async {
    final rows = await _database!.query('products', orderBy: 'id ASC');
    return rows.map((row) => ProductDto.fromJson(jsonDecode(row['payload'] as String) as Map<String, dynamic>)).toList();
  }
  /// Returns pending operations ordered by creation time.
  Future<List<Map<String, Object?>>> pendingOperations() async => (await _database!.query('sync_queue', where: 'state = ?', whereArgs: ['PENDING'], orderBy: 'created_at ASC', limit: 100)).map((row) => Map<String, Object?>.from(row)).toList();
  /// Marks a product synchronized and removes its completed queue row.
  Future<void> markSynced(String operationId, String productId) async => _database!.transaction((txn) async {
    await txn.update('products', {'sync_state': 'SYNCED'}, where: 'id = ?', whereArgs: [productId]);
    await txn.delete('sync_queue', where: 'id = ?', whereArgs: [operationId]);
  });
  /// Counts pending queue entries.
  Future<int> get pendingCount async => Sqflite.firstIntValue(await _database!.rawQuery("SELECT COUNT(*) FROM sync_queue WHERE state='PENDING'")) ?? 0;
  /// Closes SQLite.
  Future<void> close() async => _database?.close();
}

/// Creates native storage.
PlatformStore createPlatformStore() => PlatformStore();
