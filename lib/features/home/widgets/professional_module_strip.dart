
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/home/controllers/akhdamni_flow_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/home/widgets/akhdamni/akhdamni_strings.dart';

/// UI-only service chips shown after pharmacy in the home module strip.
class _LocalServiceChipData {
  const _LocalServiceChipData({
    required this.id,
    required this.label,
    required this.assetPath,
  });

  final int id;
  final String label;
  final String assetPath;
}

const List<_LocalServiceChipData> _localServiceChipsAfterPharmacy = [
  _LocalServiceChipData(
    id: AkhdamniFlowController.akhdamniChipId,
    label: AkhdamniStrings.chipServiceMe,
    assetPath: Images.serves,
  ),
  _LocalServiceChipData(
    id: AkhdamniFlowController.pickupDeliveryChipId,
    label: AkhdamniStrings.chipPickupDelivery,
    assetPath: Images.giving,
  ),
];

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

  void _exitAkhdamniFlowIfNeeded() {
    if (Get.isRegistered<AkhdamniFlowController>()) {
      Get.find<AkhdamniFlowController>().exitFlow();
    }
  }

  static bool _isPharmacyModule(ModuleModel module) {
    final String moduleType =
        (module.moduleType ?? '').toString().trim().toLowerCase();
    final String moduleName =
        (module.moduleName ?? '').toString().trim().toLowerCase();
    return moduleType == AppConstants.pharmacy ||
        moduleName.contains('صيدل') ||
        moduleName.contains('pharmacy') ||
        moduleName.contains('pharm');
  }

  static List<Object> _buildStripItems(List<ModuleModel> sortedModules) {
    final List<Object> items = List<Object>.from(sortedModules);
    final int pharmacyIndex = sortedModules.indexWhere(_isPharmacyModule);
    final int insertAt = pharmacyIndex >= 0 ? pharmacyIndex + 1 : items.length;
    items.insertAll(insertAt, _localServiceChipsAfterPharmacy);
    return items;
  }

  void _onLocalServiceChipTap(_LocalServiceChipData chip) {
    if (chip.id == AkhdamniFlowController.akhdamniChipId) {
      if (Get.isRegistered<AkhdamniFlowController>()) {
        Get.find<AkhdamniFlowController>().enterAkhdamniFlow();
      }
      return;
    }
    _exitAkhdamniFlowIfNeeded();
    if (kDebugMode) {
      debugPrint(
        '[ModuleStrip][LOCAL_SERVICE_TAP] id=${chip.id} label=${chip.label} asset=${chip.assetPath}',
      );
    }
    Get.rawSnackbar(message: AkhdamniStrings.comingSoon);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AkhdamniFlowController>(
      builder: (akhdamniController) {
        return GetBuilder<SplashController>(
          builder: (splashController) {
            final currentModule = splashController.module;
            final moduleList = splashController.moduleList ?? [];
            const disabledModuleIds = <int>{}; // dashboard controls module status
            final sortedModules = [
              ...moduleList.where((m) => !disabledModuleIds.contains(m.id)),
              ...moduleList.where((m) => disabledModuleIds.contains(m.id)),
            ];
            final stripItems = _buildStripItems(sortedModules);
            final bool isAkhdamniFlowActive = akhdamniController.isFlowActive;

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
                itemCount: stripItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final Object item = stripItems[index];
                  if (item is _LocalServiceChipData) {
                    final bool isActive =
                        akhdamniController.activeLocalChipId == item.id;
                    return _buildLocalServiceChip(
                      context,
                      item,
                      index,
                      isActive: isActive,
                    );
                  }
                  final module = item as ModuleModel;
                  final isCurrent = !isAkhdamniFlowActive &&
                      module.id == currentModule.id;
                  final isDisabled = disabledModuleIds.contains(module.id);
                  return _buildModuleChip(
                    context,
                    module,
                    currentModule,
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
      },
    );
  }

  Widget _buildLocalServiceChip(
    BuildContext context,
    _LocalServiceChipData chip,
    int index, {
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _onLocalServiceChipTap(chip),
      child: _buildChipShell(
        context,
        isActive: isActive,
        isDisabled: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'module_icon_prof_strip_local_${chip.id}_$index',
              child: _buildCircularIconShell(
                context,
                isActive: isActive,
                child: ClipOval(
                  child: Image.asset(
                    chip.assetPath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                chip.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: isActive
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

  /// Builds a modern chip-style module selector
  Widget _buildModuleChip(
    BuildContext context,
    ModuleModel module,
    ModuleModel currentModule,
    bool isActive,
    List<ModuleModel> moduleList,
    bool isDisabled,
    int index,
  ) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              _exitAkhdamniFlowIfNeeded();
              final int moduleIndex = moduleList.indexOf(module);
              if (moduleIndex >= 0 && module.id != currentModule.id) {
                _switchModule(context, module, moduleIndex);
              }
            },
      child: _buildChipShell(
        context,
        isActive: isActive,
        isDisabled: isDisabled,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'module_icon_prof_strip_${module.id}_$index',
              child: _buildCircularIconShell(
                context,
                isActive: isActive,
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

  Widget _buildChipShell(
    BuildContext context, {
    required bool isActive,
    required bool isDisabled,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
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
      child: child,
    );
  }

  Widget _buildCircularIconShell(
    BuildContext context, {
    required bool isActive,
    required Widget child,
  }) {
    return Container(
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
              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
