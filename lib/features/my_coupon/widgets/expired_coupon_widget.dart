import 'package:flutter/material.dart';

import '../controllers/my_coupon_controller.dart';
import '../domain/coupon_list_filters.dart';
import '../domain/models/my_coupon_models.dart';
import 'coupon_empty_state.dart';
import 'coupon_widget.dart';

class ExpiredCouponWidget extends StatelessWidget {
  final CouponController couponController;
  const ExpiredCouponWidget({super.key, required this.couponController});

  @override
  Widget build(BuildContext context) {
    final List<CouponModel> expiredByDate = couponsExpiredByDate(
      couponController.couponList ?? <CouponModel>[],
    );
    if (expiredByDate.isEmpty) {
      return const CouponEmptyState(
        message: 'لا يوجد كوبونات منتهية الصلاحية',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: expiredByDate.length,
      itemBuilder: (BuildContext context, int index) {
        return BuildCouponList(
          index: index,
          list: expiredByDate,
          isAvailable: false,
        );
      },
    );
  }
}
