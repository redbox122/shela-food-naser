import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Premium gradient button with animations and haptic feedback
/// Creates a delightful button experience with visual and tactile feedback
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color> gradientColors;
  final IconData? icon;
  final double? width;
  final double? height;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradientColors = const [Color(0xFF31A342), Color(0xFF2A8F38)],
    this.icon,
    this.width,
    this.height,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        } : null,
        onTapUp: isEnabled ? (_) {
          setState(() => _isPressed = false);
          HapticFeedback.mediumImpact();
          widget.onPressed?.call();
        } : null,
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: widget.gradientColors[0].withValues(alpha: 
                            0.3 + (_pulseController.value * 0.2),
                          ),
                          blurRadius: 20 + (_pulseController.value * 10),
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isEnabled
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.gradientColors,
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade400,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled ? () {} : null,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                ],
                                Text(
                                  widget.text,
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

