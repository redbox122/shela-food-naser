import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// A single onboarding page: illustration on top, title + description below.
class OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.illustration,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        children: [
          const Spacer(flex: 3),
          illustration,
          const Spacer(flex: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: tajawalBold.copyWith(
              fontSize: 20,
              height: 1.0,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            description,
            textAlign: TextAlign.center,
            style: tajawalMedium.copyWith(
              fontSize: 15,
              height: 1.0,
              color: Colors.black,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
