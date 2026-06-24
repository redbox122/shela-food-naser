import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/util/dimensions.dart';

class ModulesViewWidget extends StatelessWidget {
  const ModulesViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      final moduleList = splashController.moduleList;
      // Coming-soon modules. id 8 (الصيدليات/pharmacy) enabled per request;
      // id 7 (المحلات التجارية/grocery) stays disabled. Restaurants (6) and
      // cafés (9) were already enabled.
      const disabledModuleIds = <int>{}; // dashboard controls module status

      final List<ModuleModel> fallbackModules = [
        ModuleModel(id: -1, moduleName: 'شيلا ماركت', moduleType: 'ecommerce'),
        ModuleModel(id: -2, moduleName: 'مطاعم', moduleType: 'food'),
        ModuleModel(id: -3, moduleName: 'مقاهي', moduleType: 'food'),
        ModuleModel(id: -4, moduleName: 'صيدليات', moduleType: 'pharmacy'),
        ModuleModel(
            id: -5, moduleName: 'محلات تجارية', moduleType: 'ecommerce'),
      ];

      final bool isFallbackList = moduleList == null || moduleList.isEmpty;
      final List<ModuleModel> modules =
          isFallbackList ? fallbackModules : (moduleList).cast<ModuleModel>();
      final List<ModuleModel> sortedModules = [
        ...modules.where((module) => !disabledModuleIds.contains(module.id)),
        ...modules.where((module) => disabledModuleIds.contains(module.id)),
      ];

      return (moduleList != null && moduleList.isNotEmpty) || modules.isNotEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                const mainAxisSpacing = 10.0;
                const itemHeight = 72.0;
                final bool isFallback = isFallbackList;
                if (kDebugMode && isFallback) {
                  debugPrint(
                      '⚠️ ModulesViewWidget: Using fallback module list (API modules missing)');
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault),
                      child: TitleWidget(
                        title: 'our_services'.tr,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Stack(
                        children: [
                          AnimationLimiter(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedModules.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: mainAxisSpacing),
                              itemBuilder: (context, index) {
                                final module = sortedModules[index];
                                final bool isDisabled = isFallback ||
                                    disabledModuleIds.contains(module.id);
                                final bool blockedBySwitch =
                                    splashController.isModuleSwitching;
                                final bool isTapDisabled =
                                    isDisabled || blockedBySwitch;
                                return SizedBox(
                                  height: itemHeight,
                                  child: AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: InkWell(
                                          onTap: isTapDisabled
                                              ? null
                                              : () {
                                                  HapticFeedback.lightImpact();
                                                  try {
                                                    if (kDebugMode) {
                                                      debugPrint(
                                                          '👆 ModulesViewWidget: Module tapped -> id=${module.id} name=${module.moduleName}');
                                                    }
                                                    splashController
                                                        .selectModule(module,
                                                            context: context);
                                                    if (kDebugMode) {
                                                      debugPrint(
                                                          '✅ ModulesViewWidget: selectModule() call completed');
                                                    }
                                                  } catch (e, stackTrace) {
                                                    debugPrint(
                                                        '❌ ModulesViewWidget: Error selecting module: $e');
                                                    debugPrint(
                                                        'Stack trace: $stackTrace');
                                                    if (context.mounted) {
                                                      Get.snackbar(
                                                        'Error',
                                                        'Failed to select module. Please try again.',
                                                        snackPosition:
                                                            SnackPosition
                                                                .BOTTOM,
                                                      );
                                                    }
                                                  }
                                                },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isTapDisabled
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.10)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .shadowColor
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal:
                                                  Dimensions.paddingSizeDefault,
                                              vertical:
                                                  Dimensions.paddingSizeSmall,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: 44,
                                                  width: 44,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withValues(
                                                            alpha: 0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Hero(
                                                      tag:
                                                          'module_icon_modules_${module.id}_$index',
                                                      child: Stack(
                                                        children: [
                                                          CustomImage(
                                                            image: module
                                                                    .iconFullUrl ??
                                                                '',
                                                            height: 44,
                                                            width: 44,
                                                            fit: BoxFit.contain,
                                                          ),
                                                          if (isDisabled)
                                                            Container(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                      alpha:
                                                                          0.45),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                isFallback
                                                                    ? 'قريباً'
                                                                    : 'قريباً',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeDefault),
                                                Expanded(
                                                  child: Text(
                                                    module.moduleName ?? '',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isTapDisabled
                                                          ? Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color
                                                              ?.withValues(
                                                                  alpha: 0.5)
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (splashController.isModuleSwitching)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .scrim
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'جاري التبديل...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
          : const SizedBox(); // No shimmer needed, modules should be loaded already
    });
  }
}
