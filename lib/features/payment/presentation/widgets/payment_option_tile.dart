// A single row inside the payment-methods card: leading icon, title (+ optional
// subtitle / brand chips), and a trailing control (radio, chevron or switch).

import 'package:flutter/material.dart';
import 'package:sixam_mart/features/payment/presentation/keeta_pay_style.dart';

class PaymentOptionTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final List<Widget>? brands;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool dimmed;

  const PaymentOptionTile({
    super.key,
    required this.leading,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.brands,
    this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = KeetaPayStyle.of(context);
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              SizedBox(width: 26, child: Center(child: leading)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: s.t(14.5)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: s.t(12,
                              weight: FontWeight.w500, color: s.muted)),
                    ],
                    if (brands != null && brands!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 5, runSpacing: 4, children: brands!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// The green selection radio used by the Apple Pay row.
class KeetaRadio extends StatelessWidget {
  final bool selected;
  const KeetaRadio({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final s = KeetaPayStyle.of(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? s.green : s.border, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(shape: BoxShape.circle, color: s.green),
              ),
            )
          : null,
    );
  }
}

/// A rounded toggle matching the approved design (green or amber when on).
class KeetaSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool amber;
  const KeetaSwitch(
      {super.key, required this.value, required this.onChanged, this.amber = false});

  @override
  Widget build(BuildContext context) {
    final s = KeetaPayStyle.of(context);
    final onColor = amber ? s.amber : s.green;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 27,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerLeft : Alignment.centerRight,
        decoration: BoxDecoration(
          color: value ? onColor : s.border,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          width: 21,
          height: 21,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
