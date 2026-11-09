import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/utils/scale_barcode_parser.dart';

/// Tests variable-measure EAN-13 decoding.
void main() {
  test('rejects malformed and non-scale barcodes', () {
    expect(ScaleBarcodeParser.parse('123'), isNull);
    expect(ScaleBarcodeParser.parse('4006381333931'), isNull);
  });
  test('validates checksum and decodes scale fields', () {
    const body = '200123400500';
    var sum = 0;
    for (var i = 0; i < body.length; i++) { sum += int.parse(body[i]) * (i.isEven ? 1 : 3); }
    final check = (10 - sum % 10) % 10;
    final parsed = ScaleBarcodeParser.parse(body + check.toString());
    expect(parsed, isNotNull);
    expect(parsed!.prefix, '20');
    expect(parsed.itemCode, '01234');
    expect(parsed.encodedValue, 500);
  });
}
