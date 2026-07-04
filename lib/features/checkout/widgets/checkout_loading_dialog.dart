import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';

/// Loading dialog shown while preparing checkout data
/// Shows an engaging animation with progress messages
class CheckoutLoadingDialog extends StatefulWidget {
  const CheckoutLoadingDialog({super.key});

  @override
  State<CheckoutLoadingDialog> createState() => _CheckoutLoadingDialogState();
}

class _CheckoutLoadingDialogState extends State<CheckoutLoadingDialog> {
  int _currentMessageIndex = 0;

  // Messages to cycle through while loading
  final List<String> _messages = [
    'preparing_your_order',
    'calculating_delivery',
    'almost_ready',
  ];

  @override
  void initState() {
    super.initState();
    _startMessageCycle();
  }

  void _startMessageCycle() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
        });
        _startMessageCycle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isRTL = Get.locale?.languageCode == 'ar';
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>();

    return PopScope(
      canPop: false, // Prevent back button from closing
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (tokens?.outlineSoft ?? theme.dividerColor)
                    .withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie animation
              Lottie.asset(
                'assets/json/waiting.json',
                fit: BoxFit.contain,
                height: size.height * 0.2,
              ),

              const SizedBox(height: 20),

              // Animated message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isRTL
                      ? _getArabicMessage(_currentMessageIndex)
                      : _messages[_currentMessageIndex].tr,
                  key: ValueKey(_currentMessageIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress indicator
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor:
                      theme.primaryColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getArabicMessage(int index) {
    switch (index) {
      case 0:
        return 'pay_preparing_order'.tr;
      case 1:
        return 'pay_calc_delivery'.tr;
      case 2:
        return 'pay_almost_done'.tr;
      default:
        return 'pay_loading'.tr;
    }
  }
}

/// Shows the checkout loading dialog and returns when dismissed
bool _isCheckoutLoadingDialogVisible = false;

Future<void> showCheckoutLoadingDialog(BuildContext context) {
  if (_isCheckoutLoadingDialogVisible) {
    return Future.value();
  }
  _isCheckoutLoadingDialogVisible = true;
  return Get.dialog<void>(
    const CheckoutLoadingDialog(),
    barrierDismissible: false,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
  ).whenComplete(() {
    _isCheckoutLoadingDialogVisible = false;
  });
}

/// Dismisses checkout loading dialog safely after navigation frame.
/// Use this when route transitions are in progress to avoid Navigator lock assertions.
void dismissCheckoutLoadingDialogSafely([BuildContext? context]) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    dismissCheckoutLoadingDialog(context);
  });
}

/// Dismisses the checkout loading dialog if it's showing
void dismissCheckoutLoadingDialog([BuildContext? context]) {
  try {
    if (!_isCheckoutLoadingDialogVisible) {
      return;
    }

    // Important: never pop navigator routes here unless the dialog overlay
    // is actually open; otherwise we may pop checkout/cart pages by mistake.
    if (Get.isDialogOpen ?? false) {
      Get.back<void>();
    }

    _isCheckoutLoadingDialogVisible = false;
  } catch (_) {
    // Navigator may be locked during route transitions. Retry safely next frame.
    dismissCheckoutLoadingDialogSafely(context);
  }
}
