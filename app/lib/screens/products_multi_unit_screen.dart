import 'package:flutter/material.dart';
import '../widgets/responsive_and_shared_widgets.dart';

/// Multi-unit catalog entry screen.
class ProductsMultiUnitScreen extends StatefulWidget {
  /// Creates the screen.
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
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث بالاسم أو الرمز أو الباركود')),
    const Expanded(child: Center(child: Text('لا توجد منتجات محملة بعد.'))),
    FilledButton.icon(onPressed: () => KeyboardSafeModalSheet.show<void>(context, (ctx) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إضافة منتج', style: Theme.of(ctx).textTheme.titleLarge),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم المنتج')),
      TextField(controller: _sku, decoration: const InputDecoration(labelText: 'رمز المنتج')),
      SwitchListTile(value: _weighted, onChanged: (v) => setState(() => _weighted = v), title: const Text('منتج موزون')),
      DropdownButtonFormField<String>(value: _unit, items: ['قطعة','باكت','كرتون','كيس'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => setState(() => _unit = v ?? _unit), decoration: const InputDecoration(labelText: 'الوحدة')),
      TextField(controller: _barcode, decoration: const InputDecoration(labelText: 'الباركود / PLU')),
      TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر البيع')),
      FilledButton(onPressed: () { if (_name.text.trim().isEmpty || _sku.text.trim().isEmpty || double.tryParse(_price.text) == null) return; Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحقق محلياً؛ يلزم ربط API لإكمال الحفظ.'))); }, child: const Text('حفظ المنتج')),
    ]))), icon: const Icon(Icons.add), label: const Text('إضافة منتج')),
  ]));
}
