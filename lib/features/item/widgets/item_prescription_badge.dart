import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// "* prescription required" badge, shown only when the item requires a
/// prescription. Collapses to nothing otherwise.
class ItemPrescriptionBadge extends StatelessWidget {
  final Item? item;

  const ItemPrescriptionBadge({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // ⚠️ Null-safe check: the mini-cache may not include this field.
    if (item?.isPrescriptionRequired != true) {
      return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeExtraSmall),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Text(
        '* ${'prescription_required'.tr}',
        style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
