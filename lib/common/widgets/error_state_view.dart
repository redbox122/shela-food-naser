import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ErrorStateView extends StatelessWidget {
  final VoidCallback onRetry;
  final String titleKey;
  final String subtitleKey;

  const ErrorStateView({
    super.key,
    required this.onRetry,
    this.titleKey = 'something_went_wrong',
    this.subtitleKey = 'no_internet_connection',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 54,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              titleKey.tr,
              textAlign: TextAlign.center,
              style: robotoMedium.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              subtitleKey.tr,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
