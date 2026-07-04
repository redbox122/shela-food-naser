import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../common/widgets/custom_snackbar.dart';
import '../../../helper/date_converter.dart';
import '../../../util/app_colors.dart';
import '../../../util/images.dart';
import '../../splash/controllers/splash_controller.dart';
import '../domain/models/my_coupon_models.dart';

/// A single coupon "ticket" card (v2 design):
/// - A vertical, colored discount strip on the leading (RTL start) side.
/// - A dashed perforation with two notches separating the strip from the body.
/// - A status label, title, description and validity date in the body.
///
/// Expired coupons (isAvailable == false) and used coupons are rendered with a
/// muted grey palette. Tapping an active coupon copies its code.
class BuildCouponList extends StatelessWidget {
  final int index;
  final List<CouponModel> list;
  final bool isAvailable;

  const BuildCouponList({
    super.key,
    required this.index,
    required this.list,
    required this.isAvailable,
  });

  // Rotating palettes for active coupons (strip background + accent color).
  static const List<_CouponPalette> _palettes = <_CouponPalette>[
    _CouponPalette(strip: Color(0xFFEAF7EC), accent: Color(0xFF31A342)),
    _CouponPalette(strip: Color(0xFFF1EBF9), accent: Color(0xFF8E4EC6)),
    _CouponPalette(strip: Color(0xFFFCE9EC), accent: Color(0xFFE23744)),
    _CouponPalette(strip: Color(0xFFEAF3FB), accent: Color(0xFF2F80ED)),
  ];

  // Muted palette for expired / used coupons (grey image, per design).
  static const _CouponPalette _mutedPalette =
      _CouponPalette(strip: Color(0xFFF0F0F0), accent: Color(0xFF9E9E9E));

  static const double _stripWidth = 70;

  bool _isMuted(CouponModel coupon) => !isAvailable || coupon.isUsed;

  _CouponPalette _paletteFor(CouponModel coupon) {
    if (_isMuted(coupon)) {
      return _mutedPalette;
    }
    final int key = coupon.id ?? index;
    return _palettes[key.abs() % _palettes.length];
  }

  /// Days until [expireDate]. Null when there is no (parseable) expiry.
  int? _daysToExpiry(CouponModel coupon) {
    final String? raw = coupon.expireDate;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final DateTime? expires = DateTime.tryParse(raw);
    if (expires == null) {
      return null;
    }
    final DateTime now = DateTime.now();
    return DateTime(expires.year, expires.month, expires.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  String _discountValue(CouponModel coupon) {
    final double value = coupon.discount ?? 0;
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String _discountSuffix(CouponModel coupon) {
    if (coupon.discountType == 'percent') {
      return '%';
    }
    return Get.find<SplashController>().configModel?.currencySymbol ?? '';
  }

  String _readableDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    try {
      return DateConverter.stringToReadableString(raw);
    } catch (_) {
      return '';
    }
  }

  String _dateText(CouponModel coupon) {
    final String expiry = _readableDate(coupon.expireDate);
    if (!isAvailable) {
      return expiry.isEmpty ? 'انتهت الصلاحية' : 'انتهت الصلاحية في $expiry';
    }
    return expiry.isEmpty ? 'بدون تاريخ انتهاء' : 'صالح حتى $expiry';
  }

  String _descriptionText(CouponModel coupon) {
    if (coupon.couponType == 'store_wise' &&
        (coupon.data ?? '').trim().isNotEmpty) {
      return 'استخدم هذا الكوبون في ${coupon.data} عند الدفع.';
    }
    return 'استخدم هذا الكوبون عند الدفع للحصول على الخصم تلقائياً.';
  }

  Future<void> _copyCode(CouponModel coupon) async {
    if (!isAvailable || coupon.isUsed) {
      return;
    }
    final String code = coupon.code?.trim() ?? '';
    if (code.isEmpty) {
      showCustomSnackBar('كود القسيمة غير متاح');
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    showCustomSnackBar('تم نسخ الكود، استخدمه عند إتمام الطلب', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    final CouponModel coupon = list[index];
    final _CouponPalette palette = _paletteFor(coupon);
    final bool muted = _isMuted(coupon);
    final int? daysLeft = _daysToExpiry(coupon);
    final bool nearExpiry = isAvailable &&
        !coupon.isUsed &&
        daysLeft != null &&
        daysLeft >= 0 &&
        daysLeft <= 3;

    late final String statusText;
    late final Color statusColor;
    if (coupon.isUsed) {
      statusText = 'تم الاستخدام';
      statusColor = AppColors.darkGreyColor;
    } else if (!isAvailable) {
      statusText = 'منتهي الصلاحية';
      statusColor = AppColors.darkGreyColor;
    } else if (nearExpiry) {
      statusText = 'قرب على الانتهاء';
      statusColor = AppColors.secondaryColor;
    } else {
      statusText = 'تفعيل';
      statusColor = AppColors.primaryColor;
    }

    if (kDebugMode) {
      debugPrint(
        '[MyCoupons][RENDER_ITEM] index=$index id=${coupon.id} '
        'code=${coupon.code ?? ''} available=$isAvailable used=${coupon.isUsed} '
        'daysLeft=$daysLeft',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _copyCode(coupon),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: AppColors.wtColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F0F0)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: <Widget>[
                    // Body — defines the card height; padded to clear the strip.
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 16,
                        end: _stripWidth + 16,
                        top: 18,
                        bottom: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Top row: status label + coupon code chip.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                              const Spacer(),
                              _codeChip(coupon, muted),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Horizontal dashed separator.
                          _HDashedLine(
                            color: muted
                                ? AppColors.gryColor_4
                                : palette.accent.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            coupon.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: muted
                                  ? AppColors.darkGreyColor
                                  : AppColors.bgColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _descriptionText(coupon),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.wGreyColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              _dateText(coupon),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: muted
                                    ? AppColors.gryColor_5
                                    : AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Vertical discount strip (fills the card height).
                    PositionedDirectional(
                      end: 0,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: _stripWidth,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            // Ticket-shaped strip image, tinted per coupon color.
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                palette.strip,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                Images.coupoun_img,
                                fit: BoxFit.fill,
                                // If the asset isn't bundled yet, fall back to a
                                // plain fill (tinted by the ColorFiltered above).
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Colors.white),
                              ),
                            ),
                            Center(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontFamily: 'Tajawal'),
                                  children: <InlineSpan>[
                                    TextSpan(
                                      text: 'خصم ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: palette.accent,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '${_discountValue(coupon)}${_discountSuffix(coupon)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: palette.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The coupon code shown as a light chip with a copy icon (LTR, since the
  /// code is Latin). Tapping the card copies the code.
  Widget _codeChip(CouponModel coupon, bool muted) {
    final String code = coupon.code?.trim() ?? '';
    if (code.isEmpty) {
      return const SizedBox.shrink();
    }
    final Color fg = muted ? AppColors.darkGreyColor : AppColors.bgColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.copy_rounded, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              code,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponPalette {
  final Color strip;
  final Color accent;

  const _CouponPalette({required this.strip, required this.accent});
}

/// A thin horizontal dashed line spanning the full available width.
class _HDashedLine extends StatelessWidget {
  final Color color;

  const _HDashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.2,
      width: double.infinity,
      child: CustomPaint(painter: _HDashedLinePainter(AppColors.gryColor_4)),
    );
  }
}

class _HDashedLinePainter extends CustomPainter {
  final Color color;

  _HDashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const double dash = 4;
    const double gap = 4;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final double y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      final double end = (x + dash) > size.width ? size.width : (x + dash);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _HDashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
