import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';

class SlotWidget extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Function onTap;
  const SlotWidget({super.key, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();
    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap as void Function()?,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeExtraSmall),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : theme.cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            boxShadow: [
              BoxShadow(
                color: (tokens?.outlineSoft ?? theme.dividerColor)
                    .withValues(alpha: 0.35),
                spreadRadius: 0.5,
                blurRadius: 0.5,
              )
            ],),
          child: Text(
            title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(
              color: isSelected ? theme.cardColor : theme.textTheme.bodyLarge!.color,
              fontSize: Dimensions.fontSizeExtraSmall,
            ),
          ),
        ),
      ),
    );
  }
}
