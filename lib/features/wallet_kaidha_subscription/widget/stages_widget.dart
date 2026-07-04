import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/util/images.dart';

class StagesWidget extends StatelessWidget {
  const StagesWidget({super.key});

  static const Color _green = Color(0xFF31A342);
  static const Color _inactiveBg = Color(0xFFF2F2F4);
  static const Color _inactiveBorder = Color(0xFFE5E5E5);
  static const Color _inactiveIcon = Color(0xFF9AA0A6);
  static const Color _inactiveText = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscriptionController>(
      builder: (controller) {
        final int stage = controller.currentStage;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _step(Images.document_v2, 1, stage, 'المعلومات الشخصية'),
              _connector(stage > 1),
              _step(Images.myWalletIcon, 2, stage, 'الدخل'),
              _connector(stage > 2),
              _step(Images.shield_tick, 3, stage, 'تأكيد ومراجعة العقد'),
            ],
          ),
        );
      },
    );
  }

  Widget _step(String image, int index, int currentStage, String label) {
    // مكتملة = تم تخطّيها (قبل الحالية) → تعرض ✓
    // الحالية = دائرة خضراء بأيقونتها
    // القادمة = دائرة رمادية بأيقونتها
    final bool isCompleted = index < currentStage;
    final bool isCurrent = index == currentStage;
    final bool isGreen = index <= currentStage;
    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGreen ? _green : _inactiveBg,
              border: isGreen
                  ? null
                  : Border.all(color: _inactiveBorder, width: 1.5),
            ),
            child: Image.asset(
              isCompleted ? Images.verify_step : image,
              width: 22,
              height: 22,
              color: isGreen ? Colors.white : _inactiveIcon,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: (isCompleted || isCurrent)
                  ? FontWeight.w700
                  : FontWeight.w500,
              height: 1.3,
              color: isGreen ? _green : _inactiveText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _connector(bool passed) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 23),
        height: 2,
        color: passed ? _green : _inactiveBorder,
      ),
    );
  }
}
