import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfatoorah_flutter/MFModels.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
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
      showCustomSnackBar('خطأ في تحميل طرق الدفع');
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
    return SafeArea(
      top: false,
      bottom: true,
      left: false,
      right: false,
      minimum: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: sheetMaxHeight),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(Dimensions.radiusLarge),
                  bottom: Radius.circular(ResponsiveHelper.isDesktop(context)
                      ? Dimensions.radiusLarge
                      : 0),
                ),
              ),
              child: GetBuilder<KaidhaSubscription_Controller>(
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
                          const SizedBox(height: 10),
                          const Text('اختر طريقة الدفع',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          PriceConverter.convertPrice2(
                            checkoutController.viewTotalPrice,
                            textStyle: robotoBold.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeOverLarge,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDigitalPaymentMethodsList(checkoutController),
                          const SizedBox(height: 20),
                          const LinearProgressIndicator(value: 0.1),
                          const SizedBox(height: 20),
                          _buildActionButtons(checkoutController),
                          const SizedBox(height: 30),
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
    );
  }

  Widget _buildDigitalPaymentMethodsList(
      CheckoutController checkoutController) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();
    if (_isLoadingPaymentMethods) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل طرق الدفع...'),
          ],
        ),
      );
    }

    if (checkoutController.paymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('لا توجد طرق دفع متاحة',
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
        childAspectRatio: ResponsiveHelper.isDesktop(context) ? 1.15 : 1.28,
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
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.12)
                  : (tokens?.surfaceSoft ?? Theme.of(context).cardColor),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 36,
                  width: 36,
                  child: SmartImage(
                    url: paymentMethod.imageUrl ?? '',
                    height: 36,
                    width: 36,
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
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
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
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: robotoMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
          ),
        ),
        SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: ElevatedButton(
            onPressed:
                _isProcessing ? null : () => _handlePayment(checkoutController),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                    'اختيار طريقة الدفع',
                    style: robotoMedium.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment(CheckoutController checkoutController) async {
    if (checkoutController.select_payment_Methods != null) {
      debugPrint(
          '✅ Payment method selected: ${checkoutController.select_payment_Methods!.paymentMethodAr}');

      // Close the modal first
      Navigator.of(context).pop();
    } else {
      showCustomSnackBar('يرجى اختيار طريقة دفع أولاً');
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
      if (Platform.isAndroid) {
        return true;
      }

      // On iOS, hide Google Pay methods (if any)
      if (Platform.isIOS) {
        return !methodCode.contains('gp') && !methodEn.contains('google');
      }

      // For other platforms, show all methods
      return true;
    }).toList();
  }
}
