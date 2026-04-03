import 'package:flutter/material.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class TaxiHomeScreen extends StatefulWidget {
  const TaxiHomeScreen({super.key});

  @override
  State<TaxiHomeScreen> createState() => _TaxiHomeScreenState();
}

class _TaxiHomeScreenState extends State<TaxiHomeScreen> {

  @override
  Widget build(BuildContext context) {
    // Log page entry on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appLogger.logPageEntry('TaxiHomeScreen');
      appLogger.info('🏠 TaxiHomeScreen: Building (placeholder)');
    });
    
    // Note: Implement Taxi Home Screen
    // Note: TaxiHomeController and TaxiHomeRepository are currently unimplemented.
    // This is a placeholder.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(Images.carIcon, width: 100, height: 100, color: Theme.of(context).disabledColor),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'Taxi Service Coming Soon',
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }
}




