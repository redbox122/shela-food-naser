
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Collapsible Module Switcher Widget
/// Shows current module when collapsed, all modules when expanded
/// Allows quick module switching from any module's home screen
class CollapsibleModuleSwitcher extends StatefulWidget {
  const CollapsibleModuleSwitcher({super.key});

  @override
  State<CollapsibleModuleSwitcher> createState() =>
      _CollapsibleModuleSwitcherState();
}

class _CollapsibleModuleSwitcherState extends State<CollapsibleModuleSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Handle scroll update notifications
    if (notification is ScrollUpdateNotification) {
      final currentOffset = notification.metrics.pixels;
      final scrollDelta = currentOffset - _lastScrollOffset;

      // Scroll down: expand if collapsed
      if (scrollDelta > 0 && !_isExpanded && scrollDelta > 50) {
        setState(() {
          _isExpanded = true;
          _expandController.forward();
        });
      }
      // Scroll up: collapse if expanded (only if scrolled up significantly)
      else if (scrollDelta < 0 && _isExpanded && scrollDelta < -30) {
        setState(() {
          _isExpanded = false;
          _expandController.reverse();
        });
      }

      _lastScrollOffset = currentOffset;
    }
    
    // Always return false to allow notification to continue propagating
    return false;
  }

  Future<void> _switchModule(
    BuildContext context,
    ModuleModel module,
    int moduleIndex,
  ) async {
    final splashController = Get.find<SplashController>();

    // Collapse switcher before switching
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _expandController.reverse();
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // ⚡ INSTANT SWITCH: No navigation, just update state
    // switchModule() handles state update and background loading
    // The HomeScreen will rebuild automatically via GetBuilder when module changes
    if (!context.mounted) {
      return;
    }
    splashController.switchModule(context, moduleIndex, true);
    // ✅ NO NAVIGATION - state update triggers rebuild
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        final currentModule = splashController.module;
        final moduleList = splashController.moduleList ?? [];
        const disabledModuleIds = <int>{}; // dashboard controls module status
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

        // Wrap with NotificationListener to detect scroll
        return NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Collapsed state header - always visible
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    child: Row(
                      children: [
                        // Current module icon
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Hero(
                            tag: 'module_icon_switcher_current_${currentModule.id}',
                            flightShuttleBuilder: (
                              BuildContext flightContext,
                              Animation<double> animation,
                              HeroFlightDirection flightDirection,
                              BuildContext fromHeroContext,
                              BuildContext toHeroContext,
                            ) {
                              final Hero toHero = toHeroContext.widget as Hero;
                              return ScaleTransition(
                                scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: toHero.child,
                                ),
                              );
                            },
                            child: Material(
                              color: Colors.transparent,
                              child: ClipOval(
                                child: CustomImage(
                                  image: currentModule.iconFullUrl ?? '',
                                  width: 45,
                                  height: 45,
                                  placeholder: Images.placeholder,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeDefault),
                        // Current module name
                        Expanded(
                          child: Text(
                            currentModule.moduleName ?? '',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Arrow icon
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 300),
                          turns: _isExpanded ? 0.5 : 0.0,
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded state - animated height
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    padding: const EdgeInsets.only(
                      bottom: Dimensions.paddingSizeDefault,
                      left: Dimensions.paddingSizeDefault,
                      right: Dimensions.paddingSizeDefault,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: sortedModules.asMap().entries.map((entry) {
                          final module = entry.value;
                          final isCurrent = module.id == currentModule.id;
                          final isDisabled =
                              disabledModuleIds.contains(module.id);
                          final moduleIndex = moduleList
                              .indexWhere((m) => m.id == module.id);

                          return GestureDetector(
                            onTap: isDisabled || moduleIndex == -1
                                ? null
                                : () => _switchModule(context, module, moduleIndex),
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: Dimensions.paddingSizeDefault,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Module icon
                                  Container(
                                    width: 75,
                                    height: 75,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.secondaryColor
                                            : Colors.white.withValues(alpha: 0.3),
                                        width: isCurrent ? 3 : 2,
                                      ),
                                      boxShadow: isCurrent
                                          ? [
                                              BoxShadow(
                                                color: AppColors.secondaryColor
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 15,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: Hero(
                                      tag: 'module_icon_switcher_${module.id}_${entry.key}',
                                      child: ClipOval(
                                        child: Stack(
                                          children: [
                                            CustomImage(
                                              image: module.iconFullUrl ?? '',
                                              width: 75,
                                              height: 75,
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
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeSmall),
                                  // Module name
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      module.moduleName ?? '',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                        style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: isDisabled
                                              ? Colors.white
                                                  .withValues(alpha: 0.6)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

