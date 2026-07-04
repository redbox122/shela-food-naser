import 'package:flutter/material.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// ✅ DATA-DRIVEN MORPHING: Priority 2 — eCommerce variations
/// (choiceOptions + variations). Renders each choice option's title with a
/// 3-column grid of selectable option chips driven by the controller's
/// [ItemController.variationIndex].
class EcommerceVariationSelector extends StatelessWidget {
  final ItemController itemController;

  const EcommerceVariationSelector({super.key, required this.itemController});

  @override
  Widget build(BuildContext context) {
    final item = itemController.item!;
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: item.choiceOptions!.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.choiceOptions![index].title!,
                      style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge)),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 10,
                      childAspectRatio: (1 / 0.25),
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: item.choiceOptions![index].options!.length,
                    itemBuilder: (context, i) {
                      final bool isUnselected = itemController.variationIndex !=
                              null &&
                          index < itemController.variationIndex!.length &&
                          itemController.variationIndex![index] != i;
                      return InkWell(
                        onTap: () {
                          itemController.setCartVariationIndex(
                              index, i, itemController.item);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeExtraSmall),
                          decoration: BoxDecoration(
                            color: isUnselected
                                ? Theme.of(context).disabledColor
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(5),
                            border: isUnselected
                                ? Border.all(
                                    color: Theme.of(context).disabledColor,
                                    width: 2)
                                : null,
                          ),
                          child: Text(
                            item.choiceOptions![index].options![i].trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(
                              color: isUnselected ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                      height: index != item.choiceOptions!.length - 1
                          ? Dimensions.paddingSizeLarge
                          : 0),
                ]);
          },
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ],
    );
  }
}
