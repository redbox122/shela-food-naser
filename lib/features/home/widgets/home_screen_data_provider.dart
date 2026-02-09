import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/home/domain/models/business_settings_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';

/// Home Screen Data Provider Widget
/// 
/// Reduces GetBuilder nesting by combining HomeController and SplashController data
/// This widget provides a single GetBuilder that exposes both controllers' data
class HomeScreenDataProvider extends StatelessWidget {
  final Widget Function({
    required BusinessSettingsModel? settings,
    required ModuleModel? module,
    required bool isEcommerce,
    required bool isFood,
    required bool isGrocery,
  }) builder;

  const HomeScreenDataProvider({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (homeController) {
        return GetBuilder<SplashController>(
          builder: (splashController) {
            final settings = homeController.business_Settings;
            final module = splashController.module;
            final moduleType = module?.moduleType.toString();
            
            final isEcommerce = moduleType == 'ecommerce';
            final isFood = moduleType == 'food';
            final isGrocery = moduleType == 'grocery';

            return builder(
              settings: settings,
              module: module,
              isEcommerce: isEcommerce,
              isFood: isFood,
              isGrocery: isGrocery,
            );
          },
        );
      },
    );
  }
}

