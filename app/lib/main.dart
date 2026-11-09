import 'package:flutter/material.dart';
import 'screens/products_multi_unit_screen.dart';
import 'theme/enterprise_dark_theme.dart';
import 'widgets/responsive_and_shared_widgets.dart';

/// Launches the Flutter app.
void main() => runApp(const ShopApp());

/// Root Flutter application.
class ShopApp extends StatelessWidget {
  /// Creates the root app.
  const ShopApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, theme: EnterpriseDarkTheme.build(), builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!), home: const ResponsiveShell(title: 'إدارة المتجر', body: ProductsMultiUnitScreen()));
}
