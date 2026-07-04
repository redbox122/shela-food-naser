import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class CancellationDialogueWidget extends StatefulWidget {
  final int? orderId;
  const CancellationDialogueWidget({super.key, required this.orderId});

  @override
  State<CancellationDialogueWidget> createState() => _CancellationDialogueWidgetState();
}

class _CancellationDialogueWidgetState extends State<CancellationDialogueWidget> {
  String get _introMessageAr =>
      'ord_dear_customer'.tr + 'ord_cancel_intro'.tr;

  Map<String, List<String>> get _groupedReasonsAr => <String, List<String>>{
        'ord_reasons_purchase'.tr: <String>[
          'ord_reason_change_payment'.tr,
          'ord_reason_add_items'.tr,
          'ord_reason_no_need'.tr,
        ],
        'ord_reasons_shipping'.tr: <String>[
          'ord_reason_eta'.tr,
          'ord_reason_high_shipping'.tr,
          'ord_reason_duplicate'.tr,
        ],
        'ord_reasons_product'.tr: <String>[
          'ord_reason_wrong_variant'.tr,
          'ord_reason_better_offer'.tr,
          'ord_reason_reorder_coupon'.tr,
        ],
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<OrderController>().getOrderCancelReasons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      insetPadding: const EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: GetBuilder<OrderController>(builder: (orderController) {
        return SizedBox(
          width: 500,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(children: [
            Container(
              width: 500,
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
              ),
              child: Column(children: [
                Text('select_cancellation_reasons'.tr,
                    style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Text(
                    _introMessageAr,
                    textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                children: _groupedReasonsAr.entries.map((entry) {
                  final String sectionTitle = entry.key;
                  final List<String> reasons = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: Dimensions.paddingSizeSmall,
                          bottom: Dimensions.paddingSizeExtraSmall,
                        ),
                        child: Text(
                          sectionTitle,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                        ),
                      ),
                      ...reasons.map((reason) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onTap: () => orderController.setOrderCancelReason(reason),
                          title: Row(
                            children: [
                              Icon(
                                reason == orderController.cancelReason
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: Theme.of(context).primaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: robotoRegular,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.fontSizeDefault, vertical: Dimensions.paddingSizeSmall),
              child: !orderController.isLoading
                  ? Row(children: [
                      Expanded(
                          child: CustomButton(
                        buttonText: 'cancel'.tr,
                        color: Theme.of(context).disabledColor,
                        radius: 50,
                        onPressed: () => Get.back(),
                      )),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                          child: CustomButton(
                        buttonText: 'submit'.tr,
                        radius: 50,
                        onPressed: () {
                          debugPrint('[OrderCancel][UI] submit pressed reason=${orderController.cancelReason} orderId=${widget.orderId}');
                          if (orderController.cancelReason != '' && orderController.cancelReason != null) {
                            orderController.cancelOrder(widget.orderId, orderController.cancelReason).then((success) {
                              debugPrint('[OrderCancel][UI] submit result=$success');
                              if (success) {
                                // Success/failure refund message is already handled
                                // in cancelOrder repository response using backend flags
                                // (e.g. refund_processed=false for non-refundable cases).
                                Future.delayed(const Duration(milliseconds: 1200), () {
                                  if (Get.currentRoute != RouteHelper.initial) {
                                    Get.offAllNamed(RouteHelper.getInitialRoute());
                                  }
                                });
                              }
                            });
                          } else {
                            if (Get.isDialogOpen!) {
                              Get.back();
                            }

                            showCustomSnackBar('you_did_not_select_select_any_reason'.tr);
                          }
                        },
                      )),
                    ])
                  : const Center(child: CircularProgressIndicator()),
            ),
          ]),
        );
      }),
    );
  }
}
