import 'package:flutter/material.dart';
import 'package:sixam_mart/features/my_coupon/controllers/my_coupon_controller.dart';
import '../domain/coupon_list_filters.dart';
import '../domain/models/my_coupon_models.dart';
import 'coupon_empty_state.dart';
import 'coupon_widget.dart';

class AvailableCouponWidget extends StatelessWidget {
  final CouponController couponController;

  const AvailableCouponWidget({super.key, required this.couponController});

  @override
  Widget build(BuildContext context) {
    final List<CouponModel> firstTabCoupons = sortCouponsForFirstTab(
      couponsNotExpiredByDate(couponController.couponList ?? <CouponModel>[]),
    );
    if (firstTabCoupons.isEmpty) {
      return const CouponEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: firstTabCoupons.length,
      itemBuilder: (BuildContext context, int index) {
        return BuildCouponList(
          index: index,
          list: firstTabCoupons,
          isAvailable: true,
        );
      },
    );
  }
}
