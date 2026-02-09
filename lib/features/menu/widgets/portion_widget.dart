import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PortionWidget extends StatelessWidget {
  static DateTime? _lastTapAt;
  final String icon;
  final String title;
  final bool hideDivider;
  final String route;
  final String? suffix;
  final Function()? onTap;

  const PortionWidget(
      {super.key, required this.icon, required this.title, required this.route, this.hideDivider = false, this.suffix, this.onTap});

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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? _handleRouteTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Column(children: [
          Row(children: [
            Image.asset(icon, height: 23, width: 23),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Text(title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault))),
            suffix != null
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeSmall),
                    child: Text(suffix!,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
                        textDirection: TextDirection.ltr),
                  )
                : const SizedBox(),
          ]),
          hideDivider ? const SizedBox() : const Divider()
        ]),
      ),
    );
  }
}
