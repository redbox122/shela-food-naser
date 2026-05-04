import 'package:flutter/material.dart';
import 'package:sixam_mart/features/my_coupon/controllers/my_coupon_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../util/styles.dart';
import '../domain/coupon_list_filters.dart';
import '../domain/models/my_coupon_models.dart';
import 'coupon_widget.dart';

class AvailableCouponWidget extends StatelessWidget {
  final CouponController couponController;

  const AvailableCouponWidget({super.key, required this.couponController});

  @override
  Widget build(BuildContext context) {
    final List<CouponModel> firstTabCoupons = sortCouponsForFirstTab(
      couponsNotExpiredByDate(couponController.couponList ?? <CouponModel>[]),
    );
    return Column(
      children: [
        firstTabCoupons.isEmpty
            ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/image/my_coupon_not_found.png'),
                      Custom_Text(
                        context,
                        text: 'ليس لديك اي قسائم حاليآ',
                        style: font12Grey400W(context),
                      )
                    ],
                  ),
                ),
              )
            : ResponsiveHelper.isWeb()
                ? ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: firstTabCoupons.length,
                    itemBuilder: (BuildContext context, int index) {
                      return BuildCouponList(
                        index: index,
                        list: firstTabCoupons,
                        isAvailable: true,
                      );
                    },
                  )
                : Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: firstTabCoupons.length,
                      itemBuilder: (BuildContext context, int index) {
                        return BuildCouponList(
                          index: index,
                          list: firstTabCoupons,
                          isAvailable: true,
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}
