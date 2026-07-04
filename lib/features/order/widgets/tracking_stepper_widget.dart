import 'package:sixam_mart/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TrackingStepperWidget extends StatelessWidget {
  final String? status;
  final bool takeAway;
  const TrackingStepperWidget(
      {super.key, required this.status, required this.takeAway});

  @override
  Widget build(BuildContext context) {
    final int state = _statusIndex(status, takeAway);
    final bool isArabic = Get.locale?.languageCode == 'ar';
    final String takeAwayDoneLabel =
        isArabic ? 'ord_picked_up'.tr : 'Order received';
    final List<String> steps = [
      'order_placed'.tr,
      'order_confirmed'.tr,
      'preparing_item'.tr,
      takeAway ? 'ready_for_handover'.tr : 'delivery_on_the_way'.tr,
      takeAway ? takeAwayDoneLabel : 'delivered'.tr,
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final bool isLast = index == steps.length - 1;
        final bool isCompleted = state >= 0 && index < state;
        final bool isCurrent = state >= 0 && index == state;

        final Color activeColor = Theme.of(context).primaryColor;
        const Color currentColor = Colors.orange;
        final Color pendingColor = Theme.of(context).disabledColor;
        final Color circleColor = isCompleted
            ? activeColor
            : isCurrent
                ? currentColor
                : pendingColor;
        final Color lineColor = isCompleted ? activeColor : pendingColor;

        return Padding(
          padding:
              EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: circleColor.withValues(
                          alpha: isCompleted || isCurrent ? 1 : 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: circleColor, width: 2),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCompleted || isCurrent
                            ? Colors.white
                            : circleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28,
                      color: lineColor.withValues(alpha: 0.6),
                    ),
                ],
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isCompleted
                            ? activeColor
                            : isCurrent
                                ? currentColor
                                : pendingColor,
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  int _statusIndex(String? status, bool takeAway) {
    if (status == 'pending') {
      return 0;
    } else if (status == 'accepted' || status == 'confirmed') {
      return 1;
    } else if (status == 'processing') {
      return 2;
    } else if (status == 'handover') {
      return takeAway ? 3 : 2;
    } else if (status == 'picked_up') {
      return 3;
    } else if (status == 'delivered') {
      return 4;
    }
    return -1;
  }
}
