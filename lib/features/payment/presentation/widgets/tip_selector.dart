// Driver-tip selector ("مكافأة سائق التوصيل"): a row of amount chips with an
// optional "الأكثر شعبية" badge and an "أخرى" (custom) chip.

import 'package:flutter/material.dart';
import 'package:sixam_mart/features/payment/presentation/keeta_pay_style.dart';

class TipOption {
  final double? amount; // null => custom ("أخرى")
  final String emoji;
  final bool popular;
  const TipOption({this.amount, this.emoji = '', this.popular = false});
}

class TipSelector extends StatelessWidget {
  final List<TipOption> options;
  final double? selected;
  final ValueChanged<double?> onSelected;
  final VoidCallback? onCustom;

  const TipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final s = KeetaPayStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مكافأة سائق التوصيل', style: s.t(16, weight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(
          'يستلم سائق التوصيل مبلغ الإكرامية بالكامل. ولا نقتطع أي جزء منه.',
          style: s.t(12, weight: FontWeight.w500, color: s.muted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < options.length; i++) ...[
              if (i != 0) const SizedBox(width: 9),
              Expanded(child: _chip(context, s, options[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, KeetaPayStyle s, TipOption o) {
    final bool custom = o.amount == null;
    final bool on = !custom && selected != null && selected == o.amount;
    return GestureDetector(
      onTap: () {
        if (custom) {
          onCustom?.call();
        } else {
          onSelected(o.amount);
        }
      },
      child: Container(
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: on ? s.greenSoft : s.card,
          border: Border.all(color: on ? s.green : s.border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (o.emoji.isNotEmpty)
                  Text(o.emoji, style: const TextStyle(fontSize: 15)),
                if (o.emoji.isNotEmpty) const SizedBox(height: 3),
                Text(
                  custom ? 'أخرى' : '${_fmt(o.amount!)} ﷼',
                  style: s.t(13,
                      weight: custom ? FontWeight.w700 : FontWeight.w800,
                      color: on
                          ? s.green
                          : (custom ? s.muted : s.ink)),
                ),
              ],
            ),
            if (o.popular)
              Positioned(
                top: -21,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: s.red,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'الأكثر شعبية',
                    style: TextStyle(
                      fontFamily: KeetaPayStyle.font,
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(2) : v.toString();
}
