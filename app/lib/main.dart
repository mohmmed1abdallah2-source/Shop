import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/local_cache_and_sync_queue.dart';
import 'providers/auth_and_catalog_provider.dart';
import 'screens/app_shell_screen.dart';
import 'theme/enterprise_dark_theme.dart';

/// Initializes local storage and starts the Flutter application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = LocalCacheAndSyncQueue();
  await cache.initialize();
  runApp(ShopApp(cache: cache));
}

/// Root application widget.
class ShopApp extends StatelessWidget {
  /// Creates the application.
  const ShopApp({super.key, required this.cache});
  /// Local cache and synchronization queue.
  final LocalCacheAndSyncQueue cache;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(create: (_) => AuthAndCatalogProvider(cache), child: MaterialApp(debugShowCheckedModeBanner: false, theme: EnterpriseDarkTheme.build(), builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!), home: const AppShellScreen()));
}
