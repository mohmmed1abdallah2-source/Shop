import 'package:flutter/foundation.dart';
import '../data/local_cache_and_sync_queue.dart';

/// Exposes connectivity and pending synchronization state to the UI.
class AuthAndCatalogProvider extends ChangeNotifier {
  /// Creates provider with local storage.
  AuthAndCatalogProvider(this.cache);
  /// Local cache.
  final LocalCacheAndSyncQueue cache;
  /// Whether API is reachable.
  bool connected = false;
  /// Number of pending operations.
  int pending = 0;
  /// Updates API reachability.
  void setConnected(bool value) { connected = value; notifyListeners(); }
  /// Refreshes pending queue count.
  Future<void> refreshQueue() async { pending = await cache.pendingCount; notifyListeners(); }
}
