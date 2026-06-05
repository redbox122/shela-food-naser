import 'package:flutter/material.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/features/onboard/widgets/pop_icon.dart';

// Each icon starts deep inside the bag (hidden behind its body, near the
// bottom) and rises up out of the opening to its final spot.
const List<PopIcon> firstPageIcons = [
  PopIcon(
    asset: Images.ob_ic_pharmacy,
    start: Offset(124, 210),
    end: Offset(118, -2),
    size: 71,
    interval: Interval(0.06, 0.66),
  ),
  PopIcon(
    asset: Images.ob_ic_food,
    start: Offset(130, 215),
    end: Offset(6, 92),
    size: 55,
    interval: Interval(0.16, 0.76),
  ),
  PopIcon(
    asset: Images.ob_ic_grocery,
    start: Offset(128, 212),
    end: Offset(222, 50),
    size: 61,
    interval: Interval(0.24, 0.84),
  ),
];

const List<PopIcon> secondPageIcons = [
  PopIcon(
    asset: Images.discount_50,
    start: Offset(109, 120),
    end: Offset(108, -5),
    size: 83,
    interval: Interval(0.10, 0.58),
  ),
  PopIcon(
    asset: Images.discount_20,
    start: Offset(123, 125),
    end: Offset(35, 48),
    size: 55,
    interval: Interval(0.20, 0.70),
  ),
  PopIcon(
    asset: Images.discount_30,
    start: Offset(127, 122),
    end: Offset(205, 72),
    size: 47,
    interval: Interval(0.26, 0.78),
  ),
];

class PopIllustration extends StatefulWidget {
  final bool active;
  final String centerAsset;
  final double centerWidth;
  final double centerLeft;
  final double centerBottom;
  final List<PopIcon> icons;

  /// Total length of the pop animation (icon intervals are fractions of this).
  final Duration duration;

  const PopIllustration({
    super.key,
    required this.active,
    required this.centerAsset,
    required this.centerWidth,
    required this.centerLeft,
    required this.centerBottom,
    required this.icons,
    this.duration = const Duration(milliseconds: 750),
  });

  @override
  State<PopIllustration> createState() => _PopIllustrationState();
}

class _PopIllustrationState extends State<PopIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _stageWidth = 300;
  static const double _stageHeight = 320;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.active) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(PopIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _stageWidth,
      height: _stageHeight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double centerT =
              const Interval(0.0, 0.18, curve: Curves.easeOut)
                  .transform(_controller.value);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final icon in widget.icons) _buildIcon(icon),
              Positioned(
                bottom: widget.centerBottom,
                left: widget.centerLeft,
                child: Opacity(
                  opacity: centerT,
                  child: Transform.scale(
                    scale: 0.96 + 0.04 * centerT,
                    child: Image.asset(widget.centerAsset,
                        width: widget.centerWidth),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 2,
                child: Opacity(
                  opacity: centerT,
                  child: const Divider(thickness: 2, color: Colors.black),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIcon(PopIcon icon) {
    final double t = icon.interval.transform(_controller.value).clamp(0.0, 1.0);
    final double pop = Curves.easeOutBack.transform(t);
    final Offset pos = Offset.lerp(icon.start, icon.end, pop)!;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Opacity(
        // Become solid quickly so the icon reads as a real object rising out
        // of the bag (rather than fading in).
        opacity: (t * 3.5).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.7 + 0.3 * pop,
          child: Image.asset(icon.asset, width: icon.size),
        ),
      ),
    );
  }
}
