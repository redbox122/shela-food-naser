import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/images.dart';

/// Circular image with primary ring + soft shadow (categories, brands, etc.).
class CircularRingAvatar extends StatelessWidget {
  final String imageUrl;
  final double diameter;
  final BoxFit fit;
  final String placeholder;
  /// Optional fill behind the image (e.g. white for brand logos with [BoxFit.contain]).
  final Color? imageBackgroundColor;

  const CircularRingAvatar({
    super.key,
    required this.imageUrl,
    required this.diameter,
    this.fit = BoxFit.cover,
    this.placeholder = Images.placeholder,
    this.imageBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.primaryColor;
    final Widget image = CustomImage(
      image: imageUrl,
      fit: fit,
      width: diameter,
      height: diameter,
      placeholder: placeholder,
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardColor,
        border: Border.all(
          color: primary.withValues(alpha: 0.22),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: imageBackgroundColor != null
              ? ColoredBox(
                  color: imageBackgroundColor!,
                  child: image,
                )
              : image,
        ),
      ),
    );
  }
}
