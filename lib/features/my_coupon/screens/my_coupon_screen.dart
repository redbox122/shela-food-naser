import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/error_state_view.dart';
import '../../../common/widgets/not_logged_in_screen.dart';
import '../../../helper/auth_helper.dart';
import '../../../util/app_colors.dart';
import '../controllers/my_coupon_controller.dart';
import '../widgets/available_coupon_widget.dart';
import '../widgets/expired_coupon_widget.dart';

class MyCouponScreen extends StatefulWidget {
  const MyCouponScreen({super.key});

  @override
  State<MyCouponScreen> createState() => _MyCouponScreenState();
}

class _MyCouponScreenState extends State<MyCouponScreen> {
  static const Color _pageColor = Colors.white;
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
      backgroundColor: _pageColor,
      appBar: AppBar(
        backgroundColor: AppColors.wtColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'الكوبونات',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.bgColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.bgColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: isLoggedIn
            ? GetBuilder<CouponController>(builder: (couponController) {
                if (couponController.isLoading &&
                    couponController.couponList == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (couponController.hasError &&
                    !couponController.isLoading &&
                    (couponController.couponList == null ||
                        couponController.couponList!.isEmpty)) {
                  return ErrorStateView(
                    onRetry: couponController.getCouponList,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await couponController.getCouponList();
                  },
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _CouponTabs(
                          selectedIndex: index,
                          onChanged: (int value) {
                            setState(() {
                              index = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: index == 0
                            ? AvailableCouponWidget(
                                couponController: couponController)
                            : ExpiredCouponWidget(
                                couponController: couponController),
                      ),
                    ],
                  ),
                );
              })
            : NotLoggedInScreen(callBack: (bool value) {
                initCall();
                setState(() {});
              }),
      ),
    );
  }
}

/// The two-segment pill selector: "المتاحة" / "منتهية الصلاحية".
class _CouponTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _CouponTabs({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          _segment(text: 'المتاحة', value: 0),
          _segment(text: 'منتهية الصلاحية', value: 1),
        ],
      ),
    );
  }

  Widget _segment({required String text, required int value}) {
    final bool selected = selectedIndex == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.wtColor : AppColors.bgColor,
            ),
          ),
        ),
      ),
    );
  }
}
