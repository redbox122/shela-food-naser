// TEMPORARY preview entrypoint for the new Keeta-style payment screens.
// Run with:  flutter run -t lib/preview_payment_main.dart
// Touches NO existing app code. Safe to delete after design review.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/payment/presentation/screens/payment_method_screen.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();
  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shella Payment Preview',
      themeMode: _mode,
      theme: ThemeData(brightness: Brightness.light, fontFamily: 'Tajawal'),
      darkTheme: ThemeData(brightness: Brightness.dark, fontFamily: 'Tajawal'),
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            child ?? const SizedBox(),
            Positioned(
              bottom: 30,
              left: 16,
              child: SafeArea(
                child: FloatingActionButton.small(
                  heroTag: 'themeToggle',
                  onPressed: () => setState(() => _mode =
                      _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
                  child: Icon(_mode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode),
                ),
              ),
            ),
          ],
        ),
      ),
      home: PaymentMethodScreen(
        total: 63.82,
        walletBalance: 0,
        onPay: (sel) => Get.snackbar(
          'الدفع (معاينة)',
          'الطريقة: ${sel.method.name}  •  الإكرامية: ${sel.tip}  •  المحفظة: ${sel.useWallet}',
          snackPosition: SnackPosition.BOTTOM,
        ),
      ),
    );
  }
}
