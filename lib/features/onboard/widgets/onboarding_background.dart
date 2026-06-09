import 'package:flutter/material.dart';
import 'package:sixam_mart/util/images.dart';

/// Background gradient variants that cross-fade to animate the onboarding
/// backdrop. Add the design's alternate-color versions here and they will be
/// blended in automatically.
const List<String> onboardingBackgroundImages = [
  Images.Blured_effect_1,
  Images.Blured_effect_2,
  Images.Blured_effect_3,
  Images.Blured_effect_4,
];

/// Continuously and smoothly cross-fades between full-bleed background images —
/// always in gentle motion, never holding still.
///
/// Performance: the bottom image stays fully opaque while the next fades in on
/// top via [Image.opacity] (which blends in the image's own paint, with no
/// `Opacity` save-layer), wrapped in a [RepaintBoundary]. As soon as one fade
/// finishes the next begins, so the motion is continuous yet jank-free.
class OnboardingBackground extends StatefulWidget {
  final List<String> images;
  const OnboardingBackground({
    super.key,
    this.images = onboardingBackgroundImages,
  });

  @override
  State<OnboardingBackground> createState() => _OnboardingBackgroundState();
}

class _OnboardingBackgroundState extends State<OnboardingBackground>
    with SingleTickerProviderStateMixin {
  // Duration of one continuous fade from one image to the next.
  static const Duration _fade = Duration(seconds: 5);

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  int _current = 0;
  int _next = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _fade);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // The next image is fully shown; promote it and immediately begin
        // fading in the following one — so the motion never stops.
        setState(() {
          _current = _next;
          _next = (_next + 1) % widget.images.length;
        });
        _controller.forward(from: 0);
      }
    });

    if (widget.images.length > 1) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _image(String asset, {Animation<double>? opacity}) => Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
        opacity: opacity,
      );

  @override
  Widget build(BuildContext context) {
    if (widget.images.length <= 1) {
      return _image(widget.images.first);
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _image(widget.images[_current]),
          _image(widget.images[_next], opacity: _opacity),
        ],
      ),
    );
  }
}
