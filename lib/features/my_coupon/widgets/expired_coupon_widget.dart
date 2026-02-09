import 'package:flutter/material.dart';

import '../../../common/widgets/custom_text.dart';
import '../../../util/styles.dart';
import '../controllers/my_coupon_controller.dart';
import '../domain/models/my_coupon_models.dart';
import 'coupon_widget.dart';
class ExpiredCouponWidget extends StatelessWidget {
  List<CouponModel> getUnAvailableCoupons(List<CouponModel> coupons) {
    return coupons.where((coupon) => DateTime.tryParse(coupon.expireDate!)!.isBefore(DateTime.now()) ).toList();
  }

  final CouponController couponController;
  const ExpiredCouponWidget({super.key, required this.couponController});

  @override
  Widget build(BuildContext context) {
    final List<CouponModel> unAvailableCoupons = getUnAvailableCoupons(couponController.couponList??[]);
    return Column(
      children: [
        unAvailableCoupons.isEmpty?  Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/image/my_coupon_not_found.png'),
                Custom_Text(context, text: 'ليس لديك اي قسائم حاليآ',style: font12Grey400W(context))
              ],
            ),
          ),
        ):ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: unAvailableCoupons.length,
          itemBuilder: (context, index) {
            return buildCouponList(index: index, list: unAvailableCoupons, isAvailable: false,);
          },
        ),
      ],
    );
  }
}
