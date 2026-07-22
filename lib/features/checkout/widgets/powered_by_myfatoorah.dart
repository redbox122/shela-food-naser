import 'package:flutter/material.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// "Powered by myfatoorah" badge shown under the digital-payment methods.
///
/// Prefers the official logo asset ([Images.poweredByMyfatoorah]); if that
/// asset is missing it falls back to a clean text wordmark so the badge always
/// renders. Drop the official PNG at assets/image/powered_by_myfatoorah.png to
/// use the exact brand logo.
class PoweredByMyfatoorah extends StatelessWidget {
  const PoweredByMyfatoorah({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        Images.poweredByMyfatoorah,
        height: 22,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _TextWordmark(),
      ),
    );
  }
}

/// Fallback rendering of the "Powered by myfatoorah" wordmark using text only.
class _TextWordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedColor = isDark ? Colors.white54 : const Color(0xFF9A9A9A);
    // MyFatoorah brand wordmark: light-blue "my" + dark-blue "fatoorah".
    const Color myColor = Color(0xFF00AEEF);
    final Color fatoorahColor =
        isDark ? Colors.white : const Color(0xFF2E3192);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Powered by',
          style: robotoRegular.copyWith(fontSize: 11, color: mutedColor),
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'my',
                style: robotoBold.copyWith(
                    fontSize: 15, color: myColor, letterSpacing: 0),
              ),
              TextSpan(
                text: 'fatoorah',
                style: robotoBold.copyWith(
                    fontSize: 15, color: fatoorahColor, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
