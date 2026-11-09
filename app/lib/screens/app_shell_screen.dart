import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_and_catalog_provider.dart';
import '../widgets/responsive_and_shared_widgets.dart';
import 'login_screen.dart';
import 'products_multi_unit_screen.dart';

/// Keyboard intent for refreshing the catalog and pending sync queue.
class _SyncCatalogIntent extends Intent {
  /// Creates the sync intent.
  const _SyncCatalogIntent();
}

/// Main application shell with connectivity, sync controls and responsive navigation.
class AppShellScreen extends StatelessWidget {
  /// Creates the shell.
  const AppShellScreen({super.key});
  @override
  Widget build(BuildContext context) => Consumer<AuthAndCatalogProvider>(builder: (context, state, _) {
    if (state.session == null) return const LoginScreen();
    return Shortcuts(shortcuts: const {SingleActivator(LogicalKeyboardKey.f5): _SyncCatalogIntent()}, child: Actions(actions: {_SyncCatalogIntent: CallbackAction<_SyncCatalogIntent>(onInvoke: (_) { state.syncPendingOperations().then((_) => state.loadProducts()); return null; })}, child: ResponsiveShell(title: 'إدارة المتجر', body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [Icon(state.connected ? Icons.cloud_done : Icons.cloud_off, color: state.connected ? Colors.green : Colors.orange), const SizedBox(width: 8), Text(state.connected ? 'متصل بالخادم' : 'وضع محلي'), const Spacer(), Chip(label: Text('مزامنة معلقة: ' + state.pending.toString())), IconButton(onPressed: () async { await state.syncPendingOperations(); await state.loadProducts(); }, tooltip: 'مزامنة الآن (F5)', icon: const Icon(Icons.sync)), IconButton(onPressed: state.signOut, tooltip: 'تسجيل الخروج', icon: const Icon(Icons.logout))])),
      const Expanded(child: ProductsMultiUnitScreen()),
    ]))));
  });
}
