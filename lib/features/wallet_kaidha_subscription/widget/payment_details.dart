import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_text.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/wallet_kaidha_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/styles.dart';

class PaymentDetails extends StatelessWidget {
  final Wallet wallet;
  const PaymentDetails({super.key, required this.wallet});

  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // details of balance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Custom_Text(context,
                              text: 'تاريخ انتهاء الشهر :',
                              style: font14Black500W(context)),
                          const SizedBox(width: 5),
                          Custom_Text(context,
                              text: wallet.lockDay != null ? wallet.lockDay.toString() : 'N/A',
                              style: font16SecondaryColor400W(context)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Custom_Text(context,
                                text: wallet.serialNumber != null ? wallet.serialNumber.toString() : 'N/A',
                                style: font13Green500W(context, size: 20)),
                          ),
                          // Contract viewing button
                          if (wallet.signatureStatus == 1 &&
                              wallet.signaturePath != null &&
                              wallet.signaturePath.toString().isNotEmpty)
                            GestureDetector(
                              onTap: () async {
                                // Show loading indicator
                                Get.dialog(
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text('جاري تحميل العقد...',
                                              style: font14Black500W(context)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  barrierDismissible: false,
                                );

                                try {
                                  // Load contract PDF
                                  await Get.find<
                                          KaidhaSubscription_Controller>()
                                      .get_Pdf();

                                  // Close loading dialog
                                  Get.back();

                                  // Navigate to contract review screen
                                  Get.toNamed(
                                      RouteHelper.getContract_ReviewRoute());
                                } catch (e) {
                                  // Close loading dialog
                                  Get.back();

                                  // Show error message
                                  Get.snackbar(
                                    'خطأ',
                                    'فشل في تحميل العقد. يرجى المحاولة مرة أخرى.',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      color: Colors.blue.shade600,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'عرض العقد',
                                      style: TextStyle(
                                        color: Colors.blue.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          Custom_Text(context,
                              text: 'قيدها', style: font13Black400W(context)),
                          Custom_Text(context,
                              text: ' | ',
                              style: const TextStyle(color: Colors.grey)),
                          Custom_Text(context,
                              text: wallet.status == 'Pending'
                                  ? 'pending'.tr
                                  : wallet.status == 'Active'
                                      ? 'available'.tr
                                      : 'closed_now'.tr,
                              style: font16SecondaryColor400W(context)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            // available balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Custom_Text(context,
                    text: 'الرصيد المتاح', style: font13Black400W(context)),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PriceConverter.convertPrice2(
                      (_parseToDouble(wallet.creditLimit) ?? 0.0),
                      textStyle: font11Black400W(context),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                LinearProgressIndicator(
                  value: ((_parseToDouble(wallet.usedPercentage) ?? 0.0)) / 100,
                  backgroundColor: Colors.grey,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    Custom_Text(context,
                        text: 'حدد البطاقة', style: font13Grey400W(context)),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PriceConverter.convertPrice2(
                          (_parseToDouble(wallet.availableBalance) ?? 0.0),
                          textStyle: font13Grey400W(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ========================================================================================================

class PaymentDetailsShimmer extends StatelessWidget {
  const PaymentDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // details of balance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Custom_Text(context,
                              text: 'تاريخ انتهاء الشهر :',
                              style: font14Black500W(context)),
                          const SizedBox(width: 5),
                          Custom_Text(context,
                              text: 'yyyy/MM/dd',
                              style: font16SecondaryColor400W(context)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Custom_Text(context,
                          text: 'XXX  XXXX XXXXX',
                          style: font13Green500W(context, size: 20)),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          Custom_Text(context,
                              text: 'قيدها', style: font13Black400W(context)),
                          Custom_Text(context,
                              text: ' | ',
                              style: const TextStyle(color: Colors.grey)),
                          Custom_Text(context,
                              text: 'لا توجد محفظة',
                              style: font16SecondaryColor400W(context)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            // available balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Custom_Text(context,
                    text: 'الرصيد المتاح', style: font13Black400W(context)),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PriceConverter.convertPrice2(
                      0.00,
                      textStyle: font11Black400W(context),
                      prefixText: 'ر.س ',
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const LinearProgressIndicator(
                  value: 0 / 100,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    Custom_Text(context,
                        text: 'حدد البطاقة', style: font13Grey400W(context)),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PriceConverter.convertPrice2(
                          0.00,
                          textStyle: font13Grey400W(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
