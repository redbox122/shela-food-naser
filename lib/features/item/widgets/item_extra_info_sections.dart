import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Extra (secondary) product info: description, nutrition details and allergic
/// ingredients. Hidden as a group via [show] (the new design omits them), with
/// each section additionally gated on its own data being present.
///
/// [controllerItem] is the fully-loaded item from the controller; [widgetItem]
/// is the originally-passed item (which carries the nutrition/allergy tag
/// lists). Logic/data loading stays intact — only visibility is gated.
class ItemExtraInfoSections extends StatelessWidget {
  final bool show;
  final Item? controllerItem;
  final Item? widgetItem;

  const ItemExtraInfoSections({
    super.key,
    required this.show,
    required this.controllerItem,
    required this.widgetItem,
  });

  /// Check if text contains English characters (A-Z, a-z)
  bool _containsEnglishText(String text) {
    return RegExp(r'[A-Za-z]').hasMatch(text);
  }

  /// Check if nutrition section has any data to display
  bool _hasNutritionData() {
    final nutrition = controllerItem?.nutrition;
    if (nutrition == null) {
      return widgetItem?.nutritionsName != null &&
          widgetItem!.nutritionsName!.isNotEmpty;
    }
    return (nutrition.calories != null && nutrition.calories! > 0) ||
        nutrition.protein != null ||
        nutrition.carbs != null ||
        nutrition.fat != null ||
        nutrition.fiber != null ||
        (widgetItem?.nutritionsName != null &&
            widgetItem!.nutritionsName!.isNotEmpty);
  }

  /// Check if allergies should be shown. Returns false if the app is in Arabic
  /// and the allergy names are in English.
  bool _shouldShowAllergies(List<String>? allergiesName) {
    if (allergiesName == null || allergiesName.isEmpty) {
      return false;
    }
    try {
      final isArabic =
          Get.find<LocalizationController>().locale.languageCode == 'ar';
      if (isArabic) {
        for (final String allergy in allergiesName) {
          if (_containsEnglishText(allergy)) {
            return false;
          }
        }
      }
      return true;
    } catch (e) {
      // If LocalizationController is not available, show anyway
      return true;
    }
  }

  Widget _nutritionItem(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _description(),
        _nutrition(context),
        _allergies(context),
      ],
    );
  }

  Widget _description() {
    final bool hasData = show &&
        controllerItem?.description != null &&
        controllerItem!.description!.isNotEmpty;
    if (!hasData) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('description'.tr, style: robotoMedium),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(controllerItem!.description!, style: robotoRegular),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ],
    );
  }

  Widget _nutrition(BuildContext context) {
    if (!(show && _hasNutritionData())) return const SizedBox();
    final nutrition = controllerItem?.nutrition;
    final List<String>? tags = widgetItem?.nutritionsName;
    final bool hasTags = tags != null && tags.isNotEmpty;

    Widget tagsWrap() => Wrap(
          children: List.generate(tags!.length, (index) {
            return Text(
              '${tags[index]}${tags.length - 1 == index ? '.' : ', '}',
              style: robotoRegular.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .color
                    ?.withValues(alpha: 0.5),
              ),
            );
          }),
        );

    if (nutrition != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('nutrition_details'.tr, style: robotoMedium),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          // Calories
          if (nutrition.calories != null && nutrition.calories! > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department,
                      size: 18, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${nutrition.calories} ${'calories'.tr}',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ],
              ),
            ),
          // Nutrition breakdown
          if (nutrition.protein != null ||
              nutrition.carbs != null ||
              nutrition.fat != null ||
              nutrition.fiber != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (nutrition.protein != null)
                    _nutritionItem(context, 'protein'.tr,
                        '${nutrition.protein!.toStringAsFixed(1)}g'),
                  if (nutrition.carbs != null)
                    _nutritionItem(context, 'carbs'.tr,
                        '${nutrition.carbs!.toStringAsFixed(1)}g'),
                  if (nutrition.fat != null)
                    _nutritionItem(context, 'fat'.tr,
                        '${nutrition.fat!.toStringAsFixed(1)}g'),
                  if (nutrition.fiber != null)
                    _nutritionItem(context, 'fiber'.tr,
                        '${nutrition.fiber!.toStringAsFixed(1)}g'),
                ],
              ),
            ),
          // Nutrition tags (if available)
          if (hasTags) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            tagsWrap(),
          ],
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
      );
    }

    // Fallback to nutrition tags only if the nutrition object is null.
    if (hasTags) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('nutrition_details'.tr, style: robotoMedium),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          tagsWrap(),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _allergies(BuildContext context) {
    if (!(show && _shouldShowAllergies(widgetItem?.allergiesName))) {
      return const SizedBox();
    }
    final List<String> allergies = widgetItem!.allergiesName!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('allergic_ingredients'.tr, style: robotoMedium),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Wrap(
          children: List.generate(allergies.length, (index) {
            return Text(
              '${allergies[index]}${allergies.length - 1 == index ? '.' : ', '}',
              style: robotoRegular.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .color
                      ?.withValues(alpha: 0.5)),
            );
          }),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ],
    );
  }
}
