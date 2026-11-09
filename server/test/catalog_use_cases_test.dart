import 'package:test/test.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:shop_server/src/application/catalog_use_cases.dart';
import 'package:shop_server/src/domain/catalog_repository.dart';
import 'package:shop_server/src/infrastructure/in_memory_catalog_repository.dart';

/// Catalog application use-case tests.
void main() {
  test('replays the same product for a repeated idempotency key', () async {
    final repository = InMemoryCatalogRepository();
    final useCase = UpsertProductUseCase(repository);
    const product = ProductDto(id: 'p1', name: 'ماء', sku: 'WATER', kind: 'numeric', units: [ProductUnitBarcodeDto(unitName: 'piece', barcode: '123456', retailPrice: 10)]);
    await useCase.call('branch-1', product, 'idempotency-key-0001');
    await useCase.call('branch-1', product, 'idempotency-key-0001');
    expect((await repository.list('branch-1')).length, 1);
  });
  test('rejects reuse of one key with another payload', () async {
    final useCase = UpsertProductUseCase(InMemoryCatalogRepository());
    const first = ProductDto(id: 'p1', name: 'ماء', sku: 'WATER', kind: 'numeric', units: [ProductUnitBarcodeDto(unitName: 'piece', barcode: '123456', retailPrice: 10)]);
    const changed = ProductDto(id: 'p1', name: 'ماء كبير', sku: 'WATER', kind: 'numeric', units: [ProductUnitBarcodeDto(unitName: 'piece', barcode: '123456', retailPrice: 10)]);
    await useCase.call('branch-1', first, 'idempotency-key-0002');
    expect(() => useCase.call('branch-1', changed, 'idempotency-key-0002'), throwsA(isA<IdempotencyConflict>()));
  });
  test('isolates product lists by branch and resolves barcode', () async {
    final repository = InMemoryCatalogRepository();
    const product = ProductDto(id: 'p1', name: 'ماء', sku: 'WATER', kind: 'numeric', units: [ProductUnitBarcodeDto(unitName: 'piece', barcode: '123456', retailPrice: 10)]);
    await repository.upsert('branch-1', product, 'idempotency-key-0003');
    expect(await repository.list('branch-2'), isEmpty);
    expect((await repository.lookup('branch-1', '123456'))?.id, 'p1');
  });
  test('rejects products without a unit', () {
    final useCase = UpsertProductUseCase(InMemoryCatalogRepository());
    const product = ProductDto(id: 'p2', name: 'صنف', sku: 'SKU', kind: 'numeric', units: []);
    expect(() => useCase.call('branch-1', product, 'idempotency-key-0004'), throwsArgumentError);
  });
}
