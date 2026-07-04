import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Empty-state message for the offers list. When [canReset] is true (active
/// filters/search are narrowing the results), it also offers a "reset" button
/// that invokes [onReset].
class OffersNoResultsView extends StatelessWidget {
  final String message;
  final bool canReset;
  final VoidCallback onReset;

  const OffersNoResultsView({
    super.key,
    required this.message,
    required this.canReset,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          top: ResponsiveHelper.isDesktop(context)
              ? context.height * 0.3
              : context.height * 0.4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (canReset) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              OutlinedButton(
                onPressed: onReset,
                child: Text('reset'.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
