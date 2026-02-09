import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

class SmartImage extends StatelessWidget {
  final String url;
  final String imageStatus;
  final List<String>? fallbackUrls;
  final int cacheWidth;
  final int? cacheHeight;
  final int? diskCacheWidth;
  final int? diskCacheHeight;
  final double? height;
  final double? width;
  final BoxFit fit;
  final String? blurHash;
  final bool isNotification;
  final String placeholder;
  final bool isHovered;
  final Widget? placeholderWidget;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.url,
    this.imageStatus = 'ok',
    this.fallbackUrls,
    this.cacheWidth = 600,
    this.cacheHeight,
    this.diskCacheWidth,
    this.diskCacheHeight,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.blurHash,
    this.isNotification = false,
    this.placeholder = '',
    this.isHovered = false,
    this.placeholderWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CustomImage(
      image: url,
      imageStatus: imageStatus,
      fallbackUrls: fallbackUrls,
      height: height,
      width: width,
      fit: fit,
      isNotification: isNotification,
      placeholder: placeholder,
      isHovered: isHovered,
      blurHash: blurHash,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      diskCacheWidth: diskCacheWidth,
      diskCacheHeight: diskCacheHeight,
      placeholderWidget: placeholderWidget,
      errorWidget: errorWidget,
    );
  }
}
