import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: Shown when the user picks a point outside the service zones.
///
/// Offers to auto-redirect to the nearest serviceable area, or to go back home.
class OutOfZoneDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const OutOfZoneDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Images.deistination_v2,
              width: 186,
              height: 167,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.location_off,
                size: 96,
                color: primary,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'area_outside_service_zone'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 1.0,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'redirect_to_nearest_zone_question'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                height: 1.2,
                color: Color(0xFF121C19),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
                onPressed: onConfirm,
                child: Text(
                  'yes_direct_me'.tr,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF6F6F6),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
                onPressed: onCancel,
                child: Text(
                  'no_back_to_home'.tr,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.6,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the out-of-zone dialog, closing it before running the chosen callback.
void showOutOfZoneDialog({
  required VoidCallback onConfirm,
  required VoidCallback onCancel,
}) {
  Get.dialog<void>(
    OutOfZoneDialog(
      onConfirm: () {
        Future.microtask(() {
          Get.back<void>();
          onConfirm();
        });
      },
      onCancel: () {
        Future.microtask(() {
          Get.back<void>();
          onCancel();
        });
      },
    ),
    barrierDismissible: true,
  );
}
