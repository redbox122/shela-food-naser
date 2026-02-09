import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

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

    return PopScope(
      canPop: false, // Prevent back button from closing
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress indicator
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
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
        return 'جارٍ تجهيز طلبك...';
      case 1:
        return 'جارٍ حساب رسوم التوصيل...';
      case 2:
        return 'أوشكنا على الانتهاء...';
      default:
        return 'جارٍ التحميل...';
    }
  }
}

/// Shows the checkout loading dialog and returns when dismissed
Future<void> showCheckoutLoadingDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => const CheckoutLoadingDialog(),
  );
}

/// Dismisses the checkout loading dialog if it's showing
void dismissCheckoutLoadingDialog(BuildContext context) {
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
