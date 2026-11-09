/// Parsed value from a variable-measure EAN-13 scale barcode.
class ScaleBarcodeData {
  /// Creates parsed scale barcode data.
  const ScaleBarcodeData({required this.prefix, required this.itemCode, required this.encodedValue});
  /// Two-digit variable-measure prefix (20–29).
  final String prefix;
  /// Five-digit product reference encoded by the scale.
  final String itemCode;
  /// Five-digit weight or price field; its meaning is configured by the scale.
  final int encodedValue;
}

/// Validates and decodes common 13-digit variable-measure scale barcodes.
class ScaleBarcodeParser {
  /// Parses a valid EAN-13 barcode with a 20–29 variable-measure prefix.
  static ScaleBarcodeData? parse(String input) {
    final code = input.trim();
    if (!RegExp(r'^\d{13}$').hasMatch(code) || !hasValidChecksum(code)) return null;
    final prefix = code.substring(0, 2);
    final prefixValue = int.parse(prefix);
    if (prefixValue < 20 || prefixValue > 29) return null;
    return ScaleBarcodeData(prefix: prefix, itemCode: code.substring(2, 7), encodedValue: int.parse(code.substring(7, 12)));
  }

  /// Checks the EAN-13 weighted modulo-10 check digit.
  static bool hasValidChecksum(String code) {
    if (!RegExp(r'^\d{13}$').hasMatch(code)) return false;
    var sum = 0;
    for (var index = 0; index < 12; index++) {
      sum += int.parse(code[index]) * (index.isEven ? 1 : 3);
    }
    return (10 - sum % 10) % 10 == int.parse(code[12]);
  }
}
