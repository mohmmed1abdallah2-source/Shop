import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_and_catalog_provider.dart';
import '../widgets/responsive_and_shared_widgets.dart';
import 'products_multi_unit_screen.dart';

/// Main application shell with server and sync status.
class AppShellScreen extends StatelessWidget {
  /// Creates the shell.
  const AppShellScreen({super.key});
  @override
  Widget build(BuildContext context) => Consumer<AuthAndCatalogProvider>(builder: (context, state, child) => ResponsiveShell(title: 'إدارة المتجر', body: Column(children: [Padding(padding: const EdgeInsets.all(12), child: Row(children: [Icon(state.connected ? Icons.cloud_done : Icons.cloud_off, color: state.connected ? Colors.green : Colors.orange), const SizedBox(width: 8), Text(state.connected ? 'متصل بالخادم' : 'وضع محلي'), const Spacer(), Chip(label: Text('مزامنة معلقة: ' + state.pending.toString()))])), const Expanded(child: ProductsMultiUnitScreen())])));
}
