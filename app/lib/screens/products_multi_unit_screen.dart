import 'package:core_contracts/core_contracts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_and_catalog_provider.dart';
import '../widgets/responsive_and_shared_widgets.dart';

/// Responsive multi-unit catalog entry screen.
class ProductsMultiUnitScreen extends StatefulWidget {
  /// Creates the catalog screen.
  const ProductsMultiUnitScreen({super.key});
  @override
  State<ProductsMultiUnitScreen> createState() => _ProductsMultiUnitScreenState();
}

class _ProductsMultiUnitScreenState extends State<ProductsMultiUnitScreen> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _price = TextEditingController();
  final _search = TextEditingController();
  String _unit = 'قطعة';
  bool _weighted = false;
  @override
  void dispose() { _name.dispose(); _sku.dispose(); _barcode.dispose(); _price.dispose(); _search.dispose(); super.dispose(); }

  Future<void> _save(BuildContext sheetContext) async {
    final price = double.tryParse(_price.text.trim());
    if (_name.text.trim().isEmpty || _sku.text.trim().isEmpty || _barcode.text.trim().isEmpty || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكمل اسم المنتج والرمز والباركود والسعر بشكل صحيح.')));
      return;
    }
    final product = ProductDto(id: const Uuid().v4(), name: _name.text.trim(), sku: _sku.text.trim(), kind: _weighted ? 'weighted' : 'numeric', scalePluCode: _weighted ? _barcode.text.trim() : null, units: [ProductUnitBarcodeDto(unitName: _unit, barcode: _barcode.text.trim(), retailPrice: price)]);
    final synced = await context.read<AuthAndCatalogProvider>().saveProduct(product);
    if (!mounted) return;
    Navigator.pop(sheetContext);
    _name.clear();
    _sku.clear();
    _barcode.clear();
    _price.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(synced ? 'تم حفظ المنتج ومزامنته مع الخادم.' : 'تم حفظ المنتج محلياً وسيبقى في قائمة المزامنة.')));
  }

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث بالاسم أو الرمز أو الباركود')),
    const Expanded(child: Center(child: Text('ابحث عن منتج أو أضف منتجاً جديداً.'))),
    FilledButton.icon(onPressed: () => KeyboardSafeModalSheet.show<void>(context, (ctx) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إضافة منتج', style: Theme.of(ctx).textTheme.titleLarge),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم المنتج')),
      TextField(controller: _sku, decoration: const InputDecoration(labelText: 'رمز المنتج')),
      SwitchListTile(value: _weighted, onChanged: (v) => setState(() => _weighted = v), title: const Text('منتج موزون')),
      DropdownButtonFormField<String>(value: _unit, items: ['قطعة','باكت','كرتون','كيس'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => setState(() => _unit = v ?? _unit), decoration: const InputDecoration(labelText: 'الوحدة')),
      TextField(controller: _barcode, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الباركود / PLU')),
      TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر البيع')),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () => _save(ctx), child: const Text('حفظ المنتج'))),
    ]))), icon: const Icon(Icons.add), label: const Text('إضافة منتج')),
  ]));
}
