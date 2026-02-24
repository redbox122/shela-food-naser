import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/controllers/home_unified_controller.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';

abstract class ModuleHomeScreenBase extends StatefulWidget {
  final int moduleId;
  final String moduleName;
  final String moduleType;

  const ModuleHomeScreenBase({
    super.key,
    required this.moduleId,
    required this.moduleName,
    required this.moduleType,
  });
}

abstract class ModuleHomeScreenBaseState<T extends ModuleHomeScreenBase>
    extends State<T> with AutomaticKeepAliveClientMixin<T> {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureModuleReady);
  }

  Future<void> _ensureModuleReady() async {
    if (Get.isRegistered<HomeUnifiedController>()) {
      try {
        final controller = Get.find<HomeUnifiedController>();
        controller.allowImmediateFetchForModule(widget.moduleId);
        await controller.onModuleReady(widget.moduleId);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              'ModuleHomeScreenBase: onModuleReady failed for module ${widget.moduleId}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return HomeScreen(
      key: ValueKey('home_module_${widget.moduleId}'),
    );
  }
}
