/// Module Icon Format Detection Utility
///
/// Detects the format of module icons from URL extensions
/// Supports: Lottie JSON, MP4, GIF, WebP, and static images (PNG/JPG)
library;

enum ModuleIconFormat {
  /// Lottie JSON animation (.json)
  lottie,

  /// MP4 video (.mp4)
  mp4,

  /// GIF animation (.gif)
  gif,

  /// WebP image (static or animated) (.webp)
  webp,

  /// Static images (PNG, JPG, JPEG)
  static,

  /// Unknown or unsupported format
  unknown,
}

/// Detects the format of a module icon from its URL
///
/// [url] The full URL or filename of the icon
/// Returns [ModuleIconFormat] based on file extension
ModuleIconFormat detectModuleIconFormat(String? url) {
  if (url == null || url.isEmpty) {
    return ModuleIconFormat.unknown;
  }

  // Extract extension from URL (handle query parameters)
  final uri = Uri.tryParse(url);
  final path = uri?.path ?? url;
  final extension = path.split('.').last.toLowerCase().split('?').first;

  switch (extension) {
    case 'json':
      return ModuleIconFormat.lottie;
    case 'mp4':
      return ModuleIconFormat.mp4;
    case 'gif':
      return ModuleIconFormat.gif;
    case 'webp':
      return ModuleIconFormat.webp;
    case 'png':
    case 'jpg':
    case 'jpeg':
      return ModuleIconFormat.static;
    default:
      return ModuleIconFormat.unknown;
  }
}

/// Checks if the format is animated
///
/// [format] The detected format
/// Returns true if format supports animation
bool isAnimatedFormat(ModuleIconFormat format) {
  return format == ModuleIconFormat.lottie ||
      format == ModuleIconFormat.mp4 ||
      format == ModuleIconFormat.gif ||
      format == ModuleIconFormat.webp;
}

/// Gets a human-readable format name
///
/// [format] The detected format
/// Returns a string representation of the format
String getFormatName(ModuleIconFormat format) {
  switch (format) {
    case ModuleIconFormat.lottie:
      return 'Lottie';
    case ModuleIconFormat.mp4:
      return 'MP4';
    case ModuleIconFormat.gif:
      return 'GIF';
    case ModuleIconFormat.webp:
      return 'WebP';
    case ModuleIconFormat.static:
      return 'Static';
    case ModuleIconFormat.unknown:
      return 'Unknown';
  }
}


