import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PortionWidget extends StatelessWidget {
  static DateTime? _lastTapAt;
  final String? icon;
  // When set, a crisp Material icon is drawn instead of an asset — used for
  // rows whose PNG asset is wrong/illustration (e.g. live chat, check updates).
  final IconData? iconData;
  final String title;
  final bool hideDivider;
  final String route;
  final String? suffix;
  final Function()? onTap;

  const PortionWidget(
      {super.key, this.icon, this.iconData, required this.title, required this.route, this.hideDivider = false, this.suffix, this.onTap});

  void _handleRouteTap() {
    final now = DateTime.now();
    if (_lastTapAt != null && now.difference(_lastTapAt!).inMilliseconds < 500) {
      return;
    }
    _lastTapAt = now;

    if (Get.currentRoute == route) {
      return;
    }
    Get.toNamed(route);
  }

  static const Color _navy = Color(0xFF42526E);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? _handleRouteTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            // Icon inside a soft rounded tile for a clean, consistent look.
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconData != null
                  ? Icon(iconData, size: 21, color: _navy)
                  : (icon != null
                      ? Image.asset(icon!, height: 21, width: 21)
                      : const SizedBox(width: 21, height: 21)),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Text(
                title,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
            ),
            if (suffix != null)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeExtraSmall,
                    horizontal: Dimensions.paddingSizeSmall),
                child: Text(suffix!,
                    style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall, color: Colors.white),
                    textDirection: TextDirection.ltr),
              )
            else
              // Navigation chevron (points to the start side in RTL).
              Icon(Icons.chevron_left,
                  size: 22, color: Theme.of(context).hintColor),
          ]),
        ),
        // Divider aligned under the title (indented past the icon tile).
        hideDivider
            ? const SizedBox()
            : const Padding(
                padding: EdgeInsetsDirectional.only(start: 52),
                child: Divider(height: 1, thickness: 0.6),
              ),
      ]),
    );
  }
}
