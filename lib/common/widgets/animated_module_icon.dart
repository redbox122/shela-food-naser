/// Animated Module Icon Widget
///
/// Smart widget that automatically detects and renders module icons
/// Supports: Lottie JSON, MP4 video, GIF, WebP, and static images (PNG/JPG)
///
/// Features:
/// - Automatic format detection from URL
/// - Proper rendering for each format
/// - Error handling with fallbacks
/// - Caching for performance
/// - Looping for animated formats
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:sixam_mart/common/utils/module_icon_format.dart';
import 'package:sixam_mart/util/images.dart';

class AnimatedModuleIcon extends StatefulWidget {
  /// The URL of the module icon (can be Lottie JSON, MP4, GIF, WebP, or static image)
  final String? url;

  /// Width of the icon
  final double? width;

  /// Height of the icon
  final double? height;

  /// How the icon should be fitted within its bounds
  final BoxFit fit;

  /// Placeholder image to show while loading or on error
  final String placeholder;

  /// Whether the icon should be clipped to a circle
  final bool clipToCircle;

  /// Callback when an error occurs
  final VoidCallback? onError;

  const AnimatedModuleIcon({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder = Images.placeholder,
    this.clipToCircle = false,
    this.onError,
  });

  @override
  State<AnimatedModuleIcon> createState() => _AnimatedModuleIconState();
}

class _AnimatedModuleIconState extends State<AnimatedModuleIcon> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasError = false;
  static const int _maxCacheSize = 1200;

  int? _resolveCacheSize(double? displaySize) {
    if (displaySize == null || displaySize.isNaN || displaySize.isInfinite) {
      return null;
    }
    final int displaySizeInt = displaySize.round();
    final int calculatedSize = (displaySize * 1.5).round();
    final int cappedSize =
        calculatedSize > _maxCacheSize ? _maxCacheSize : calculatedSize;
    return cappedSize < displaySizeInt ? displaySizeInt : cappedSize;
  }

  @override
  void initState() {
    super.initState();
    _initializeVideoIfNeeded();
  }

  @override
  void didUpdateWidget(AnimatedModuleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeVideo();
      _hasError = false;
      _initializeVideoIfNeeded();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _initializeVideoIfNeeded() {
    if (widget.url == null || widget.url!.isEmpty) {
      return;
    }

    final format = detectModuleIconFormat(widget.url);
    if (format == ModuleIconFormat.mp4) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url!),
      );

      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController!.setLooping(true);
          _videoController!.setVolume(0); // Mute
          _videoController!.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
          widget.onError?.call();
        }
      });
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      widget.placeholder,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }

  Widget _buildLottie() {
    return Lottie.network(
      widget.url!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      repeat: true,
      animate: true,
      errorBuilder: (context, error, stackTrace) {
        widget.onError?.call();
        return _buildPlaceholder();
      },
      frameBuilder: (context, child, frame) {
        if (frame == null) {
          return _buildPlaceholder();
        }
        return child;
      },
    );
  }

  Widget _buildVideo() {
    if (!_isVideoInitialized || _videoController == null) {
      return _buildPlaceholder();
    }

    if (_hasError) {
      return _buildPlaceholder();
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final int? cacheWidth = _resolveCacheSize(widget.width);
    final int? cacheHeight = _resolveCacheSize(widget.height);
    return CachedNetworkImage(
      imageUrl: widget.url!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) {
        widget.onError?.call();
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildContent() {
    // Handle null or empty URL
    if (widget.url == null || widget.url!.isEmpty || widget.url == 'null') {
      return _buildPlaceholder();
    }

    // Handle error state
    if (_hasError) {
      return _buildPlaceholder();
    }

    // Detect format and render accordingly
    final format = detectModuleIconFormat(widget.url);

    Widget content;

    switch (format) {
      case ModuleIconFormat.lottie:
        content = _buildLottie();
        break;
      case ModuleIconFormat.mp4:
        content = _buildVideo();
        break;
      case ModuleIconFormat.gif:
      case ModuleIconFormat.webp:
      case ModuleIconFormat.static:
      case ModuleIconFormat.unknown:
        content = _buildImage();
        break;
    }

    // Clip to circle if requested
    if (widget.clipToCircle) {
      return ClipOval(child: content);
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}


