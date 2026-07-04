import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/wallet_kaidha_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/images.dart';

// ==== خطوط Tajawal الخاصة ببطاقة محفظة قيدها ====
const String _fontTajawal = 'Tajawal';

TextStyle _tajawal(
  double size,
  FontWeight weight, {
  Color color = Colors.white,
  double? height,
}) {
  return TextStyle(
    fontFamily: _fontTajawal,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

class PaymentDetails extends StatelessWidget {
  final Wallet wallet;
  const PaymentDetails({super.key, required this.wallet});

  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _statusLabel() {
    final String status = (wallet.status ?? '').toString().toLowerCase();
    if (status == 'active') return 'متاح';
    if (status == 'pending') return 'قيد المراجعة';
    return 'مغلق';
  }

  @override
  Widget build(BuildContext context) {
    final double availableBalance =
        _parseToDouble(wallet.availableBalance) ?? 0.0;
    final double usedBalance = _parseToDouble(wallet.usedBalance) ?? 0.0;
    final double creditLimit = _parseToDouble(wallet.creditLimit) ??
        _parseToDouble(wallet.purchaseLimit) ??
        0.0;

    // نسبة الاستخدام لشريط التقدّم (0..1)
    double progress = 0;
    final double? usedPct = _parseToDouble(wallet.usedPercentage);
    if (usedPct != null && usedPct > 0) {
      progress = (usedPct / 100).clamp(0.0, 1.0);
    } else if (creditLimit > 0) {
      progress = (usedBalance / creditLimit).clamp(0.0, 1.0);
    }

    // مساحة إضافية بالأسفل ليبرز صندوق "الرصيد المستخدم" خارج البطاقة (ستاك).
    return Padding(
      padding: const EdgeInsets.only(bottom: 48),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // البطاقة الخضراء (ارتفاع أكبر عبر AspectRatio)
          AspectRatio(
            aspectRatio: 1.8,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage(Images.card_quidha),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // أعلى البطاقة: شارة الحالة (يسار) + الرصيد المتاح (يمين)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // يمين (أول عنصر في RTL): الرصيد المتاح + المبلغ
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // إزاحة العنوان قليلاً لليمين ليحاذي بداية الرقم
                            Transform.translate(
                              offset: const Offset(8, 0),
                              child: Text(
                                'الرصيد المتاح',
                                style: _tajawal(14, FontWeight.w500,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _AmountText(
                              amount: availableBalance,
                              fontSize: 35,
                              weight: FontWeight.w800,
                              symbolSize: 20,
                            ),
                          ],
                        ),
                        const Spacer(),
                        // يسار (آخر عنصر في RTL): شارة الحالة (وزر العقد أسفلها إن وُجد)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              child: Center(
                                child: Text(
                                  _statusLabel(),
                                  style: _tajawal(12, FontWeight.w700),
                                ),
                              ),
                            ),
                            if (wallet.signatureStatus == 1 &&
                                wallet.signaturePath != null &&
                                wallet.signaturePath.toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _ContractButton(),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // رقم البطاقة (القيمة يسار والعنوان يمين بسطر واحد)
                    _CardInfoRow(
                      label: 'رقم البطاقة',
                      value: wallet.serialNumber?.toString() ?? '—',
                    ),
                    const SizedBox(height: 10),
                    _CardInfoRow(
                      label: 'تاريخ انتهاء الشهر',
                      value: wallet.lockDay?.toString() ?? '—',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // صندوق "الرصيد المستخدم" بارز أسفل البطاقة (ستاك) مع شريط التقدّم
          Positioned(
            left: 16,
            right: 16,
            bottom: -40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xffE8F5E9),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'الرصيد المستخدم',
                    textAlign: TextAlign.right,
                    style: _tajawal(12, FontWeight.w500,
                        color: const Color(0xFF135017)),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE9EBEE),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3EC856)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'حد البطاقة',
                        style: _tajawal(10, FontWeight.w500,
                            color: const Color(0xFF135017)),
                      ),
                      const Spacer(),
                      _AmountText(
                        amount: usedBalance,
                        fontSize: 14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF135017),
                        symbolSize: 13,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// نص المبلغ مع رمز الريال
class _AmountText extends StatelessWidget {
  final double amount;
  final double fontSize;
  final FontWeight weight;
  final Color color;
  final double symbolSize;
  const _AmountText({
    required this.amount,
    required this.fontSize,
    required this.weight,
    this.color = Colors.white,
    this.symbolSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          amount.toStringAsFixed(2),
          style: _tajawal(fontSize, weight, color: color),
        ),
        const SizedBox(width: 5),
        Image.asset(
          Images.sar,
          width: symbolSize,
          height: symbolSize,
          cacheWidth: (symbolSize * 3).round(),
          cacheHeight: (symbolSize * 3).round(),
          color: color,
        ),
      ],
    );
  }
}

// سطر معلومة على البطاقة (عنوان + قيمة)
class _CardInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _CardInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    // في الاتجاه RTL: العنوان على اليمين والقيمة على اليسار بسطر واحد.
    return Row(
      children: [
        Text(
          label,
          style: _tajawal(14, FontWeight.w500, color: Colors.white),
        ),
        const Spacer(),
        Text(
          value,
          style: _tajawal(16, FontWeight.w500, color: Colors.white),
        ),
      ],
    );
  }
}

// زر عرض العقد
class _ContractButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Get.dialog(
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('جاري تحميل العقد...',
                      style: _tajawal(14, FontWeight.w500,
                          color: const Color(0xFF2D3633))),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );

        try {
          await Get.find<KaidhaSubscriptionController>().get_Pdf();
          Get.back();
          Get.toNamed(RouteHelper.getContract_ReviewRoute());
        } catch (e) {
          Get.back();
          Get.snackbar(
            'خطأ',
            'فشل في تحميل العقد. يرجى المحاولة مرة أخرى.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text('عرض العقد', style: _tajawal(11, FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ========================================================================================================

class PaymentDetailsShimmer extends StatelessWidget {
  const PaymentDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF31A342).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
