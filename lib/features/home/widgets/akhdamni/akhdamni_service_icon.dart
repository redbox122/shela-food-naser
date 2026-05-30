import 'package:flutter/material.dart';

/// Renders an Akhdamni service icon from [assets/image/akhdamni/] when available,
/// otherwise falls back to the provided [icon] without throwing.
class AkhdamniServiceIcon extends StatelessWidget {
  const AkhdamniServiceIcon({
    super.key,
    required this.icon,
    this.assetFileName,
    this.size = 28,
    this.color,
  });

  static const String assetsFolder = 'assets/image/akhdamni/';

  final IconData icon;
  final String? assetFileName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final String? fileName = assetFileName?.trim();
    if (fileName != null && fileName.isNotEmpty) {
      return Image.asset(
        '$assetsFolder$fileName',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
