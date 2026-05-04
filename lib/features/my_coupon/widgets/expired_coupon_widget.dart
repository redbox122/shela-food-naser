import 'package:flutter/material.dart';

import '../../../common/widgets/custom_text.dart';
import '../../../util/styles.dart';
import '../controllers/my_coupon_controller.dart';
import '../domain/coupon_list_filters.dart';
import '../domain/models/my_coupon_models.dart';
import 'coupon_widget.dart';

class ExpiredCouponWidget extends StatelessWidget {
  final CouponController couponController;
  const ExpiredCouponWidget({super.key, required this.couponController});

  @override
  Widget build(BuildContext context) {
    final List<CouponModel> expiredByDate = couponsExpiredByDate(
      couponController.couponList ?? <CouponModel>[],
    );
    return Column(
      children: [
        expiredByDate.isEmpty
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
            : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: expiredByDate.length,
                itemBuilder: (BuildContext context, int index) {
                  return BuildCouponList(
                    index: index,
                    list: expiredByDate,
                    isAvailable: false,
                  );
                },
              ),
      ],
    );
  }
}
