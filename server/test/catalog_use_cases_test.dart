import 'package:test/test.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:shop_server/src/application/catalog_use_cases.dart';
import 'package:shop_server/src/infrastructure/in_memory_catalog_repository.dart';

/// Catalog use-case tests.
void main() {
  test('replays same product for repeated idempotency key', () async {
    final repo = InMemoryCatalogRepository();
    final useCase = UpsertProductUseCase(repo);
    const product = ProductDto(id: 'p1', name: 'ماء', sku: 'WATER', kind: 'numeric', units: [ProductUnitBarcodeDto(unitName: 'piece', barcode: '123456', retailPrice: 10)]);
    await useCase.call('b1', product, 'idempotency-key-0001');
    await useCase.call('b1', product, 'idempotency-key-0001');
    expect((await repo.list('b1')).length, 1);
  });
  test('rejects product without a unit', () {
    final useCase = UpsertProductUseCase(InMemoryCatalogRepository());
    const product = ProductDto(id: 'p2', name: 'صنف', sku: 'SKU', kind: 'numeric', units: []);
    expect(() => useCase.call('b1', product, 'idempotency-key-0002'), throwsArgumentError);
  });
}
