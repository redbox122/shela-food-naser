// "إضافة بطاقة جديدة" — approved Keeta-style card screen (phase 1 UI).
// Confirm currently returns the intent to the caller; phase 2 swaps the form
// for MyFatoorah's PCI-compliant embedded session.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/payment/presentation/keeta_pay_style.dart';
import 'package:sixam_mart/features/payment/presentation/widgets/card_form_widget.dart';

class AddCardScreen extends StatelessWidget {
  final VoidCallback? onConfirm;
  const AddCardScreen({super.key, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final s = KeetaPayStyle.of(context);
    return Scaffold(
      backgroundColor: s.screen,
      appBar: AppBar(
        backgroundColor: s.screen,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: s.ink),
        title: Text('إضافة بطاقة جديدة', style: s.t(18, weight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: const CardFormWidget(showError: false),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: s.green,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onConfirm ?? () => Get.back<void>(),
            child: Text('تأكيد',
                style: s.t(16, weight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
