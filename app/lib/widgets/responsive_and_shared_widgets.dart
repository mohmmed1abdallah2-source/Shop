import 'package:flutter/material.dart';

/// Responsive shell with compact and desktop layouts.
class ResponsiveShell extends StatelessWidget {
  /// Creates the shell.
  const ResponsiveShell({super.key, required this.title, required this.body});
  /// Page title.
  final String title;
  /// Page body.
  final Widget body;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 900) return Scaffold(appBar: AppBar(title: Text(title)), body: body);
    return Scaffold(body: Row(children: [const NavigationRail(selectedIndex: 0, destinations: [NavigationRailDestination(icon: Icon(Icons.inventory_2), label: Text('المنتجات'))]), const VerticalDivider(width: 1), Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: body)))]));
  }
}

/// Expandable record card for mobile layouts.
class SmartExpandableCard extends StatelessWidget {
  /// Creates an expandable card.
  const SmartExpandableCard({super.key, required this.title, required this.subtitle, required this.details});
  /// Main title.
  final String title;
  /// Secondary title.
  final String subtitle;
  /// Expanded details.
  final List<Widget> details;
  @override
  Widget build(BuildContext context) => Card(child: ExpansionTile(title: Text(title), subtitle: Text(subtitle), children: details));
}

/// Keyboard-aware modal sheet helper.
class KeyboardSafeModalSheet {
  /// Shows a scrollable sheet that accounts for the keyboard.
  static Future<T?> show<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(context: context, isScrollControlled: true, builder: (ctx) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom), child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => FocusManager.instance.primaryFocus?.unfocus(), child: SingleChildScrollView(child: builder(ctx)))));
}

/// Balance indicator using له / عليه / مسدد labels.
class PartyBalanceChip extends StatelessWidget {
  /// Creates a balance chip.
  const PartyBalanceChip({super.key, required this.amount, required this.isOwedToParty});
  /// Absolute balance.
  final num amount;
  /// Whether amount is owed to the party.
  final bool isOwedToParty;
  @override
  Widget build(BuildContext context) {
    final label = amount == 0 ? 'مسدَّد' : isOwedToParty ? 'له' : 'عليه';
    final color = amount == 0 || isOwedToParty ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    return Chip(label: Text(label + (amount == 0 ? '' : ' ' + amount.toString())), backgroundColor: color.withOpacity(.16), side: BorderSide(color: color));
  }
}
