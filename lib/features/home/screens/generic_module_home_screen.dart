import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/base/module_home_screen_base.dart';

class GenericModuleHomeScreen extends ModuleHomeScreenBase {
  const GenericModuleHomeScreen({
    super.key,
    required super.moduleId,
    required super.moduleName,
    required super.moduleType,
  });

  @override
  State<GenericModuleHomeScreen> createState() =>
      _GenericModuleHomeScreenState();
}

class _GenericModuleHomeScreenState
    extends ModuleHomeScreenBaseState<GenericModuleHomeScreen> {}
