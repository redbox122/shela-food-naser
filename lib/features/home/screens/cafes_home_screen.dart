import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/base/module_home_screen_base.dart';

class CafesHomeScreen extends ModuleHomeScreenBase {
  const CafesHomeScreen({
    super.key,
    required super.moduleId,
    required super.moduleName,
    required super.moduleType,
  });

  @override
  State<CafesHomeScreen> createState() => _CafesHomeScreenState();
}

class _CafesHomeScreenState
    extends ModuleHomeScreenBaseState<CafesHomeScreen> {}
