import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/akhdamni/akhdamni_service_icon.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

abstract final class AkhdamniUi {
  static const Color unselectedBorder = Color(0xFFE4E4E4);
  static const double cardRadius = 16;
  static const double gridRadius = 14;
}

class AkhdamniSectionTitle extends StatelessWidget {
  const AkhdamniSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          textDirection: TextDirection.rtl,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            height: 1.35,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            subtitle!,
            textAlign: TextAlign.start,
            textDirection: TextDirection.rtl,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).hintColor,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class AkhdamniGreenButton extends StatelessWidget {
  const AkhdamniGreenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.38),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeLarge,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class AkhdamniSelectableTypeCard extends StatelessWidget {
  const AkhdamniSelectableTypeCard({
    super.key,
    required this.title,
    required this.icon,
    this.assetFileName,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String? assetFileName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color borderColor =
        isSelected ? primaryColor : AkhdamniUi.unselectedBorder;
    final Color iconColor =
        isSelected ? primaryColor : Theme.of(context).hintColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AkhdamniUi.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 128),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeLarge,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.06)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AkhdamniUi.cardRadius),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AkhdamniServiceIcon(
                icon: icon,
                assetFileName: assetFileName,
                size: 40,
                color: iconColor,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                title,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AkhdamniServiceGridItem extends StatelessWidget {
  const AkhdamniServiceGridItem({
    super.key,
    required this.label,
    required this.icon,
    this.assetFileName,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? assetFileName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AkhdamniUi.gridRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AkhdamniUi.gridRadius),
          border: Border.all(
            color: isSelected ? primaryColor : AkhdamniUi.unselectedBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AkhdamniServiceIcon(
              icon: icon,
              assetFileName: assetFileName,
              size: 30,
              color: isSelected ? primaryColor : Theme.of(context).hintColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: isSelected
                    ? primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.25,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AkhdamniWorkshopCard extends StatelessWidget {
  const AkhdamniWorkshopCard({
    super.key,
    required this.name,
    required this.description,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.imageWidget,
    this.onTap,
  });

  final String name;
  final String description;
  final String location;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final Widget imageWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AkhdamniUi.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AkhdamniUi.cardRadius),
            border: Border.all(color: AkhdamniUi.unselectedBorder),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AkhdamniUi.cardRadius),
                ),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: imageWidget,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.rtl,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 16, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '${rating.toStringAsFixed(1)} ($reviewCount)',
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.place_outlined,
                            size: 15, color: Theme.of(context).hintColor),
                        const SizedBox(width: 4),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} كم',
                          textDirection: TextDirection.rtl,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      textAlign: TextAlign.start,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      textAlign: TextAlign.start,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location,
                      textAlign: TextAlign.start,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
