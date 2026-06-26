import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/widgets/address_selection_sheet.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: Top notice pill shown under the home greeting.
///
/// It surfaces a single, context-aware row:
///  1. Location not set on the map   → "ضع عنوانك لتكتشف خدماتنا بسهولة"
///  2. Guest user (location is set)   → "انضم إلينا واستمتع بخدمات شله"
///  3. Logged-in user with a location → shows the saved address (📍 pin)
///
/// This is a presentation-only widget; it reads existing controllers/helpers
/// and never triggers data loading.
class HomeTopNoticeStrip extends StatelessWidget {
  const HomeTopNoticeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild when the location changes (after the user picks an address)
    // or when the module/login state changes.
    return GetBuilder<SplashController>(
      builder: (_) => GetBuilder<LocationController>(
        builder: (locationController) {
          final address = AddressHelper.getUserAddressFromSharedPref();
          final bool hasLocation = address != null &&
              address.latitude != null &&
              address.longitude != null;
          final bool isGuest = !AuthHelper.isLoggedIn();

          if (!hasLocation) {
            return _NoticePill(
              label: 'place_your_address_to_discover_services'.tr,
              trailingIcon: Icons.chevron_right,
              onTap: showAddressSelectionSheet,
            );
          }

          if (isGuest) {
            return _NoticePill(
              label: 'join_us_and_enjoy_shilla_services'.tr,
              trailingIcon: Icons.chevron_right,
              // "Join us" → guests must sign in first (address APIs need auth).
              onTap: () => Get.toNamed(RouteHelper.getSignInRoute('home')),
            );
          }

          // Logged-in user with a saved location → show the address.
          final String locationText =
              (address.address != null && address.address!.isNotEmpty)
                  ? AddressHelper().removeEnglishAndNumbers(address.address!)
                  : 'your_location'.tr;
          return _NoticePill(
            label: locationText,
            image: Images.location_v2,
            onTap: showAddressSelectionSheet,
          );
        },
      ),
    );
  }
}

class _NoticePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? image;
  final IconData? trailingIcon;

  const _NoticePill({
    required this.label,
    required this.onTap,
    this.image,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    const Color fill = Color(0xFFEBFEEB);

    // Container hugs its content (not full width) and aligns to the start (RTL: right).
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Material(
          color: fill,
          // Fully-rounded (stadium / pill) ends.
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall + 2,
                vertical: Dimensions.paddingSizeExtraSmall + 1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (image != null) ...[
                    Image.asset(
                      image!,
                      width: 16,
                      height: 16,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.location_on,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.83,
                        color: Color(0xFF121C19),
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Icon(trailingIcon, color: primary, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
