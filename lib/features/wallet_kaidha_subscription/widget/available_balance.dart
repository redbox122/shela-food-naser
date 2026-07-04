import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/wallet_kaidha_model.dart';
import 'package:sixam_mart/util/images.dart';

const String _fontTajawal = 'Tajawal';
const Color _primary = Color(0xFF31A342);
const Color _title = Color(0xFF000000);
const Color _outline = Color(0xFFE5E5E5);

class PaymentOptions extends StatefulWidget {
  final Wallet wallet;
  const PaymentOptions({super.key, required this.wallet});

  @override
  State<PaymentOptions> createState() => _PaymentOptionsState();
}

class _PaymentOptionsState extends State<PaymentOptions> {
  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final double usedBalanceAmount =
        _parseToDouble(widget.wallet.usedBalance) ?? 0.0;
    final double minimumDueAmount =
        _parseToDouble(widget.wallet.minimumDueLimit) ?? 0.0;

    final List<Map<String, dynamic>> list = [
      {'title': 'المبلغ المستحق بالكامل', 'amount': usedBalanceAmount},
      {'title': 'المبلغ الأدنى المستحق', 'amount': minimumDueAmount},
    ];

    return GetBuilder<KaidhaSubscriptionController>(
        builder: (KaidhaSubController) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'خيارات الدفع',
            style: TextStyle(
              fontFamily: _fontTajawal,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _title,
            ),
          ),
          ...List.generate(list.length, (int index) {
            final bool isSelected =
                KaidhaSubController.selectedPaymentOption == index;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: () => KaidhaSubController.selectPaymentOption(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEBFEEB)
                        : const Color(0xFFF6F5F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _primary : _outline,
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // النص والسعر بنفس العمود
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              list[index]['title'] as String,
                              style: const TextStyle(
                                fontFamily: _fontTajawal,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _title,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _AmountText(
                                amount: list[index]['amount'] as double),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // زر الاختيار في النهاية
                      _RadioDot(selected: isSelected),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected ? _primary : const Color(0xFFC5C5C5),
          width: 6,
        ),
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  final double amount;
  const _AmountText({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount.toStringAsFixed(2),
          style: const TextStyle(
            fontFamily: _fontTajawal,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _title,
          ),
        ),
        const SizedBox(width: 4),
        Image.asset(
          Images.sar,
          width: 14,
          height: 14,
          cacheWidth: 42,
          cacheHeight: 42,
          color: _title,
        ),
      ],
    );
  }
}
