import 'package:flutter/material.dart';

import '../../../util/app_colors.dart';
import '../../../util/images.dart';

/// Empty-state illustration + message shown when a coupons tab has no items.
class CouponEmptyState extends StatelessWidget {
  final String message;

  const CouponEmptyState({
    super.key,
    this.message = 'لا يوجد كوبونات في\n الوقت الحالي',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            Images.couboun,
            width: 248,
            height: 250,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: AppColors.bgColor,
            ),
          ),
        ],
      ),
    );
  }
}
