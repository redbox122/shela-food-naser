import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// PERFORMANCE POLICY:
/// - Network images must use `CustomImage`, or explicitly set cache sizing.
/// - Avoid decoding full-resolution assets on the UI thread.
/// - Use `cacheWidth/cacheHeight` (or `memCacheWidth/memCacheHeight`) to match
///   the display size and prevent memory spikes, especially in dialogs/profile.
class CustomImage extends StatefulWidget {
  final String image;
  final List<String>? fallbackUrls;
  final String imageStatus;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final bool isNotification;
  final String placeholder;
  final bool isHovered;
  final String? blurHash;
  final int? cacheWidth;
  final int? cacheHeight;
  final int? diskCacheWidth;
  final int? diskCacheHeight;
  final Widget? placeholderWidget;
  final Widget? errorWidget;
  final void Function(String url, Object error)? onImageError;

  const CustomImage(
      {super.key,
      required this.image,
      this.fallbackUrls,
      this.imageStatus = 'ok',
      this.height,
      this.width,
      this.fit = BoxFit.cover,
      this.isNotification = false,
      this.placeholder = '',
      this.isHovered = false,
      this.blurHash,
      this.cacheWidth,
      this.cacheHeight,
      this.diskCacheWidth,
      this.diskCacheHeight,
      this.placeholderWidget,
      this.errorWidget,
      this.onImageError});

  @override
  State<CustomImage> createState() => _CustomImageState();
}

class _CustomImageState extends State<CustomImage> {
  static const String _networkErrorText = 'تعذر تحميل الصورة. تحقق من الاتصال بالإنترنت';
  static const String _imageUnavailableText = 'الصورة غير متوفرة';
  int _imageIndex = 0;
  String? _errorMessage;

  List<String> _buildCandidates() {
    final List<String> candidates = [];
    void addIfValid(String? url) {
      if (url == null || url.isEmpty) return;
      if (!_isValidImageUrl(url)) return;
      if (!candidates.contains(url)) {
        candidates.add(url);
      }
    }

    if (widget.imageStatus == 'ok') {
      addIfValid(widget.image);
    }
    if (widget.fallbackUrls != null && widget.fallbackUrls!.isNotEmpty) {
      for (final url in widget.fallbackUrls!) {
        addIfValid(url);
      }
    }
    return candidates;
  }

  @override
  void didUpdateWidget(CustomImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool urlChanged = oldWidget.image != widget.image;
    final bool fallbackChanged =
        !listEquals(oldWidget.fallbackUrls, widget.fallbackUrls);
    if (urlChanged || fallbackChanged) {
      _imageIndex = 0;
      _errorMessage = null;
    }
  }

  /// ðŸ”§ FIX: CDN (mafrservices) requires User-Agent header to serve images
  /// CDN blocks empty User-Agents and returns HTML instead of images
  /// This ensures proper headers for successful image loading
  static Map<String, String> get _cloudflareHeaders => {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      };

  /// ðŸ”§ FIX: Guard against Infinity/NaN values when converting to int
  /// This prevents crashes when width/height is double.infinity
  /// Also caps to maxCacheSize to prevent decoding huge images
  static const int _maxCacheSize = 1200; // Increased for better quality on high-DPI screens

  /// ðŸŽ¯ FIX: Calculate optimal cache size (1.5x display size for retina quality)
  /// Prevents decoding huge images while maintaining quality
  /// Ensures cache size is NEVER smaller than display size (prevents blur)
  static int? _calculateCacheSize(double? displaySize) {
    if (displaySize == null || displaySize.isInfinite || displaySize.isNaN) {
      return 400; // Default fallback
    }
    // Use 1.5x for retina quality, but cap at maxCacheSize
    // IMPORTANT: Ensure cache size is at least equal to display size (no downscaling)
    final displaySizeInt = displaySize.round();
    final calculatedSize = (displaySize * 1.5).round();
    final finalSize = calculatedSize > _maxCacheSize ? _maxCacheSize : calculatedSize;
    // Never return a size smaller than display size (prevents blur from upscaling)
    return finalSize < displaySizeInt ? displaySizeInt : finalSize;
  }

  static int? _resolveCacheSize(double? displaySize, int? explicitCacheSize) {
    if (explicitCacheSize != null) {
      final int cappedSize = explicitCacheSize > _maxCacheSize ? _maxCacheSize : explicitCacheSize;
      if (displaySize == null || displaySize.isInfinite || displaySize.isNaN) {
        return cappedSize;
      }
      final int displaySizeInt = displaySize.round();
      return cappedSize < displaySizeInt ? displaySizeInt : cappedSize;
    }
    return _calculateCacheSize(displaySize);
  }

  /// âœ… Helper: Check if character is a digit (0-9) without using RegExp
  static bool _isDigit(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57; // '0' to '9'
  }

  /// ðŸŽ¯ FIX: Optimize image URLs intelligently based on container size
  /// Calculates optimal resize value (1.5x container width for retina quality)
  /// Prevents loading huge images while maintaining quality
  String _optimizeImageUrl(String url, double? containerWidth) {
    if (url.isEmpty) return url;
    
    // If no width specified, use default optimization for large images only
    if (containerWidth == null || containerWidth.isInfinite || containerWidth.isNaN) {
      // Only optimize very large images (1700+)
      if (url.contains('Resize=1700')) {
        return url.replaceAll('Resize=1700', 'Resize=800');
      }
      if (url.contains('Resize=2000')) {
        return url.replaceAll('Resize=2000', 'Resize=800');
      }
      return url;
    }
    
    // ðŸ”¥ Calculate optimal size: container width Ã— 1.5 for retina quality
    final targetWidth = (containerWidth * 1.5).round().clamp(200, 1200);
    
    // Replace existing Resize parameter with calculated value
    if (url.contains('Resize=')) {
      // âœ… FIX: Use manual string replacement to avoid deprecated RegExp
      // Find the position of 'Resize=' and replace the number after it
      final resizeIndex = url.indexOf('Resize=');
      if (resizeIndex != -1) {
        final afterResize = url.substring(resizeIndex + 7); // 'Resize=' is 7 chars
        // Find where the number ends (first non-digit character)
        // âœ… FIX: Check if character is digit without using RegExp
        int numberEndIndex = 0;
        while (numberEndIndex < afterResize.length) {
          final char = afterResize[numberEndIndex];
          if (!_isDigit(char)) {
            break; // Found non-digit character
          }
          numberEndIndex++;
        }
        if (numberEndIndex == 0) {
          // No number found, return original
          return url;
        }
        if (numberEndIndex == afterResize.length) {
          // Number extends to end of string
          return url.substring(0, resizeIndex + 7) + targetWidth.toString();
        } else {
          // Replace number in the middle
          return url.substring(0, resizeIndex + 7) + 
                 targetWidth.toString() + 
                 afterResize.substring(numberEndIndex);
        }
      }
    }
    
    // If no Resize parameter exists, add it (if URL supports it)
    // This is optional - only if your CDN supports adding Resize parameter
    return url;
  }

  static int? _toSafeInt(double? value) {
    if (value == null || value.isInfinite || value.isNaN) return null;
    final intValue = value.toInt();
    // ðŸ”§ FIX: Cap cache size to prevent decoding 4000px images for 300px containers
    return intValue > _maxCacheSize ? _maxCacheSize : intValue;
  }

  
  Widget _buildBlurHashPlaceholder() {
    if (widget.blurHash != null && widget.blurHash!.isNotEmpty) {
      // Calculate dimensions for BlurHash image (use reasonable defaults if null)
      final blurHashWidth = _toSafeInt(widget.width) ?? 32;
      final blurHashHeight = _toSafeInt(widget.height) ?? 32;

      return FutureBuilder<Uint8List?>(
        future:
            _decodeBlurHashToBytes(widget.blurHash!, blurHashWidth, blurHashHeight),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return SizedBox(
              height: widget.height,
              width: widget.width,
              child: Image.memory(
                snapshot.data!,
                fit: widget.fit ?? BoxFit.cover,
                height: widget.height,
                width: widget.width,
              ),
            );
          }
          // While loading or on error, show neutral grey shimmer placeholder
          return Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              height: widget.height,
              width: widget.width,
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
            ),
          );
        },
      );
    }
    // TASK 1: Neutral grey-scale shimmer placeholder for technical feel
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
        ),
      ),
    );
  }

  
  /// Decodes BlurHash string to PNG bytes for use with Image.memory
  Future<Uint8List?> _decodeBlurHashToBytes(String hash, int width, int height) async {
    try {
      // Decode BlurHash to img.Image (from image package)
      final decoded = BlurHash.decode(hash);
      final image = decoded.toImage(width, height);
      
      // Encode to PNG bytes
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      // If BlurHash decoding fails, return null to show gradient placeholder
      if (kDebugMode) {
        debugPrint('âš ï¸ BlurHash decode failed: $e');
      }
      return null;
    }
  }

  /// ðŸ›¡ï¸ FIX: Validate image URL before attempting to decode
  /// Prevents Android ImageDecoder crashes from invalid URLs
  /// Blocks SVG and other unsupported formats
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty || url == 'null' || url.trim().isEmpty) {
      return false;
    }
    // Check if URL looks valid (starts with http/https or data:)
    if (!url.startsWith('http://') && 
        !url.startsWith('https://') && 
        !url.startsWith('data:') &&
        !url.startsWith('/')) {
      return false;
    }
    // ðŸ”¥ Block SVG - Android ImageDecoder doesn't support it well
    if (url.toLowerCase().contains('.svg') || url.toLowerCase().contains('svg')) {
      return false;
    }
    return true;
  }

  
  String _resolveErrorMessage(Object error) {
    final String text = error.toString().toLowerCase();

    if (error is TimeoutException ||
        text.contains('timeoutexception') ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable') ||
        text.contains('connection reset by peer')) {
      return _networkErrorText;
    }

    if (text.contains('handshakeexception') ||
        text.contains('certificate') ||
        text.contains('ssl') ||
        text.contains('tls')) {
      return _networkErrorText;
    }

    if (text.contains('404')) {
      return _imageUnavailableText;
    }

    if (widget.imageStatus == 'invalid' || widget.imageStatus == 'placeholder') {
      return _imageUnavailableText;
    }

    return _networkErrorText;
  }
  void _advanceToNextUrl(List<String> candidates) {
    if (_imageIndex >= candidates.length - 1) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _imageIndex += 1;
        _errorMessage = null;
      });
    });
  }

  Widget _buildErrorMessageUI(String message) {
    return Container(
      height: widget.height,
      width: widget.width,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (widget.imageStatus == 'placeholder') {
      return _buildBlurHashPlaceholder();
    }

    final candidates = _buildCandidates();
    if (candidates.isEmpty) {
      if (widget.errorWidget != null) {
        return widget.errorWidget!;
      }
      if (widget.imageStatus == 'invalid') {
        return _buildErrorMessageUI(_imageUnavailableText);
      }
      if (widget.imageStatus == 'missing') {
        return _buildErrorMessageUI(_networkErrorText);
      }
      return _buildErrorMessageUI(_networkErrorText);
    }

    final imageUrl = candidates[_imageIndex];
    // FIX: Validate image URL before attempting to decode
    // Prevents Android ImageDecoder crashes from invalid URLs
    if (!_isValidImageUrl(imageUrl)) {
      return _buildErrorMessageUI(_imageUnavailableText);
    }

    // FIX: Optimize image URL based on container size
    // Calculate optimal resize value (1.5x width for retina quality)
    final optimizedImageUrl = _optimizeImageUrl(imageUrl, widget.width);
    final int? resolvedCacheWidth = _resolveCacheSize(widget.width, widget.cacheWidth);
    final int? resolvedCacheHeight = _resolveCacheSize(widget.height, widget.cacheHeight);
    final int? resolvedDiskCacheWidth =
        _resolveCacheSize(widget.width, widget.diskCacheWidth ?? widget.cacheWidth);
    final int? resolvedDiskCacheHeight =
        _resolveCacheSize(widget.height, widget.diskCacheHeight ?? widget.cacheHeight);

    return AnimatedScale(
      scale: widget.isHovered ? 1.1 : 1.0, // Scale animation
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: kIsWeb
          ? RepaintBoundary(
              // TASK 1: ISOLATE pixel layer - if native decoder crashes, only this layer dies
              // PERFORMANCE: Use CachedNetworkImage for web too (with memCacheWidth/Height)
              child: CachedNetworkImage(
                imageUrl: optimizedImageUrl,
                height: widget.height,
                width: widget.width,
                fit: widget.fit,
                httpHeaders: _cloudflareHeaders, // FIX: Add User-Agent for Cloudflare CDN
                memCacheWidth: resolvedCacheWidth, // PERFORMANCE: Limit memory cache width
                memCacheHeight: resolvedCacheHeight, // PERFORMANCE: Limit memory cache height
                maxWidthDiskCache: resolvedDiskCacheWidth,
                maxHeightDiskCache: resolvedDiskCacheHeight,
                imageBuilder: (context, imageProvider) {
                  final ImageProvider resizedProvider =
                      (resolvedCacheWidth != null || resolvedCacheHeight != null)
                          ? ResizeImage(
                              imageProvider,
                              width: resolvedCacheWidth,
                              height: resolvedCacheHeight,
                            )
                          : imageProvider;
                  return Image(
                    image: resizedProvider,
                    height: widget.height,
                    width: widget.width,
                    fit: widget.fit ?? BoxFit.cover,
                  );
                },
                placeholder: (context, url) =>
                    widget.placeholderWidget ??
                    Image.asset(Images.placeholder, fit: widget.fit ?? BoxFit.cover),
                errorWidget: (context, url, error) {
                  widget.onImageError?.call(url, error);
                  final message = _resolveErrorMessage(error);
                  if (kDebugMode) {
                    debugPrint(
                        '[IMG_ERR] type=${error.runtimeType} url=$url index=$_imageIndex/${candidates.length - 1} error=$error');
                  }
                  _errorMessage = message;
                  _advanceToNextUrl(candidates);
                  if (_imageIndex < candidates.length - 1) {
                    return widget.placeholderWidget ?? _buildBlurHashPlaceholder();
                  }
                  return widget.errorWidget ??
                      _buildErrorMessageUI(_errorMessage ?? message);
                },
              ),
            )
          : RepaintBoundary(
              // PERFORMANCE: Use CachedNetworkImage with memCacheWidth/Height for banner images
              // This reduces memory usage by decoding images at display size instead of full resolution
              child: CachedNetworkImage(
                imageUrl: optimizedImageUrl,
                height: widget.height,
                width: widget.width,
                fit: widget.fit ?? BoxFit.cover,
                httpHeaders: _cloudflareHeaders, // FIX: Add User-Agent for CDN
                memCacheWidth: resolvedCacheWidth, // PERFORMANCE: Limit memory cache width (e.g., 1080px for banners)
                memCacheHeight: resolvedCacheHeight, // PERFORMANCE: Limit memory cache height (e.g., 480px for banners)
                maxWidthDiskCache: resolvedDiskCacheWidth,
                maxHeightDiskCache: resolvedDiskCacheHeight,
                imageBuilder: (context, imageProvider) {
                  final ImageProvider resizedProvider =
                      (resolvedCacheWidth != null || resolvedCacheHeight != null)
                          ? ResizeImage(
                              imageProvider,
                              width: resolvedCacheWidth,
                              height: resolvedCacheHeight,
                            )
                          : imageProvider;
                  return Image(
                    image: resizedProvider,
                    height: widget.height,
                    width: widget.width,
                    fit: widget.fit ?? BoxFit.cover,
                  );
                },
                placeholder: (context, url) =>
                    widget.placeholderWidget ?? _buildBlurHashPlaceholder(),
                errorWidget: (context, url, error) {
                  widget.onImageError?.call(url, error);
                  final message = _resolveErrorMessage(error);
                  if (kDebugMode) {
                    debugPrint(
                        '[IMG_ERR] type=${error.runtimeType} url=$url index=$_imageIndex/${candidates.length - 1} error=$error');
                  }
                  _errorMessage = message;
                  _advanceToNextUrl(candidates);
                  if (_imageIndex < candidates.length - 1) {
                    return widget.placeholderWidget ?? _buildBlurHashPlaceholder();
                  }
                  return widget.errorWidget ??
                      _buildErrorMessageUI(_errorMessage ?? message);
                },
              ),
            ),
    );
  }
}

