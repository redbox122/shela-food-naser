import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Success celebration widget with confetti animation
/// Creates a delightful moment of achievement
class SuccessAnimationWidget extends StatefulWidget {
  final Widget child;
  final bool show;

  const SuccessAnimationWidget({
    super.key,
    required this.child,
    this.show = true,
  });

  @override
  State<SuccessAnimationWidget> createState() => _SuccessAnimationWidgetState();
}

class _SuccessAnimationWidgetState extends State<SuccessAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    if (widget.show) {
      _initializeParticles();
      _startAnimation();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(
        ConfettiParticle(
          color: _getRandomColor(random),
          startX: 0.5 + (random.nextDouble() - 0.5) * 0.2,
          startY: 0.5,
          velocityX: (random.nextDouble() - 0.5) * 2,
          velocityY: -random.nextDouble() * 3 - 1,
          rotation: random.nextDouble() * math.pi * 2,
          size: random.nextDouble() * 8 + 4,
        ),
      );
    }
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      const Color(0xFF31A342), // Green
      const Color(0xFFFA9D2B), // Orange
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFA855F7), // Purple
    ];
    return colors[random.nextInt(colors.length)];
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    _rotationController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti particles
        if (widget.show)
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return CustomPaint(
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
        
        // Main content with scale and rotation animation
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _scaleController,
            curve: Curves.elasticOut,
          ),
          child: RotationTransition(
            turns: Tween<double>(begin: -0.1, end: 0.0).animate(
              CurvedAnimation(
                parent: _rotationController,
                curve: Curves.easeOut,
              ),
            ),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// Confetti particle data
class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double size;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.size,
  });
}

/// Custom painter for confetti particles
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = size.width * particle.startX + 
          particle.velocityX * size.width * 0.3 * progress;
      final y = size.height * particle.startY + 
          particle.velocityY * size.height * 0.3 * progress +
          0.5 * 500 * progress * progress; // Gravity effect

      if (y < size.height) {
        final paint = Paint()
          ..color = particle.color.withValues(alpha: (1 - progress).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(particle.rotation + progress * math.pi * 4);
        
        // Draw confetti piece (rectangle)
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 1.5,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

