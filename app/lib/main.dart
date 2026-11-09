import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/firebase_auth_adapter.dart';
import 'data/local_cache_and_sync_queue.dart';
import 'providers/auth_and_catalog_provider.dart';
import 'screens/app_shell_screen.dart';
import 'theme/enterprise_dark_theme.dart';

/// Initializes storage, Firebase REST authentication and API client.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = LocalCacheAndSyncQueue();
  await cache.initialize();
  final auth = FirebaseAuthAdapter(apiKey: const String.fromEnvironment('FIREBASE_API_KEY'));
  final api = ApiClient(baseUri: Uri.parse(const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com')), tokenProvider: auth.getIdToken);
  final provider = AuthAndCatalogProvider(cache: cache, auth: auth, api: api);
  await provider.restoreSession();
  runApp(ShopApp(provider: provider));
}

/// Root Flutter application.
class ShopApp extends StatelessWidget {
  /// Creates the app with its initialized provider.
  const ShopApp({super.key, required this.provider});
  /// Shared authentication and catalog state.
  final AuthAndCatalogProvider provider;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(value: provider, child: MaterialApp(debugShowCheckedModeBanner: false, theme: EnterpriseDarkTheme.build(), builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!), home: const AppShellScreen()));
}
