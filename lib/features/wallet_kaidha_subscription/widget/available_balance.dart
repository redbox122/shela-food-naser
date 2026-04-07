
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/wallet_kaidha_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/styles.dart';

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
    final double usedBalanceAmount = _parseToDouble(widget.wallet.usedBalance) ?? 0.0;
    final double minimumDueAmount = _parseToDouble(widget.wallet.minimumDueLimit) ?? 0.0;
    
    final List<Map<String, dynamic>> list = [
      {
        'title': 'المبلغ المستحق بالكامل',
        'amount': usedBalanceAmount,
      },
      {
        'title': 'المبلغ الأدنى المستحق',
        'amount': minimumDueAmount,
      },
    ];
    return GetBuilder<KaidhaSubscription_Controller>(
        builder: (KaidhaSubController) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Custom_Text(context,
                  text: 'خيارات الدفع', style: font14Black500W(context)),
              Column(
                children: List.generate(
                  list.length,
                  (int index) => Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GestureDetector(
                      onTap: () {
                        // Select payment option (0=Full, 1=Minimum)
                        KaidhaSubController.selectPaymentOption(index);
                      },
                      child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey)),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Custom_Text(context,
                                          text: list[index]['title'] as String,
                                          style: font13Black400W(context)),
                                      const SizedBox(height: 5),
                                      PriceConverter.convertPrice2(
                                          list[index]['amount'] as double)
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // ignore: deprecated_member_use
                                Radio<int>(
                                  value: index,
                                  // ignore: deprecated_member_use
                                  groupValue: KaidhaSubController.selectedPaymentOption,
                                  // ignore: deprecated_member_use
                                  onChanged: (int? value) {
                                    // Select payment option (0=Full, 1=Minimum)
                                    if (value != null) {
                                      KaidhaSubController.selectPaymentOption(value);
                                    }
                                  },
                                  fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.green;
                                    }
                                    return Theme.of(context).unselectedWidgetColor;
                                  }),
                                )
                              ],
                            ),
                          )),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      );
    });
  }
}
