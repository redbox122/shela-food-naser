import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/customAppBar.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../common/widgets/no_data_screen.dart';
import '../../../common/widgets/not_logged_in_screen.dart';
import '../../../helper/auth_helper.dart';
import '../../../util/app_colors.dart';
import '../../../util/styles.dart';
import '../controllers/my_coupon_controller.dart';
import '../widgets/available_coupon_widget.dart';
import '../widgets/expired_coupon_widget.dart';

class MyCouponScreen extends StatefulWidget {
  const MyCouponScreen({super.key});

  @override
  State<MyCouponScreen> createState() => _MyCouponScreenState();
}

class _MyCouponScreenState extends State<MyCouponScreen> {
  int index = 0;

  @override
  void initState() {
    super.initState();

    initCall();
  }

  void initCall() {
    if (AuthHelper.isLoggedIn()) {
      Get.find<CouponController>().getCouponList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: customAppBar(context,
          title: 'قسائمي', img: 'assets/image/coupon1.png'),
      body: isLoggedIn
          ? GetBuilder<CouponController>(builder: (couponController) {
              if (couponController.isLoading &&
                  couponController.couponList == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final couponList = couponController.couponList ?? const [];
              return couponList.isNotEmpty
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await couponController.getCouponList();
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // toggle button between applied and expired coupon
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(
                                          alpha: 0.5), // Shadow color
                                      blurRadius: 5, // Blur radius
                                      offset: const Offset(
                                          0, 3), // Offset from the container
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 25),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          const int i = 0;
                                          setState(() {
                                            index = i;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  bottom: index == 0
                                                      ? const BorderSide(
                                                          color: AppColors
                                                              .greenColor,
                                                          width: 2,
                                                        )
                                                      : BorderSide.none)),
                                          child: Custom_Text(
                                            context,
                                            text: 'المتاحة',
                                            style: font14Black400W(context),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          const int i = 1;
                                          setState(() {
                                            index = i;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  bottom: index == 1
                                                      ? const BorderSide(
                                                          color: AppColors
                                                              .greenColor,
                                                          width: 2,
                                                        )
                                                      : BorderSide.none)),
                                          child: Custom_Text(
                                            context,
                                            text: 'expired'.tr,
                                            style: font14Black400W(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (index == 0)
                                Expanded(
                                    child: AvailableCouponWidget(
                                  couponController: couponController,
                                ))
                              else
                                Expanded(
                                    child: ExpiredCouponWidget(
                                  couponController: couponController,
                                ))
                            ],
                          ),
                        ),
                      ),
                    )
                  : NoDataScreen(text: 'no_coupon_found'.tr, showFooter: true);
            })
          : NotLoggedInScreen(callBack: (bool value) {
              initCall();
              setState(() {});
            }),
    );
  }
}
