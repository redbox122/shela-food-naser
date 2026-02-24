import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/base/module_home_screen_base.dart';

class PharmacyHomeScreen extends ModuleHomeScreenBase {
  const PharmacyHomeScreen({
    super.key,
    required super.moduleId,
    required super.moduleName,
    required super.moduleType,
  });

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState
    extends ModuleHomeScreenBaseState<PharmacyHomeScreen> {}
