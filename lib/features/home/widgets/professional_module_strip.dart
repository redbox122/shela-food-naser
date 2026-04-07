
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Modern Module Switcher Strip
/// Clean chip-based design with icon + text for each module
/// White background with active module highlighted
/// RTL: Active module on right, swipe right to see more
/// LTR: Active module on left, swipe left to see more
class ProfessionalModuleStrip extends StatelessWidget {
  const ProfessionalModuleStrip({super.key});

  void _switchModule(
    BuildContext context,
    ModuleModel module,
    int moduleIndex,
  ) {
    final splashController = Get.find<SplashController>();

    // switchModule now handles navigation internally
    splashController.switchModule(context, moduleIndex, true);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        final currentModule = splashController.module;
        final moduleList = splashController.moduleList ?? [];
        const disabledModuleIds = <int>{7, 8};
        final sortedModules = [
          ...moduleList.where((m) => !disabledModuleIds.contains(m.id)),
          ...moduleList.where((m) => disabledModuleIds.contains(m.id)),
        ];

        // Don't show if no module selected or less than 2 modules
        if (currentModule == null ||
            moduleList.isEmpty ||
            moduleList.length < 2) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: 6,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // No reverse - Flutter's native RTL/LTR handling works perfectly
            // RTL (Arabic): Active module shows on right, swipe right to see more
            // LTR (English): Active module shows on left, swipe left to see more
            itemCount: sortedModules.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final module = sortedModules[index];
              final isCurrent = module.id == currentModule.id;
              final isDisabled = disabledModuleIds.contains(module.id);
              
              return _buildModuleChip(
                context,
                module,
                isCurrent,
                moduleList,
                isDisabled,
                index,
              );
            },
          ),
        );
      },
    );
  }

  /// Builds a modern chip-style module selector
  Widget _buildModuleChip(
    BuildContext context,
    ModuleModel module,
    bool isActive,
    List<ModuleModel> moduleList,
    bool isDisabled,
    int index,
  ) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
        final moduleIndex = moduleList.indexOf(module);
        if (moduleIndex >= 0 && !isActive) {
          _switchModule(context, module, moduleIndex);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // Active: Filled with primary color
          // Inactive: White with gray border
          color: isDisabled
              ? Colors.grey.withValues(alpha: 0.2)
              : isActive 
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.withValues(alpha: 0.4)
                : isActive 
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor.withValues(alpha: 0.7),
            width: isActive && !isDisabled ? 2 : 1.5,
          ),
          boxShadow: isActive && !isDisabled
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Theme.of(context)
                        .shadowColor
                        .withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Module icon
            Hero(
              tag: 'module_icon_prof_strip_${module.id}_$index',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive 
                        ? Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.35)
                        : Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      CustomImage(
                        image: module.iconFullUrl ?? '',
                        width: 32,
                        height: 32,
                        placeholder: Images.placeholder,
                      ),
                      if (isDisabled)
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: const Text(
                            '\u0642\u0631\u064a\u0628\u0627',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Module name
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                module.moduleName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: isDisabled
                      ? Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.5)
                      : isActive
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
