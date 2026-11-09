import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/widgets/responsive_and_shared_widgets.dart';

/// Widget test for approved balance vocabulary.
void main() {
  testWidgets('uses له and عليه labels', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PartyBalanceChip(amount: 12, isOwedToParty: true))));
    expect(find.textContaining('له'), findsOneWidget);
    expect(find.textContaining('مدين'), findsNothing);
    expect(find.textContaining('دائن'), findsNothing);
  });
}
