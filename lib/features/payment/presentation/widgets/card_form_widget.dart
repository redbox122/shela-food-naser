// Card form UI (approved design). NOTE: for the Saudi MyFatoorah account the
// real card entry must go through MyFatoorah's PCI-compliant Embedded widget —
// these fields render the approved look for phase 1 and are swapped for the
// embedded session in phase 2. No raw PAN leaves the device from here yet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/features/payment/presentation/keeta_pay_style.dart';
import 'package:sixam_mart/features/payment/presentation/widgets/payment_option_tile.dart';

class CardFormWidget extends StatefulWidget {
  final bool showError;
  const CardFormWidget({super.key, this.showError = false});

  @override
  State<CardFormWidget> createState() => _CardFormWidgetState();
}

class _CardFormWidgetState extends State<CardFormWidget> {
  bool saveAsDefault = true;

  @override
  Widget build(BuildContext context) {
    final s = KeetaPayStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand chips row
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 6,
          children: const [
            KeetaBrandChip('UnionPay', KeetaBrandChip.unionpay, fontSize: 11),
            KeetaBrandChip('AMEX', KeetaBrandChip.amex, fontSize: 11),
            KeetaBrandChip('MC', KeetaBrandChip.mc, fontSize: 11),
            KeetaBrandChip('VISA', KeetaBrandChip.visa, fontSize: 11),
            KeetaBrandChip('mada', KeetaBrandChip.mada, fontSize: 11),
          ],
        ),
        const SizedBox(height: 16),
        _field(
          s,
          hint: 'يُرجى إدخال رقم البطاقة المصرفية',
          error: widget.showError,
          keyboard: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
          ],
          suffix: Icon(Icons.credit_card, color: s.muted, size: 20),
        ),
        if (widget.showError)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 4),
            child: Text('رقم البطاقة لا يمكن أن يكون فارغًا',
                style: s.t(11.5, weight: FontWeight.w500, color: s.red)),
          ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _field(s,
                  hint: 'الشهر / السنة',
                  keyboard: TextInputType.number,
                  prefix: Icon(Icons.info_outline, color: s.muted, size: 18)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _field(s,
                  hint: 'CVV / CVC',
                  keyboard: TextInputType.number,
                  obscure: true,
                  prefix: Icon(Icons.info_outline, color: s.muted, size: 18)),
            ),
          ],
        ),
        const SizedBox(height: 11),
        _field(s, hint: 'يُرجى إدخال الاسم الموجود على البطاقة'),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                  child: Text('حفظ كطريقة الدفع الأساسية', style: s.t(14.5))),
              KeetaSwitch(
                  value: saveAsDefault,
                  onChanged: (v) => setState(() => saveAsDefault = v)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _securityBox(s),
      ],
    );
  }

  Widget _field(
    KeetaPayStyle s, {
    required String hint,
    bool error = false,
    bool obscure = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    Widget? prefix,
    Widget? suffix,
  }) {
    return TextField(
      obscureText: obscure,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: s.t(13.5, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: s.t(13.5, weight: FontWeight.w500, color: s.muted),
        filled: true,
        fillColor: s.field,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        prefixIcon: prefix == null
            ? null
            : Padding(padding: const EdgeInsets.only(left: 8), child: prefix),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 20),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: error ? s.red : s.border, width: error ? 1.4 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error ? s.red : s.green, width: 1.4),
        ),
      ),
    );
  }

  Widget _securityBox(KeetaPayStyle s) {
    const points = [
      'ملتزمون بمعيار أمان بيانات البطاقات (PCI DSS)',
      'معلومات البطاقة مشفّرة بالكامل ولا تُشارك مع أي طرف',
      'لا تُباع معلومات بطاقتك بتاتًا',
      'عند أي تفويض مسبق يُعاد المبلغ فورًا',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: s.greenSoft,
        border: Border.all(color: s.green.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: s.green, size: 17),
              const SizedBox(width: 6),
              Text('تحمي شله معلومات بطاقتك',
                  style: s.t(13, weight: FontWeight.w800, color: s.green)),
            ],
          ),
          const SizedBox(height: 9),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, color: s.green, size: 14),
                  const SizedBox(width: 7),
                  Expanded(
                      child: Text(p,
                          style: s.t(11.5, weight: FontWeight.w500))),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final b in const [
                'SafeKey',
                'ID Check',
                'Visa Secure',
                '3-D Secure'
              ])
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: s.card,
                    border: Border.all(color: s.border),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(b,
                      style: s.t(8.5, weight: FontWeight.w800, color: s.muted)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
