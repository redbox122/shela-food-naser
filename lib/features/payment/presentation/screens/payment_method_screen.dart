// "طريقة الدفع" — approved Keeta-style native payment screen (phase 1).
//
// Purely presentational + local UI state. It takes the order total, wallet
// balance and tip options as inputs, and reports the user's choices back through
// [onPay]. Wiring it into the real checkout (and the MyFatoorah charge) is a
// separate, reviewed step — this screen touches no existing code.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/payment/presentation/keeta_pay_style.dart';
import 'package:sixam_mart/features/payment/presentation/screens/add_card_screen.dart';
import 'package:sixam_mart/features/payment/presentation/widgets/additional_info_section.dart';
import 'package:sixam_mart/features/payment/presentation/widgets/apple_pay_button.dart';
import 'package:sixam_mart/features/payment/presentation/widgets/payment_option_tile.dart';
import 'package:sixam_mart/features/payment/presentation/widgets/tip_selector.dart';

enum KeetaPayMethod { applePay, newCard, wallet }

class KeetaPaySelection {
  final KeetaPayMethod method;
  final double tip;
  final bool useWallet;
  final bool tableware;
  const KeetaPaySelection({
    required this.method,
    required this.tip,
    required this.useWallet,
    required this.tableware,
  });
}

class PaymentMethodScreen extends StatefulWidget {
  final double total;
  final double walletBalance;
  final String currency;
  final List<TipOption> tipOptions;
  final void Function(KeetaPaySelection selection)? onPay;

  const PaymentMethodScreen({
    super.key,
    required this.total,
    this.walletBalance = 0,
    this.currency = '﷼',
    this.onPay,
    this.tipOptions = const [
      TipOption(amount: null, emoji: ''),
      TipOption(amount: 5, emoji: '🍔'),
      TipOption(amount: 3, emoji: '🍗', popular: true),
      TipOption(amount: 1, emoji: '🥐'),
    ],
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  KeetaPayMethod _method = KeetaPayMethod.applePay;
  double? _tip;
  bool _useWallet = false;
  bool _tableware = true;

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final s = KeetaPayStyle.of(context);
    return Scaffold(
      backgroundColor: s.screen,
      appBar: AppBar(
        backgroundColor: s.screen,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 96,
        leading: TextButton(
          onPressed: () => Get.back<void>(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text('المزيد',
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: s.t(13.5, weight: FontWeight.w700, color: s.green)),
              ),
              Icon(Icons.chevron_left, color: s.green, size: 18),
            ],
          ),
        ),
        title: Text('طريقة الدفع', style: s.t(18, weight: FontWeight.w800)),
        actions: [Icon(Icons.chevron_right, color: s.muted, size: 22), const SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          children: [
            _optionsCard(s),
            const SizedBox(height: 20),
            TipSelector(
              options: widget.tipOptions,
              selected: _tip,
              onSelected: (t) => setState(() => _tip = t),
              onCustom: _showCustomTip,
            ),
            const SizedBox(height: 20),
            AdditionalInfoSection(
              tableware: _tableware,
              onTablewareChanged: (v) => setState(() => _tableware = v),
              onUnavailableTap: () {},
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(s),
    );
  }

  Widget _optionsCard(KeetaPayStyle s) {
    return Container(
      decoration: BoxDecoration(
        color: s.card,
        border: Border.all(color: s.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          PaymentOptionTile(
            leading: Icon(Icons.apple, color: s.ink, size: 22),
            title: 'Apple Pay',
            trailing: KeetaRadio(selected: _method == KeetaPayMethod.applePay),
            onTap: () => setState(() => _method = KeetaPayMethod.applePay),
          ),
          Divider(height: 1, color: s.border, indent: 15, endIndent: 15),
          PaymentOptionTile(
            leading: Icon(Icons.credit_card, color: s.ink, size: 21),
            title: 'إضافة بطاقة جديدة',
            brands: const [
              KeetaBrandChip('mada', KeetaBrandChip.mada),
              KeetaBrandChip('VISA', KeetaBrandChip.visa),
              KeetaBrandChip('MC', KeetaBrandChip.mc),
              KeetaBrandChip('AMEX', KeetaBrandChip.amex),
              KeetaBrandChip('UPI', KeetaBrandChip.unionpay),
            ],
            trailing: Icon(Icons.chevron_left, color: s.muted, size: 22),
            onTap: () {
              setState(() => _method = KeetaPayMethod.newCard);
              Get.to<void>(() => const AddCardScreen());
            },
          ),
          Divider(height: 1, color: s.border, indent: 15, endIndent: 15),
          PaymentOptionTile(
            leading: Icon(Icons.account_balance_wallet_outlined,
                color: s.amber, size: 21),
            title: 'المحفظة',
            subtitle: 'المجموع ${_fmt(widget.walletBalance)} ${widget.currency}',
            trailing: KeetaSwitch(
              value: _useWallet,
              onChanged: (v) => setState(() => _useWallet = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(KeetaPayStyle s) {
    return Container(
      decoration: BoxDecoration(
        color: s.card,
        border: Border(top: BorderSide(color: s.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          ApplePayButton(onPressed: _pay),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الإجمالي',
                  style: s.t(11.5, weight: FontWeight.w600, color: s.muted)),
              Text('${_fmt(widget.total)} ${widget.currency}',
                  style: s.t(18, weight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  void _pay() {
    widget.onPay?.call(KeetaPaySelection(
      method: _method,
      tip: _tip ?? 0,
      useWallet: _useWallet,
      tableware: _tableware,
    ));
  }

  void _showCustomTip() {
    final s = KeetaPayStyle.of(context);
    final controller = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: s.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('مبلغ آخر للإكرامية',
                textAlign: TextAlign.center,
                style: s.t(16, weight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: s.t(18, weight: FontWeight.w800),
              decoration: InputDecoration(
                filled: true,
                fillColor: s.field,
                suffixText: widget.currency,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: s.border),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: s.green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final v = double.tryParse(controller.text.trim());
                  Get.back<void>();
                  if (v != null && v > 0) setState(() => _tip = v);
                },
                child: Text('تأكيد',
                    style:
                        s.t(15, weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
