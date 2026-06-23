import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/dashboard/widgets/home_bottom_nav_bar.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: the app bottom navigation bar, reused on pushed market screens
/// (storefront / single store). Tapping a tab jumps to the matching dashboard
/// page, replacing the current navigation stack.
class StoreBottomNavBar extends StatelessWidget {
  /// Which tab to render as selected (0:home, 1:cart, 2:discounts, 3:orders,
  /// 4:profile). Defaults to home for the market storefront screens.
  final int currentIndex;

  const StoreBottomNavBar({super.key, this.currentIndex = 0});

  static const List<String> _pages = [
    'home',
    'cart',
    'discounts',
    'order',
    'profile',
  ];

  @override
  Widget build(BuildContext context) {
    final items = <HomeNavBarItem>[
      HomeNavBarItem(
          icon: Images.home_v2,
          activeIcon: Images.home_v2_active,
          label: 'nav_home'.tr),
      HomeNavBarItem(
          icon: Images.bag_v2,
          activeIcon: Images.bag_v2_active,
          label: 'nav_cart'.tr,
          isCart: true),
      HomeNavBarItem(
          icon: Images.discount_shape_v2,
          activeIcon: Images.discount_shape_v2_active,
          label: 'nav_discounts'.tr),
      HomeNavBarItem(
          icon: Images.receipt_ext_v2,
          activeIcon: Images.receipt_ext_v2_active,
          label: 'nav_orders'.tr),
      HomeNavBarItem(
          icon: Images.profile_v2,
          activeIcon: Images.profile_v2_active,
          label: 'nav_profile'.tr),
    ];
    return HomeBottomNavBar(
      items: items,
      currentIndex: currentIndex,
      onTap: (i) => Get.offAllNamed(RouteHelper.getMainRoute(_pages[i])),
    );
  }
}
