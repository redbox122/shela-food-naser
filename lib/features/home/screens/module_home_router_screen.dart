import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/cafes_home_screen.dart';
import 'package:sixam_mart/features/home/screens/ecommerce_home_screen.dart';
import 'package:sixam_mart/features/home/screens/generic_module_home_screen.dart';
import 'package:sixam_mart/features/home/screens/pharmacy_home_screen.dart';
import 'package:sixam_mart/features/home/screens/restaurants_home_screen.dart';

class ModuleHomeRouterScreen extends StatelessWidget {
  final int moduleId;
  final String? moduleName;
  final String? moduleType;

  const ModuleHomeRouterScreen({
    super.key,
    required this.moduleId,
    this.moduleName,
    this.moduleType,
  });

  @override
  Widget build(BuildContext context) {
    return _buildScreen();
  }

  Widget _buildScreen() {
    switch ((moduleType ?? '').toLowerCase()) {
      case 'ecommerce':
        return EcommerceHomeScreen(
          moduleId: moduleId,
          moduleName: moduleName ?? '',
          moduleType: moduleType ?? 'ecommerce',
        );
      case 'food':
      case 'restaurant':
        return RestaurantsHomeScreen(
          moduleId: moduleId,
          moduleName: moduleName ?? '',
          moduleType: moduleType ?? 'food',
        );
      case 'cafe':
        return CafesHomeScreen(
          moduleId: moduleId,
          moduleName: moduleName ?? '',
          moduleType: moduleType ?? 'cafe',
        );
      case 'pharmacy':
        return PharmacyHomeScreen(
          moduleId: moduleId,
          moduleName: moduleName ?? '',
          moduleType: moduleType ?? 'pharmacy',
        );
      default:
        return GenericModuleHomeScreen(
          moduleId: moduleId,
          moduleName: moduleName ?? '',
          moduleType: moduleType ?? '',
        );
    }
  }
}
