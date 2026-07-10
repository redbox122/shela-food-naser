import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfatoorah_flutter/MFModels.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

//

class PaymentMethodBottomSheet extends StatefulWidget {
  const PaymentMethodBottomSheet({super.key});

  @override
  State<PaymentMethodBottomSheet> createState() =>
      _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  // Form state
  final bool _isProcessing =
      false; // ✅ FIX: Removed 'final' to allow state change
  bool _isLoadingPaymentMethods = true;

  @override
  void initState() {
    super.initState();

    // Check if payment methods are already loaded — skip loading state entirely
    final checkoutController = Get.find<CheckoutController>();
    if (checkoutController.paymentMethods.isNotEmpty) {
      _isLoadingPaymentMethods = false;
      debugPrint('✅ Payment methods already available - no loading needed');
    } else {
      // Only fetch if not already loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPaymentMethods();
      });
    }
  }

  Future<void> _checkPaymentMethods() async {
    final checkoutController = Get.find<CheckoutController>();

    // If payment methods were loaded between initState and this callback
    if (checkoutController.paymentMethods.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingPaymentMethods = false;
        });
      }
      debugPrint(
          '✅ Payment methods already loaded: ${checkoutController.paymentMethods.length} - showing instantly');
      return;
    }

    // Only load if not already available
    try {
      debugPrint('🔄 Payment methods not loaded, loading now...');

      // Load payment methods with the current total amount
      await checkoutController.initiatePaymentWithAmount(
          context, checkoutController.viewTotalPrice.toString());

      if (mounted) {
        setState(() {
          _isLoadingPaymentMethods = false;
        });
      }

      debugPrint(
          '✅ Payment methods loaded: ${checkoutController.paymentMethods.length}');
    } catch (e) {
      debugPrint('❌ Error loading payment methods: $e');
      if (mounted) {
        setState(() {
          _isLoadingPaymentMethods = false;
        });
      }
      showCustomSnackBar('error_loading_payment_methods'.tr);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double sheetMaxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sheetMaxHeight),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF0F172A)
                  : theme.cardColor,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(Dimensions.radiusLarge),
                bottom: Radius.circular(ResponsiveHelper.isDesktop(context)
                    ? Dimensions.radiusLarge
                    : 0),
              ),
            ),
            // White fills through the bottom safe-area (no dark strip below).
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: GetBuilder<KaidhaSubscriptionController>(
                  builder: (KaidhaSubController) {
                    return GetBuilder<CheckoutController>(
                        builder: (checkoutController) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 6),
                            // Header: centered title + close (X) on the left.
                            SizedBox(
                              height: 32,
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'choose_digital_payment'.tr,
                                      textAlign: TextAlign.center,
                                      style: tajawalBold.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        height: 1.6,
                                        letterSpacing: 0,
                                        color: theme.brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : const Color(0xFF121C19),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: InkWell(
                                      onTap: () => Navigator.of(context).pop(),
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.close, size: 22),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Total — SAR symbol + amount (Tajawal Bold 32, 120%).
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  (checkoutController.viewTotalPrice ?? 0)
                                      .toStringAsFixed(2),
                                  textAlign: TextAlign.right,
                                  style: tajawalBold.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    letterSpacing: 0,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.asset(
                                  Images.sar,
                                  width: 21.33,
                                  height: 23.89,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildDigitalPaymentMethodsList(checkoutController),
                            const SizedBox(height: 24),
                            _buildActionButtons(checkoutController),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalPaymentMethodsList(
      CheckoutController checkoutController) {
    final theme = Theme.of(context);
    if (_isLoadingPaymentMethods) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('loading_payment_methods'.tr),
          ],
        ),
      );
    }

    if (checkoutController.paymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Images.add_payment_method,
              height: 150,
              width: 150,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text('no_payment_methods_available'.tr,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    // Filter payment methods based on platform
    final filteredPaymentMethods =
        _filterPaymentMethodsByPlatform(checkoutController.paymentMethods);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isDesktop(context) ? 4 : 3,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        // Figma card: 103 × 100 → aspect ratio 103/100.
        childAspectRatio:
            ResponsiveHelper.isDesktop(context) ? 1.15 : 103 / 100,
      ),
      itemCount: filteredPaymentMethods.length,
      itemBuilder: (context, index) {
        final paymentMethod = filteredPaymentMethods[index];
        final int originalIndex =
            checkoutController.paymentMethods.indexOf(paymentMethod);
        final bool isSelected = originalIndex >= 0 &&
            originalIndex < checkoutController.isSelected.length &&
            checkoutController.isSelected[originalIndex];

        return GestureDetector(
          onTap: () {
            if (originalIndex == -1) {
              return;
            }
            checkoutController.selectPaymentMethod(originalIndex);
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                  : (theme.brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Theme.of(context).cardColor),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (theme.brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 44,
                  width: 44,
                  child: SmartImage(
                    url: paymentMethod.imageUrl ?? '',
                    height: 44,
                    width: 44,
                    fit: BoxFit.contain,
                    cacheWidth: 300,
                    cacheHeight: 300,
                    errorWidget: const Icon(Icons.image_not_supported),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  paymentMethod.paymentMethodEn ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: tajawalBold.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                    fontSize: 14,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(CheckoutController checkoutController) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isProcessing ? null : () => _handlePayment(checkoutController),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'choose_payment_method'.tr,
                style: tajawalBold.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
      ),
    );
  }

  Future<void> _handlePayment(CheckoutController checkoutController) async {
    if (checkoutController.select_payment_Methods != null) {
      debugPrint(
          '✅ Payment method selected: ${checkoutController.select_payment_Methods!.paymentMethodAr}');

      // Close the modal first
      Navigator.of(context).pop();
    } else {
      showCustomSnackBar('please_select_payment_method_first'.tr);
    }
  }

  /// Filter payment methods based on platform
  /// Apple Pay remains enabled
  /// iOS: Hide Google Pay methods (if any)
  List<MFPaymentMethod> _filterPaymentMethodsByPlatform(
      List<MFPaymentMethod> paymentMethods) {
    return paymentMethods.where((method) {
      final methodCode = method.paymentMethodCode?.toLowerCase() ?? '';
      final methodEn = method.paymentMethodEn?.toLowerCase() ?? '';

      // On Android, keep all methods visible (including Apple Pay).
      if ((!kIsWeb && Platform.isAndroid)) {
        return true;
      }

      // On iOS, hide Google Pay methods (if any)
      if ((!kIsWeb && Platform.isIOS)) {
        return !methodCode.contains('gp') && !methodEn.contains('google');
      }

      // For other platforms, show all methods
      return true;
    }).toList();
  }
}
