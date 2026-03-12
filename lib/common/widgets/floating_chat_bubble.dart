import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class FloatingChatBubbleManager {
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext context,
    required NotificationBodyModel notificationBody,
    required User user,
  }) {
    hide();
    _overlayEntry = OverlayEntry(
      builder: (_) => FloatingChatBubble(
        notificationBody: notificationBody,
        user: user,
        onDismiss: hide,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class FloatingChatBubble extends StatefulWidget {
  final NotificationBodyModel notificationBody;
  final User user;
  final VoidCallback onDismiss;

  const FloatingChatBubble({
    super.key,
    required this.notificationBody,
    required this.user,
    required this.onDismiss,
  });

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble>
    with SingleTickerProviderStateMixin {
  double _x = 20;
  double _y = 300;
  bool _isDragging = false;
  bool _isOverDismiss = false;
  bool _hasMoved = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const double _bubbleSize = 58.0;
  static const double _dismissSize = 60.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _dismissCenterX =>
      (MediaQuery.of(context).size.width / 2) - (_dismissSize / 2);
  double get _dismissCenterY =>
      MediaQuery.of(context).size.height - 130;

  bool get _nearDismiss {
    final dx = (_x - _dismissCenterX).abs();
    final dy = (_y - _dismissCenterY).abs();
    return dx < 65 && dy < 65;
  }

  void _snapToEdge(Size size) {
    setState(() {
      _isDragging = false;
      _isOverDismiss = false;
      _x = _x + _bubbleSize / 2 > size.width / 2
          ? size.width - _bubbleSize - 10
          : 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Dismiss zone (X) ──
        if (_isDragging)
          Positioned(
            left: _dismissCenterX,
            top: _dismissCenterY,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _dismissSize,
              height: _dismissSize,
              decoration: BoxDecoration(
                color: _nearDismiss ? Colors.red : Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: _nearDismiss
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha:0.5),
                          blurRadius: 16,
                          spreadRadius: 4,
                        )
                      ]
                    : [],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),

        // ── Floating bubble ──
        Positioned(
          left: _x.clamp(0.0, size.width - _bubbleSize),
          top: _y.clamp(0.0, size.height - _bubbleSize),
          child: GestureDetector(
            onTap: () async {
              if (!_hasMoved) {
                await Get.toNamed(
                  RouteHelper.getChatRoute(
                    notificationBody: widget.notificationBody,
                    user: widget.user,
                  ),
                );
              }
            },
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
                _hasMoved = false;
              });
              _pulseController.stop();
            },
            onPanUpdate: (d) {
              setState(() {
                _x += d.delta.dx;
                _y += d.delta.dy;
                _hasMoved = true;
                _isOverDismiss = _nearDismiss;
              });
            },
            onPanEnd: (_) {
              if (_nearDismiss) {
                widget.onDismiss();
              } else {
                _snapToEdge(size);
                _pulseController.repeat(reverse: true);
              }
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) {
                final scale = _isDragging ? 1.0 : _pulseAnimation.value;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _isOverDismiss ? 70 : _bubbleSize,
                height: _isOverDismiss ? 70 : _bubbleSize,
                decoration: BoxDecoration(
                  color: _isOverDismiss ? Colors.red : const Color(0xFF31A342),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isOverDismiss ? Colors.red : const Color(0xFF31A342))
                          .withValues(alpha:0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: _isOverDismiss ? 34 : 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
