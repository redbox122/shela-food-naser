import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/base/module_home_screen_base.dart';

class EcommerceHomeScreen extends ModuleHomeScreenBase {
  const EcommerceHomeScreen({
    super.key,
    required super.moduleId,
    required super.moduleName,
    required super.moduleType,
  });

  @override
  State<EcommerceHomeScreen> createState() => _EcommerceHomeScreenState();
}

class _EcommerceHomeScreenState
    extends ModuleHomeScreenBaseState<EcommerceHomeScreen> {}
