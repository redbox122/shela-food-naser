// Apple Pay styled button (black pill with Apple logo + "Pay"). Presentational —
// the actual PassKit/MyFatoorah call is wired by the caller via [onPressed].

import 'package:flutter/material.dart';
import 'package:sixam_mart/features/payment/presentation/keeta_pay_style.dart';

class ApplePayButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool block;
  final String label;
  const ApplePayButton({
    super.key,
    required this.onPressed,
    this.block = false,
    this.label = 'Pay',
  });

  @override
  Widget build(BuildContext context) {
    final s = KeetaPayStyle.of(context);
    final child = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.apple, color: Colors.white, size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: KeetaPayStyle.font,
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    return Material(
      color: s.payBlack,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: block ? 16 : 26),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
