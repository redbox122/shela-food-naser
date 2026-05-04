import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Built-in address types use GetX translations; any other value is shown as
/// the API/custom label (Arabic, English, or mixed) without `.tr` lookup.
String _resolveAddressCardTitleText(String? addressType) {
  if (addressType == null || addressType.isEmpty) {
    return '';
  }
  final String trimmed = addressType.trim();
  final String lower = trimmed.toLowerCase();
  if (lower == 'home' || lower == 'office' || lower == 'others') {
    return lower.tr;
  }
  return trimmed;
}

TextDirection? _resolveAddressCardTitleDirection(String titleText) {
  if (titleText.isEmpty) {
    return null;
  }
  final bool hasArabic =
      titleText.runes.any((int r) => r >= 0x0600 && r <= 0x06FF);
  final bool hasLatin = RegExp(r'[A-Za-z]').hasMatch(titleText);
  if (hasLatin && !hasArabic) {
    return TextDirection.ltr;
  }
  return null;
}

class AddressWidget extends StatelessWidget {
  final AddressModel? address;
  final bool fromAddress;
  final bool fromCheckout;
  final Function? onRemovePressed;
  final Function? onEditPressed;
  final Function? onTap;
  final bool isSelected;
  final bool fromDashBoard;
  final bool showRadioButton;
  final String? radioGroupValue;
  final String? radioValue;
  final ValueChanged<String?>? onRadioChanged;
  const AddressWidget(
      {super.key,
      required this.address,
      required this.fromAddress,
      this.onRemovePressed,
      this.onEditPressed,
      this.onTap,
      this.fromCheckout = false,
      this.isSelected = false,
      this.fromDashBoard = false,
      this.showRadioButton = false,
      this.radioGroupValue,
      this.radioValue,
      this.onRadioChanged});

  @override
  Widget build(BuildContext context) {
    final AddressModel? model = address;
    final String titleText = _resolveAddressCardTitleText(model?.addressType);
    final String subtitleText = (model?.address ?? '').trim();
    if (kDebugMode) {
      debugPrint(
        '[AddressCard][DATA] id=${model?.id} addressType=${model?.addressType} '
        'label=${model?.addressType} address=${model?.address} '
        'contactPerson=${model?.contactPersonName} road=${model?.streetNumber} '
        'house=${model?.house} floor=${model?.floor}',
      );
      debugPrint(
        '[AddressCard][RENDER] titleText=$titleText subtitleText=$subtitleText',
      );
      if (titleText.isEmpty && model != null) {
        debugPrint(
          '[AddressCard][INVESTIGATE] Empty title after resolve; '
          'payload=${jsonEncode(model.toJson())}',
        );
      }
    }
    return Padding(
      padding: EdgeInsets.only(
          bottom: fromCheckout ? 0 : Dimensions.paddingSizeSmall),
      child: Container(
        decoration: fromDashBoard
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: isSelected ? 1 : 0),
              )
            : fromCheckout
                ? const BoxDecoration()
                : BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).cardColor,
                        width: isSelected ? 0.5 : 0),
                    boxShadow: [
                      BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          blurRadius: 5,
                          spreadRadius: 1)
                    ],
                  ),
        child: CustomInkWell(
          onTap: onTap as void Function()?,
          radius: fromDashBoard
              ? Dimensions.radiusDefault
              : fromCheckout
                  ? 0
                  : Dimensions.radiusSmall,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context)
                ? Dimensions.paddingSizeDefault
                : Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                // Radio Button (if enabled)
                if (showRadioButton && onRadioChanged != null) ...[
                  // ignore: deprecated_member_use
                  Radio<String>(
                    value: radioValue ?? '',
                    // ignore: deprecated_member_use
                    groupValue: radioGroupValue,
                    // ignore: deprecated_member_use
                    onChanged: onRadioChanged!,
                    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).primaryColor;
                      }
                      return Theme.of(context).unselectedWidgetColor;
                    }),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                ],

                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              model?.addressType?.toLowerCase() == 'home'
                                  ? Images.homeIcon
                                  : model?.addressType?.toLowerCase() ==
                                          'office'
                                      ? Images.workIcon
                                      : Images.otherIcon,
                              color: Theme.of(context).primaryColor,
                              height: ResponsiveHelper.isDesktop(context)
                                  ? 25
                                  : 20,
                              width: ResponsiveHelper.isDesktop(context)
                                  ? 25
                                  : 20,
                            ),
                            const SizedBox(
                                width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: Text(
                                titleText,
                                textDirection:
                                    _resolveAddressCardTitleDirection(titleText),
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall),
                        Text(
                          subtitleText,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                ),

                // Edit and Delete Icons (always show when fromAddress is true)
                if (fromAddress) ...[
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: Colors.blueGrey, size: 25),
                    onPressed: onEditPressed as void Function()?,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 25),
                    onPressed: onRemovePressed as void Function()?,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
