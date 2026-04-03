

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../common/widgets/text_button_w.dart';
import '../../../helper/date_converter.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../../splash/controllers/splash_controller.dart';
import '../domain/models/my_coupon_models.dart';

class BuildCouponList extends StatelessWidget {
  final int index;
  final List<CouponModel> list;
  final bool isAvailable;
  const BuildCouponList({super.key,required this.index, required this.list, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final coupon = list[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.wtColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2), // Shadow color
                  spreadRadius: 2, // Spread radius
                  blurRadius: 2, // Blur radius
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    height: ResponsiveHelper.isDesktop(context)? 200 : 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.gryColor_7
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Custom_Text(
                          context,
                          text: '${coupon.discount}${coupon.discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol} ${'off'}',
                          style: font16SecondaryColor400W(context).copyWith(
                            color: isAvailable == false? AppColors.darkGreyColor:AppColors.secondaryColor
                          )
                        ),
                        const SizedBox(height: 10,),
                        Custom_Text(
                            context,
                            text: coupon.couponType == 'store_wise' ? '${'on'.tr} ${coupon.data}' : 'on_all_store'.tr,
                            style: font12SecondaryColor400W(context).copyWith(
                                color: isAvailable == false? AppColors.darkGreyColor:AppColors.secondaryColor
                            )
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Custom_Text(
                            context,
                            text: '${coupon.title}',
                            maxLines: 1,
                            textOverFlow: TextOverflow.ellipsis,
                            style: font12Black400W(context).copyWith(
                                color: isAvailable == false? AppColors.darkGreyColor:AppColors.bgColor
                            )
                        ),
                        const SizedBox(height: 10,),
                        Text(
                          '${DateConverter.stringToReadableString(coupon.startDate!)} ${'to'.tr} ${DateConverter.stringToReadableString(coupon.expireDate!)}',
                          style: robotoMedium.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10,),
                        Text(
                          '*${'min_purchase'.tr} ',
                          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeExtraSmall),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        isAvailable?
                        ResponsiveHelper.isWeb() ? Align(
                              alignment: AlignmentDirectional.bottomEnd,
                              child: TextButtonWidget(
                                onPressed: (){},
                                verticalPadd: 0,
                                height: 50,
                                width: 155,
                                horizontalPadd: 10,
                                text: 'استخدام',
                                radius: 8,
                                textStyle: font10SecondaryColor600W(context),
                                backgroundColor: AppColors.backgroundColor,
                                borderColor: AppColors.secondaryColor,
                                borderWidth: 2.0,

                              ),
                            ) :
                        Align(
                          alignment: AlignmentDirectional.bottomEnd,
                          child: TextButtonWidget(
                            onPressed: (){},
                            verticalPadd: 0,
                            height: 30,
                            width: 60,
                            horizontalPadd: 10,
                            text: 'use'.tr,
                            radius: 16,
                            textStyle: font10White400W(context),
                            backgroundColor: AppColors.secondaryColor,
                          ),
                        ):Container(),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: -42,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: AppColors.wtColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2), // Shadow color
                    spreadRadius: 2, // Spread radius
                    blurRadius: 2, // Blur radius
                  ),
                ]
              ),
            ),
          )
        ],
      ),
    );
  }
}
