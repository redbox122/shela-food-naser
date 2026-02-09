import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VegFilterWidget extends StatelessWidget {
  final String? type;
  final bool fromAppBar;
  final void Function(String value)? onSelected;
  const VegFilterWidget({super.key, required this.type, required this.onSelected, this.fromAppBar = false});

  @override
  Widget build(BuildContext context) {
    // ✅ DEFENSIVE: Check if ItemController is registered before using it
    if (!Get.isRegistered<ItemController>()) {
      // ItemController not available - return empty widget
      return const SizedBox();
    }
    
    // ✅ DEFENSIVE: Try-catch to handle lazy initialization failures
    ItemController? itemController;
    try {
      itemController = Get.find<ItemController>();
    } catch (e) {
      // ItemController not initialized yet or failed to initialize
      return const SizedBox();
    }
    
    // Store in final variable for null safety
    final ItemController controller = itemController;
    final bool ltr = Get.find<LocalizationController>().isLtr;
    final List<PopupMenuEntry<int>> entryList = <PopupMenuEntry<int>>[];
    
    for(int i=0; i < controller.itemTypeList.length; i++){
      entryList.add(PopupMenuItem<int>(value: i, child: Row(children: [
        controller.itemTypeList[i] == type
            ? Icon(Icons.radio_button_checked_sharp, color: Theme.of(context).primaryColor)
            : Icon(Icons.radio_button_off, color: Theme.of(context).disabledColor),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

        Text(
          controller.itemTypeList[i].tr,
          style: robotoMedium.copyWith(color: controller.itemTypeList[i] == type
              ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).disabledColor),
        ),
      ])));
    }

    return (Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg!) ? Padding(
      padding: fromAppBar ? EdgeInsets.zero : EdgeInsets.only(left: ltr ? Dimensions.paddingSizeSmall : 0, right: ltr ? 0 : Dimensions.paddingSizeSmall),
      child: PopupMenuButton<int>(
        offset: const Offset(-20, 20),
        itemBuilder: (BuildContext context) => entryList,
        onSelected: (int value) => onSelected!(controller.itemTypeList[value]),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
        ),
        child: Container(
          decoration: fromAppBar ? const BoxDecoration() : BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).primaryColor)
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: const Icon(Icons.filter_list, size: 24),
        ),
      ),
    ) : const SizedBox();
  }
}
