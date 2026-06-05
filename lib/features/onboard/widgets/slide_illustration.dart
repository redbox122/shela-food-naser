import 'package:flutter/material.dart';
import 'package:sixam_mart/util/images.dart';

/// Page 3 illustration: a static clock with the boxes sliding in from the left.
class SlideIllustration extends StatefulWidget {
  /// Whether the page is currently visible; toggling false→true replays it.
  final bool active;
  const SlideIllustration({super.key, required this.active});

  @override
  State<SlideIllustration> createState() => _SlideIllustrationState();
}

class _SlideIllustrationState extends State<SlideIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _boxesSlide;

  static const double _stageWidth = 300;
  static const double _stageHeight = 320;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Boxes slide in from off-screen left, starting just after the clock shows.
    _boxesSlide = Tween<Offset>(
      begin: const Offset(-1.7, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
    ));
    if (widget.active) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SlideIllustration oldWidget) {
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
          final double clockT = const Interval(0.0, 0.25, curve: Curves.easeOut)
              .transform(_controller.value);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The clock — static, present from the start (quick fade-in).
              Positioned(
                top: 55,
                left: (_stageWidth - 205) / 2,
                child: Opacity(
                  opacity: clockT,
                  child: Transform.scale(
                    scale: 0.96 + 0.04 * clockT,
                    child: Image.asset(Images.oclock, width: 205),
                  ),
                ),
              ),

              // The boxes — slide in from the left and settle overlapping the
              // clock's lower-left.
              Positioned(
                bottom: 72,
                left: 40,
                child: SlideTransition(
                  position: _boxesSlide,
                  child: Image.asset(Images.boxes, width: 155),
                ),
              ),

              // Divider line just beneath the clock + boxes group.
              Positioned(
                left: 0,
                right: 0,
                bottom: 55,
                child: Opacity(
                  opacity: clockT,
                  child: const Divider(thickness: 2, color: Colors.black),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
