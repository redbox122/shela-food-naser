import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/styles.dart';

class OnboardingSkipButton extends StatelessWidget {
  final VoidCallback onTap;
  const OnboardingSkipButton({super.key, required this.onTap});

  static const Color _fill = Color(0xFFEDF2FB); // pale blue
  static const Color _text = Color(0xFF44546A); // muted slate

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _fill,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF44546A).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'skip'.tr,
            style: tajawalMedium.copyWith(
              fontSize: 15,
              color: _text,
            ),
          ),
        ),
      ),
    );
  }
}
