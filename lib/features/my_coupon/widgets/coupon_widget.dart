

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import '../../../common/widgets/custom_snackbar.dart';
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

  String _readableDateOrEmpty(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    try {
      return DateConverter.stringToReadableString(raw);
    } catch (_) {
      return '';
    }
  }

  String _buildDateText(CouponModel coupon) {
    final String startText = _readableDateOrEmpty(coupon.startDate);
    final String expiryText = _readableDateOrEmpty(coupon.expireDate);
    final String safeExpiryText = expiryText.isEmpty ? 'بدون تاريخ انتهاء' : expiryText;
    if (kDebugMode) {
      debugPrint('[MyCoupons][RENDER_SAFE_DATE] code=${coupon.code ?? ''} expiryText=$safeExpiryText');
    }
    if (startText.isNotEmpty && expiryText.isNotEmpty) {
      return '$startText ${'to'.tr} $expiryText';
    }
    if (startText.isNotEmpty) {
      return '$startText ${'to'.tr} $safeExpiryText';
    }
    return safeExpiryText;
  }

  String _buildDiscountText(BuildContext context, CouponModel coupon) {
    final String discountValue = coupon.discount?.toString() ?? '0';
    final String discountType = coupon.discountType ?? '';
    final String currencySymbol =
        Get.find<SplashController>().configModel?.currencySymbol ?? '';
    final String suffix = discountType == 'percent' ? '%' : currencySymbol;
    return '$discountValue$suffix ${'off'}';
  }

  Future<void> _copyCouponCode(CouponModel coupon) async {
    if (coupon.isUsed) {
      return;
    }
    final String code = coupon.code?.trim() ?? '';
    if (code.isEmpty) {
      if (kDebugMode) {
        debugPrint('[MyCoupons][COPY_CODE_FAIL_EMPTY]');
      }
      showCustomSnackBar('كود القسيمة غير متاح');
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (kDebugMode) {
      debugPrint('[MyCoupons][COPY_CODE] code=$code');
    }
    showCustomSnackBar('تم نسخ الكود، استخدمه عند إتمام الطلب', isError: false);
  }

  Widget _buildFirstTabAction(BuildContext context, CouponModel coupon) {
    if (coupon.isUsed) {
      if (kDebugMode) {
        debugPrint('[MyCoupons][USED_DISABLED] code=${coupon.code ?? ''}');
      }
      if (ResponsiveHelper.isWeb()) {
        return Align(
          alignment: AlignmentDirectional.bottomEnd,
          child: SizedBox(
            height: 50,
            width: 155,
            child: TextButton(
              onPressed: null,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.backgroundColor,
                side: BorderSide(
                  color: AppColors.secondaryColor.withValues(alpha: 0.35),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'تم الاستخدام',
                style: font10SecondaryColor600W(context).copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ),
          ),
        );
      }
      return Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: SizedBox(
          height: 30,
          width: 90,
          child: TextButton(
            onPressed: null,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.gryColor_7,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'تم الاستخدام',
              style: font10White400W(context).copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
        ),
      );
    }
    if (ResponsiveHelper.isWeb()) {
      return Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: TextButtonWidget(
          onPressed: () => _copyCouponCode(coupon),
          verticalPadd: 0,
          height: 50,
          width: 155,
          horizontalPadd: 10,
          text: 'نسخ الكود',
          radius: 8,
          textStyle: font10SecondaryColor600W(context),
          backgroundColor: AppColors.backgroundColor,
          borderColor: AppColors.secondaryColor,
          borderWidth: 2.0,
        ),
      );
    }
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: TextButtonWidget(
        onPressed: () => _copyCouponCode(coupon),
        verticalPadd: 0,
        height: 30,
        width: 90,
        horizontalPadd: 10,
        text: 'نسخ الكود',
        radius: 16,
        textStyle: font10White400W(context),
        backgroundColor: AppColors.secondaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CouponModel coupon = list[index];
    final bool dimmed = !isAvailable || coupon.isUsed;
    if (kDebugMode) {
      debugPrint(
        '[MyCoupons][RENDER_ITEM] index=$index id=${coupon.id} code=${coupon.code ?? ''} '
        'type=${coupon.couponType ?? ''} start=${coupon.startDate ?? ''} expire=${coupon.expireDate ?? ''} '
        'isUsed=${coupon.isUsed} storeNull=${coupon.store == null}',
      );
    }
    try {
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
                          text: _buildDiscountText(context, coupon),
                          style: font16SecondaryColor400W(context).copyWith(
                            color: dimmed
                                ? AppColors.darkGreyColor
                                : AppColors.secondaryColor,
                          )
                        ),
                        const SizedBox(height: 10,),
                        Custom_Text(
                            context,
                            text: coupon.couponType == 'store_wise'
                                ? '${'on'.tr} ${coupon.data ?? ''}'
                                : 'on_all_store'.tr,
                            style: font12SecondaryColor400W(context).copyWith(
                                color: dimmed
                                    ? AppColors.darkGreyColor
                                    : AppColors.secondaryColor,
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
                            text: coupon.title ?? '',
                            maxLines: 1,
                            textOverFlow: TextOverflow.ellipsis,
                            style: font12Black400W(context).copyWith(
                                color: dimmed
                                    ? AppColors.darkGreyColor
                                    : AppColors.bgColor,
                            )
                        ),
                        if (coupon.isUsed) ...[
                          const SizedBox(height: 6),
                          Text(
                            'مستخدم من قبل',
                            style: robotoMedium.copyWith(
                              color: Theme.of(context).hintColor,
                              fontSize: Dimensions.fontSizeExtraSmall,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10,),
                        Text(
                          _buildDateText(coupon),
                          style: robotoMedium.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10,),
                        Text(
                          'كود القسيمة: ${coupon.code?.trim().isNotEmpty == true ? (coupon.code?.trim() ?? '') : 'كود القسيمة غير متاح'}',
                          style: robotoMedium.copyWith(
                            color: dimmed
                                ? AppColors.darkGreyColor
                                : AppColors.bgColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8,),
                        Text(
                          '*${'min_purchase'.tr} ',
                          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeExtraSmall),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        isAvailable
                            ? _buildFirstTabAction(context, coupon)
                            : const SizedBox.shrink(),
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
    } catch (err, stack) {
      if (kDebugMode) {
        debugPrint('[MyCoupons][RENDER_ERROR] index=$index error=$err stack=$stack');
      }
      return const SizedBox.shrink();
    }
  }
}
