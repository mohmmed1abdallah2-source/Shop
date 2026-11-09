import 'package:core_contracts/core_contracts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_and_catalog_provider.dart';
import '../utils/scale_barcode_parser.dart';
import '../widgets/responsive_and_shared_widgets.dart';

/// Editable form state for one product selling unit.
class _UnitEntry {
  /// Creates a unit entry with a default unit label.
  _UnitEntry([this.unitName = 'قطعة']);
  /// Unit label.
  String unitName;
  /// Barcode controller.
  final TextEditingController barcode = TextEditingController();
  /// Retail price controller.
  final TextEditingController retailPrice = TextEditingController();
  /// Wholesale price controller.
  final TextEditingController wholesalePrice = TextEditingController();
  /// Releases text controllers.
  void dispose() { barcode.dispose(); retailPrice.dispose(); wholesalePrice.dispose(); }
}

/// Responsive catalog with multiple units, mobile cards and desktop table.
class ProductsMultiUnitScreen extends StatefulWidget {
  /// Creates the catalog screen.
  const ProductsMultiUnitScreen({super.key});
  @override
  State<ProductsMultiUnitScreen> createState() => _ProductsMultiUnitScreenState();
}

class _ProductsMultiUnitScreenState extends State<ProductsMultiUnitScreen> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _scalePlu = TextEditingController();
  final _search = TextEditingController();
  final List<_UnitEntry> _units = [_UnitEntry()];
  bool _weighted = false;
  static const _unitOptions = ['قطعة', 'باكت', 'كرتون', 'كيس'];

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _scalePlu.dispose();
    _search.dispose();
    for (final unit in _units) { unit.dispose(); }
    super.dispose();
  }

  /// Validates and saves a product with all configured units.
  Future<void> _save() async {
    final unitDtos = <ProductUnitBarcodeDto>[];
    final barcodes = <String>{};
    final labels = <String>{};
    for (final unit in _units) {
      final barcode = unit.barcode.text.trim();
      final retail = double.tryParse(unit.retailPrice.text.trim());
      final wholesale = unit.wholesalePrice.text.trim().isEmpty ? 0.0 : double.tryParse(unit.wholesalePrice.text.trim());
      if (barcode.isEmpty || retail == null || retail < 0 || wholesale == null || wholesale < 0 || !barcodes.add(barcode) || !labels.add(unit.unitName)) {
        _showValidationError('تحقق من الوحدات والباركود والأسعار، ولا تكرر الوحدة أو الباركود.');
        return;
      }
      unitDtos.add(ProductUnitBarcodeDto(unitName: unit.unitName, barcode: barcode, retailPrice: retail, wholesalePrice: wholesale));
    }
    if (_name.text.trim().isEmpty || _sku.text.trim().isEmpty || (_weighted && _scalePlu.text.trim().isEmpty)) {
      _showValidationError('اسم المنتج والرمز، ورمز الميزان للمنتج الموزون، حقول مطلوبة.');
      return;
    }
    final product = ProductDto(id: const Uuid().v4(), name: _name.text.trim(), sku: _sku.text.trim(), kind: _weighted ? 'weighted' : 'numeric', scalePluCode: _weighted ? _scalePlu.text.trim() : null, units: unitDtos);
    final synced = await context.read<AuthAndCatalogProvider>().saveProduct(product);
    if (!mounted) return;
    Navigator.of(context).pop();
    _name.clear();
    _sku.clear();
    _scalePlu.clear();
    for (final unit in _units) { unit.dispose(); }
    _units
      ..clear()
      ..add(_UnitEntry());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(synced ? 'تم حفظ المنتج ومزامنته مع الخادم.' : 'تم حفظ المنتج محلياً وسيبقى في قائمة المزامنة.')));
  }

  /// Displays form validation feedback.
  void _showValidationError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  /// Builds the responsive product list.
  Widget _productList(AuthAndCatalogProvider state, bool wide) {
    final query = _search.text.trim().toLowerCase();
    final rows = state.products.where((p) => query.isEmpty || p.name.toLowerCase().contains(query) || p.sku.toLowerCase().contains(query) || p.units.any((u) => u.barcode.toLowerCase().contains(query))).toList();
    if (rows.isEmpty) return const Center(child: Text('لا توجد منتجات مطابقة للبحث.'));
    if (wide) return SingleChildScrollView(child: DataTable(columns: const [DataColumn(label: Text('المنتج')), DataColumn(label: Text('الرمز')), DataColumn(label: Text('النوع')), DataColumn(label: Text('الوحدات')), DataColumn(label: Text('حالة المزامنة'))], rows: rows.map((p) => DataRow(cells: [DataCell(Text(p.name)), DataCell(Text(p.sku)), DataCell(Text(p.kind == 'weighted' ? 'موزون' : 'عددي')), DataCell(Text(p.units.length.toString())), DataCell(Chip(label: Text(state.pendingProductIds.contains(p.id) ? 'قيد المزامنة' : 'متزامن'), backgroundColor: (state.pendingProductIds.contains(p.id) ? Colors.amber : Colors.green).withOpacity(.18)))])).toList()));
    return ListView.builder(itemCount: rows.length, itemBuilder: (context, index) {
      final product = rows[index];
      return SmartExpandableCard(title: product.name, subtitle: product.sku, details: [Align(alignment: Alignment.centerRight, child: Chip(label: Text(state.pendingProductIds.contains(product.id) ? 'قيد المزامنة' : 'متزامن'), backgroundColor: (state.pendingProductIds.contains(product.id) ? Colors.amber : Colors.green).withOpacity(.18))), Text('النوع: ' + (product.kind == 'weighted' ? 'موزون' : 'عددي')), ...product.units.map((unit) => Text(unit.unitName + ' — ' + unit.barcode + ' — بيع ' + unit.retailPrice.toString() + ' — جملة ' + unit.wholesalePrice.toString()))]);
    });
  }

  /// Builds the product catalog and keyboard-safe multi-unit entry sheet.
  @override
  Widget build(BuildContext context) => Consumer<AuthAndCatalogProvider>(builder: (context, state, _) => Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث بالاسم أو الرمز أو الباركود')),
    const SizedBox(height: 12),
    Expanded(child: _productList(state, MediaQuery.sizeOf(context).width >= 900)),
    if (!state.hasPermission('catalog.write')) const Padding(padding: EdgeInsets.all(8), child: Text('صلاحية إضافة المنتجات غير متاحة لهذا الحساب.')),
    if (state.hasPermission('catalog.write')) FilledButton.icon(onPressed: () => KeyboardSafeModalSheet.show<void>(context, (ctx) => StatefulBuilder(builder: (ctx, setSheetState) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إضافة منتج', style: Theme.of(ctx).textTheme.titleLarge),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم المنتج')),
      TextField(controller: _sku, decoration: const InputDecoration(labelText: 'رمز المنتج')),
      SwitchListTile(value: _weighted, onChanged: (v) => setSheetState(() => _weighted = v), title: const Text('منتج موزون')),
      if (_weighted) TextField(controller: _scalePlu, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'رمز PLU الخاص بالميزان')),
      Align(alignment: Alignment.centerRight, child: Text('وحدات البيع', style: Theme.of(ctx).textTheme.titleMedium)),
      ..._units.asMap().entries.map((entry) {
        final index = entry.key;
        final unit = entry.value;
        return Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
          Row(children: [Expanded(child: DropdownButtonFormField<String>(value: unit.unitName, items: _unitOptions.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(), onChanged: (value) => setSheetState(() => unit.unitName = value ?? unit.unitName), decoration: const InputDecoration(labelText: 'الوحدة'))), if (_units.length > 1) IconButton(onPressed: () => setSheetState(() { _units.removeAt(index).dispose(); }), icon: const Icon(Icons.delete_outline), tooltip: 'حذف الوحدة')]),
          TextField(controller: unit.barcode, textDirection: TextDirection.ltr, onChanged: (_) => setSheetState(() {}), decoration: const InputDecoration(labelText: 'الباركود')),
          if (_weighted && index == 0) Builder(builder: (context) { final parsed = ScaleBarcodeParser.parse(unit.barcode.text); return Align(alignment: Alignment.centerRight, child: Text(parsed == null ? 'يمكن إدخال باركود ميزان EAN-13 يبدأ من 20 إلى 29.' : 'رمز الصنف: ' + parsed.itemCode + ' — القيمة المشفرة: ' + parsed.encodedValue.toString(), style: Theme.of(context).textTheme.bodySmall)); }),
          TextField(controller: unit.retailPrice, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر البيع')),
          TextField(controller: unit.wholesalePrice, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر الجملة')),
        ])));
      }),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _units.length == _unitOptions.length ? null : () => setSheetState(() { final next = _unitOptions.firstWhere((name) => !_units.any((u) => u.unitName == name), orElse: () => 'قطعة'); _units.add(_UnitEntry(next)); }), icon: const Icon(Icons.add), label: const Text('إضافة وحدة أخرى'))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: const Text('حفظ المنتج'))),
    ])))), icon: const Icon(Icons.add), label: const Text('إضافة منتج')),
  ])));
}
