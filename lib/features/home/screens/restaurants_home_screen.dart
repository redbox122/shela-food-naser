import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/base/module_home_screen_base.dart';

class RestaurantsHomeScreen extends ModuleHomeScreenBase {
  const RestaurantsHomeScreen({
    super.key,
    required super.moduleId,
    required super.moduleName,
    required super.moduleType,
  });

  @override
  State<RestaurantsHomeScreen> createState() => _RestaurantsHomeScreenState();
}

class _RestaurantsHomeScreenState
    extends ModuleHomeScreenBaseState<RestaurantsHomeScreen> {}
