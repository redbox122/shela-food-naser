import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class NoteAndPrescriptionSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final int? storeId;
  const NoteAndPrescriptionSection({
    super.key,
    required this.checkoutController,
    this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 🎨 Label — Tajawal Bold 14, line-height 160%.
      Text('additional_note'.tr,
          textAlign: TextAlign.right,
          style: tajawalBold.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.6,
            letterSpacing: 0,
          )),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      // 🎨 Note field — borderless, height 56, radius 12, padding 8/12.
      Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: checkoutController.noteController,
          maxLines: 3,
          minLines: 1,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          textAlign: TextAlign.right,
          style: tajawalMedium.copyWith(fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: 'please_provide_extra_napkin'.tr,
            hintStyle: tajawalMedium.copyWith(
              fontSize: 14,
              height: 1.6,
              letterSpacing: 0,
              color: const Color(0xFF717885),
            ),
          ),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeLarge),

      /*storeId == null && Get.find<SplashController>().configModel!.moduleConfig!.module!.orderAttachment! ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('prescription'.tr, style: robotoMedium),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            Text(
              '(${'max_size_2_mb'.tr})',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          ImagePickerWidget(
            image: '', rawFile: checkoutController.rawAttachment,
            onTap: () => checkoutController.pickImage(),
          ),
        ],
      ) : const SizedBox(),*/
    ]);
  }
}
