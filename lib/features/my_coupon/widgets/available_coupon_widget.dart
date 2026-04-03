import 'package:flutter/material.dart';
import 'package:sixam_mart/features/my_coupon/controllers/my_coupon_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../common/widgets/dialog/dialog.dart';
import '../../../util/app_colors.dart';
import '../../../util/styles.dart';
import '../domain/models/my_coupon_models.dart';
import 'coupon_widget.dart';

class AvailableCouponWidget extends StatelessWidget {
  List<CouponModel> getAvailableCoupons(List<CouponModel> coupons) {

    return coupons.where((coupon) => DateTime.tryParse(coupon.expireDate!)!.isAfter(DateTime.now()) ).toList();
  }
  List<CouponModel> getUnAvailableCoupons(List<CouponModel> coupons) {
    return coupons.where((coupon) => DateTime.tryParse(coupon.expireDate!)!.isBefore(DateTime.now()) ).toList();
  }

  final CouponController couponController;

  const AvailableCouponWidget({super.key, required this.couponController});

  @override
  Widget build(BuildContext context) {
    final List<CouponModel> availableCoupons = getAvailableCoupons(couponController.couponList??[]);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        getAvailableCoupons(couponController.couponList??[]).isEmpty?  Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/image/my_coupon_not_found.png'),
                Custom_Text(context, text: 'ليس لديك اي قسائم حاليآ',style: font12Grey400W(context))
              ],
            ),
          ),
        ):
            ResponsiveHelper.isWeb()?
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: availableCoupons.length,
          itemBuilder: (context, index) {
            return BuildCouponList(index: index, list: availableCoupons, isAvailable: true,);
          },
        ): Expanded(
          child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: availableCoupons.length,
                itemBuilder: (context, index) {
                  return BuildCouponList(index: index, list: availableCoupons, isAvailable: true,);
                },),
        ),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            color: AppColors.greenColor,
            borderRadius: BorderRadius.circular(8)
          ),
          child: TextButton(
            onPressed: (){
              if(ResponsiveHelper.isWeb()){
                showDialog(
                  context: context,
                  builder: (context) =>const AlertDialog(
                    contentPadding: EdgeInsets.zero,
                    content: CouponInputDialog(),
                  )
                );
              }else {
                showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (BuildContext context){
                  return const CouponInputDialog();
                }
              );
              }
            },
            child: Custom_Text(context, text: 'إضافة قسمية جديدة',style: font14White500W(context)),
          ),
        )
      ],
    );
  }
}

