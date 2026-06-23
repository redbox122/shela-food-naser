import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 🚧 TEMPORARY: Per-service storefront destination (e.g. "شاشة الماركت").
///
/// Tapping a service card in [HomeServicesGrid] lands here so navigation works
/// end-to-end. For now it is just a centered title; the real design for each
/// service screen will replace this later. [moduleType] is carried through so
/// that screen can load the right module's data.
class ModuleStorefrontScreen extends StatelessWidget {
  final String title;
  final String moduleType;

  /// Module id this service loads its data from (e.g. restaurants = 3).
  final int? moduleId;

  const ModuleStorefrontScreen({
    super.key,
    required this.title,
    required this.moduleType,
    this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
          onPressed: () => Get.back<void>(),
        ),
      ),
      body: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFF121C19),
          ),
        ),
      ),
    );
  }
}
