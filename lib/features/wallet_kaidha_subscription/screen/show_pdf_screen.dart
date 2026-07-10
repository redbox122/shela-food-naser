
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class ShowPdfScreen extends StatefulWidget {
  const ShowPdfScreen({super.key});

  @override
  State<ShowPdfScreen> createState() => _ShowPdfScreenState();
}

class _ShowPdfScreenState extends State<ShowPdfScreen> {
  // Shella green used across the review design.
  static const Color _green = Color(0xFF30913F);
  static const Color _grey = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscriptionController>(
      builder: (KaidhaSubController) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Hourglass illustration (green frame + sand, clouds, X marks).
                        const _KaidhaHourglassArt(),
                        const SizedBox(height: 20),
                        const Text(
                          'طلبك قيد المراجعة النهائية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF121C19),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'سيتم تحديد الحد الائتماني وتفعيل المحفظة خلال '
                          '24 - 48 ساعة\nسنقوم بإشعارك فور الانتهاء',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Progress steps (RTL: received → reviewing → activated).
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _step(Icons.assignment_turned_in_outlined,
                                'تم استلام الطلب',
                                done: true),
                            _line(true),
                            _step(Icons.access_time, 'قيد المراجعة',
                                active: true),
                            _line(false),
                            _step(Icons.account_balance_wallet_outlined,
                                'تفعيل المحفظة'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Time remaining.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time,
                                color: _grey, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'الوقت المتبقي 24 - 48 ساعة عمل',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: _grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Primary action: review the contract.
                CustomButton(
                  color: _green,
                  radius: 12,
                  buttonText: 'استعراض العقد',
                  onPressed: () async {
                    Get.toNamed(RouteHelper.getContract_ReviewRoute());
                  },
                ),
                const SizedBox(height: 10),
                // Secondary action: contact support (white, bordered).
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6F6F8),
                      side: const BorderSide(color: Color(0xFFE6E8EC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.phone_outlined,
                        color: Color(0xFF121C19), size: 20),
                    label: const Text(
                      'تواصل مع خدمة العملاء',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF121C19),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // One progress step. `done` = completed (filled green + check tint),
  // `active` = current (green ring), otherwise upcoming (grey).
  Widget _step(IconData icon, String label,
      {bool done = false, bool active = false}) {
    final Color color = (done || active) ? _green : _grey;
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? _green : Colors.white,
              border: Border.all(
                color: active ? _green : (done ? _green : const Color(0xFFE0E0E0)),
                width: active ? 2 : 1,
              ),
            ),
            child: Icon(icon,
                size: 20, color: done ? Colors.white : color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: (done || active) ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(bool done) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 22),
        height: 2,
        color: done ? _green : const Color(0xFFE0E0E0),
      ),
    );
  }
}

//

/// Green hourglass illustration (frame + sand) with soft clouds and X marks,
/// drawn to match the pending-review design without needing an image asset.
class _KaidhaHourglassArt extends StatelessWidget {
  const _KaidhaHourglassArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 190,
      child: CustomPaint(painter: _HourglassPainter()),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    const green = Color(0xFF3DAE52);
    const sandLight = Color(0xFFCDEFC6);
    const sandMed = Color(0xFF8FD597);
    const cloud = Color(0xFFEAF7E6);
    const shadow = Color(0xFFD8F0D2);

    final double cx = w / 2;
    const double topY = 42;
    final double botY = h - 26;
    final double cy = (topY + botY) / 2;
    const double halfTop = 42;
    const double neck = 5;

    // Bottom shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h - 14), width: 122, height: 20),
      Paint()..color = shadow,
    );

    // Clouds.
    final cloudPaint = Paint()..color = cloud;
    _cloud(canvas, cloudPaint, Offset(w * 0.34, 26), 1.0);
    _cloud(canvas, cloudPaint, Offset(w * 0.66, 20), 1.15);

    // Scattered X marks.
    final xPaint = Paint()
      ..color = green
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    _x(canvas, xPaint, Offset(w * 0.15, h * 0.32), 6);
    _x(canvas, xPaint, Offset(w * 0.87, h * 0.44), 6);
    _x(canvas, xPaint, Offset(w * 0.20, h * 0.60), 5);

    // Sand — top (light) resting above the neck.
    final topSand = Path()
      ..moveTo(cx - neck, cy - 2)
      ..quadraticBezierTo(cx - halfTop, cy - 28, cx - halfTop * 0.7, topY + 26)
      ..quadraticBezierTo(cx, topY + 18, cx + halfTop * 0.7, topY + 26)
      ..quadraticBezierTo(cx + halfTop, cy - 28, cx + neck, cy - 2)
      ..close();
    canvas.drawPath(topSand, Paint()..color = sandLight);

    // Sand — bottom mound.
    final botSand = Path()
      ..moveTo(cx - neck, cy + 2)
      ..quadraticBezierTo(cx - halfTop * 0.5, botY - 14, cx - halfTop * 0.85, botY - 6)
      ..quadraticBezierTo(cx, botY - 26, cx + halfTop * 0.85, botY - 6)
      ..quadraticBezierTo(cx + halfTop * 0.5, botY - 14, cx + neck, cy + 2)
      ..close();
    canvas.drawPath(botSand, Paint()..color = sandMed);

    // Top & bottom caps.
    final capPaint = Paint()..color = green;
    canvas.drawRRect(
      RRect.fromLTRBR(cx - halfTop - 4, topY - 8, cx + halfTop + 4, topY,
          const Radius.circular(6)),
      capPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(cx - halfTop - 4, botY, cx + halfTop + 4, botY + 8,
          const Radius.circular(6)),
      capPaint,
    );

    // Curved glass outline.
    final frame = Paint()
      ..color = green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final left = Path()
      ..moveTo(cx - halfTop, topY)
      ..quadraticBezierTo(cx - halfTop, cy - 18, cx - neck, cy)
      ..quadraticBezierTo(cx - halfTop, cy + 18, cx - halfTop, botY);
    final right = Path()
      ..moveTo(cx + halfTop, topY)
      ..quadraticBezierTo(cx + halfTop, cy - 18, cx + neck, cy)
      ..quadraticBezierTo(cx + halfTop, cy + 18, cx + halfTop, botY);
    canvas.drawPath(left, frame);
    canvas.drawPath(right, frame);
  }

  void _cloud(Canvas c, Paint p, Offset o, double s) {
    c.drawCircle(o, 12 * s, p);
    c.drawCircle(o + Offset(16 * s, 4 * s), 9 * s, p);
    c.drawCircle(o + Offset(-14 * s, 4 * s), 8 * s, p);
    c.drawRRect(
      RRect.fromLTRBR(o.dx - 16 * s, o.dy + 2 * s, o.dx + 18 * s, o.dy + 12 * s,
          Radius.circular(6 * s)),
      p,
    );
  }

  void _x(Canvas c, Paint p, Offset o, double r) {
    c.drawLine(o + Offset(-r, -r), o + Offset(r, r), p);
    c.drawLine(o + Offset(r, -r), o + Offset(-r, r), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.access_time, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          'طلبك قيد المراجعة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'طلبك قيد المراجعة النهائية. سيتم تحديد الحد الائتماني وتفعيل المحفظة خلال 24 - 48 ساعة. سنقوم بإشعارك فور الانتهاء.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 32),
        // Progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStepCircle(Icons.check, 'تم استلام الطلب', Colors.green),
            _buildStepLine(),
            _buildStepCircle(Icons.hourglass_bottom, 'قيد المراجعة', Colors.green),
            _buildStepLine(),
            _buildStepCircle(null, 'تفعيل المحفظة', Colors.grey),
          ],
        ),
        const SizedBox(height: 32),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, color: Colors.black54),
            SizedBox(width: 8),
            Text(
              'الوقت المتوقع 24-48 ساعة عمل',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
        const Spacer(),
        const Text('هل لديك استفسار؟', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          icon: const Icon(Icons.phone, color: Colors.orange),
          label: const Text(
            'تواصل مع خدمة العملاء',
            style: TextStyle(color: Colors.orange, fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStepCircle(IconData? icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.1),
          child: icon != null
              ? Icon(icon, color: color, size: 18)
              : Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 20,
      height: 1,
      color: Colors.grey[400],
    );
  }
}
