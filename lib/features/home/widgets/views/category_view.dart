// ignore_for_file: unnecessary_null_comparison, unused_local_variable, non_constant_identifier_names, prefer_is_empty

import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/circular_ring_avatar.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:get/get.dart';
import '../../../category/domain/models/category_model.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

// #region agent log helper
void _writeDebugLog(String location, String message, Map<String, dynamic> data, String hypothesisId) {
  if (!kDebugMode || !AppConstants.enableVerboseLogs) {
    return;
  }
  unawaited(_writeDebugLogAsync(location, message, data, hypothesisId));
}

Future<void> _writeDebugLogAsync(String location, String message, Map<String, dynamic> data, String hypothesisId) async {
  if (!kDebugMode || !AppConstants.enableVerboseLogs) {
    return;
  }
  try {
    const logPath = r'c:\Users\pc\Desktop\clone\app-test\.cursor\debug.log';
    final logFile = File(logPath);
    final logDir = logFile.parent;
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    final logEntry = {
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': hypothesisId,
    };
    await logFile.writeAsString('${jsonEncode(logEntry)}\n', mode: FileMode.append);
  } catch (e) {
    // Silently fail - don't break the app
  }
}
// #endregion

class CategoryView extends StatelessWidget {
  /// Compact home grid so four tiles fit without scrolling past clipped labels.
  static const double _homeCategoryImageSize = 98;
  static const double _homeCategoryLabelMaxHeight = 44;
  /// Width/height for each grid child. [CircularRingAvatar] is taller than
  /// [_homeCategoryImageSize] (padding + border); 1.12 made cells too short
  /// on common phone widths (~8px bottom overflow). ~0.92 fits the true content height.
  static const double _homeCategoryGridAspectRatio = 0.92;

  final ScrollController? scrollController;

  const CategoryView({super.key, this.scrollController});

  /// Toggle off to revert **market/ecommerce only**; food / restaurants / cafes stay circular.
  static const bool _tryEcommerceCircularCategories = true;

  /// Circular category avatars on home: food modules + optional ecommerce (module 3 / ماركيت).
  static bool _useCircularCategoryAvatar(SplashController splash) {
    final ModuleModel? module = splash.module;
    if (module == null) {
      return false;
    }
    final String type = module.moduleType.toString().toLowerCase().trim();
    if (type == AppConstants.food ||
        type == 'restaurant' ||
        type == 'cafe') {
      return true;
    }
    if (module.id == 9) {
      return true;
    }
    if (_tryEcommerceCircularCategories &&
        (type == AppConstants.ecommerce || module.id == 3)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        final bool isPharmacy = splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.pharmacy;
        final bool isFood = splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.food;
        
        // 🔧 CRITICAL FIX: Only initialize CategoryController when in a specific module (Food/Pharmacy)
        // Do NOT initialize on MultiModuleHomeScreen (where module is null)
        // This prevents unnecessary category loading (saves 45 image loads)
        if (splashController.module == null) {
          // On multi-module screen - don't initialize CategoryController
          return const SizedBox.shrink();
        }
        
        // ⚡ SINGLETON FIX: CategoryController is registered as permanent singleton in get_di.dart
        // Do NOT create new instances here - this causes race conditions and stale state
        // If controller is not registered, it means dependencies aren't ready yet
        if (!Get.isRegistered<CategoryController>()) {
          // Dependencies not ready – keep shimmer until they are.
          return const CategoryShimmer();
        }
        
        return GetBuilder<CategoryController>(
          builder: (categoryController) {
            // #region agent log
            _writeDebugLog('category_view.dart:45', 'GetBuilder<CategoryController> rebuild', {
              'categoryListIsNull': categoryController.categoryList == null,
              'categoryListLength': categoryController.categoryList?.length ?? 'null',
              'initialBatchIsNull': categoryController.initialCategoryBatch == null,
              'initialBatchLength': categoryController.initialCategoryBatch?.length ?? 'null',
              'visibleCount': categoryController.visibleCount,
            }, 'B');
            // #endregion
            
            // ⚡ PERFORMANCE: Use initial batch if available for faster rendering
            // Show first 4 categories immediately, then full list when ready
            List<CategoryModel>? displayList;
            
            if (categoryController.categoryList != null && 
                categoryController.categoryList!.isNotEmpty) {
              // Full list is ready - use it (includes initial batch + remaining)
              // 🎯 PERFORMANCE: Use controller method - no calculations in build()
              displayList = categoryController.getFilteredCategoryList(categoryController.categoryList);
            } else if (categoryController.initialCategoryBatch != null && 
                       categoryController.initialCategoryBatch!.isNotEmpty) {
              // Show initial batch immediately (first 4 categories) while rest load
              // 🎯 PERFORMANCE: Use controller method - no calculations in build()
              displayList = categoryController.getFilteredCategoryList(categoryController.initialCategoryBatch);
            }
            
            // #region agent log
            _writeDebugLog('category_view.dart:63', 'CategoryView visibility check', {
              'displayListIsNull': displayList == null,
              'displayListLength': displayList?.length ?? 'null',
              'categoryListIsNull': categoryController.categoryList == null,
              'willShowShimmer': displayList == null || displayList.isEmpty ? (categoryController.categoryList == null) : false,
              'willHideSection': displayList == null || displayList.isEmpty ? (categoryController.categoryList != null) : false,
              'willShowContent': displayList != null && displayList.isNotEmpty,
            }, 'B');
            // #endregion
            
            // ⚡ Hide section if no data (don't show shimmer after API call completes)
            // Shimmer only shows while loading, not when data is empty
            if (displayList == null || displayList.isEmpty) {
              // Check if we're still loading or if data is actually empty
              // If categoryList is null, we're still loading - show shimmer
              // If categoryList is empty list, data loaded but empty - hide section
              if (categoryController.categoryList == null) {
                return const CategoryShimmer();
              } else {
                // Data loaded but empty - hide section
                return const SizedBox.shrink();
              }
            }
            return build_ListView(context, categoryController, displayList, scrollController);
          },
        );
      },
    );
  }

  // 🎯 PERFORMANCE: Removed - moved to CategoryController.getFilteredCategoryList()
  // This prevents calculations in build() - controller handles filtering

  Widget build_ListView(BuildContext context, CategoryController categoryController, List<CategoryModel> categoryList, [ScrollController? scrollController]) {
    if (categoryList.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // ✅ Show only first 4 categories in a 2x2 grid
    final visibleCategories = categoryList.take(4).toList();
    final SplashController splashForModule = Get.find<SplashController>();
    final bool useCircularCategory =
        CategoryView._useCircularCategoryAvatar(splashForModule);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: Dimensions.paddingSizeSmall),
        if (visibleCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'sections'.tr,
                    style: robotoBold.copyWith(
                      fontSize: ResponsiveHelper.isDesktop(context)
                          ? Dimensions.fontSizeLarge
                          : Dimensions.fontSizeLarge,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                const _CategorySeeAllButton(),
              ],
            ),
          ),
        RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: Dimensions.paddingSizeSmall,
                crossAxisSpacing: Dimensions.paddingSizeSmall,
                childAspectRatio: CategoryView._homeCategoryGridAspectRatio,
              ),
              itemCount: visibleCategories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Get.toNamed(
                      RouteHelper.getCategoryItemRoute(
                        visibleCategories[index].id,
                        visibleCategories[index].name!,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Center(
                        child: useCircularCategory
                            ? CircularRingAvatar(
                                imageUrl:
                                    visibleCategories[index].imageFullUrl ??
                                        '',
                                diameter:
                                    CategoryView._homeCategoryImageSize,
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(Dimensions.radiusSmall),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Builder(
                                  builder: (BuildContext context) {
                                    final String imageUrl =
                                        visibleCategories[index]
                                                .imageFullUrl ??
                                            '';
                                    return CustomImage(
                                      image: imageUrl,
                                      height: CategoryView
                                          ._homeCategoryImageSize,
                                      width: CategoryView
                                          ._homeCategoryImageSize,
                                      placeholder: Images.placeholder,
                                    );
                                  },
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: CategoryView._homeCategoryLabelMaxHeight,
                        child: Text(
                          visibleCategories[index].name ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeMedim,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill-style "see all" control for the home categories header.
class _CategorySeeAllButton extends StatelessWidget {
  const _CategorySeeAllButton();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.primaryColor;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(RouteHelper.getCategoryRoute()),
        borderRadius: BorderRadius.circular(22),
        splashColor: primary.withValues(alpha: 0.12),
        highlightColor: primary.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                Color.lerp(primary, Colors.black, 0.12) ?? primary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.32),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'see_all'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: theme.cardColor,
                    letterSpacing: 0.15,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                  size: 17,
                  color: theme.cardColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PharmacyCategoryView extends StatelessWidget {
  final CategoryController categoryController;
  const PharmacyCategoryView({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 160,
        child: categoryController.categoryList != null
            ? RepaintBoundary(
                child: ListView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
                  itemCount: categoryController.categoryList!.length > 10 ? 10 : categoryController.categoryList!.length,
                  itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeDefault),
                    child: InkWell(
                      onTap: () {
                        if (index == 9 && categoryController.categoryList!.length > 10) {
                          Get.toNamed(RouteHelper.getCategoryRoute());
                        } else {
                          Get.toNamed(RouteHelper.getCategoryItemRoute(
                            categoryController.categoryList![index].id,
                            categoryController.categoryList![index].name!,
                          ));
                        }
                      },
                      borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(100), topRight: Radius.circular(100)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              Theme.of(context).cardColor.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: Column(children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(100), topRight: Radius.circular(100)),
                                child: CustomImage(
                                  image: '${categoryController.categoryList![index].imageFullUrl}',
                                  height: 60,
                                  width: double.infinity,
                                ),
                              ),
                              (index == 9 && categoryController.categoryList!.length > 10)
                                  ? Positioned(
                                      right: 0,
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(topLeft: Radius.circular(100), topRight: Radius.circular(100)),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                                Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                                Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '+${categoryController.categoryList!.length - 10}',
                                              style: robotoMedium.copyWith(
                                                  fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          )),
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Expanded(
                              child: Text(
                            (index == 9 && categoryController.categoryList!.length > 10)
                                ? 'see_all'.tr
                                : categoryController.categoryList![index].name!,
                            style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: (index == 9 && categoryController.categoryList!.length > 10)
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).textTheme.bodyMedium!.color),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          )),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            )
            : PharmacyCategoryShimmer(categoryController: categoryController),
      ),
    ]);
  }
}

class FoodCategoryView extends StatelessWidget {
  final CategoryController categoryController;
  const FoodCategoryView({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 160,
          child: categoryController.categoryList != null
              ? RepaintBoundary(
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
                    itemCount: categoryController.categoryList!.length > 10 ? 10 : categoryController.categoryList!.length,
                    itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeDefault,
                          right: Dimensions.paddingSizeDefault,
                          top: Dimensions.paddingSizeDefault),
                      child: InkWell(
                        onTap: () {
                          if (index == 9 && categoryController.categoryList!.length > 10) {
                            Get.toNamed(RouteHelper.getCategoryRoute());
                          } else {
                            Get.toNamed(RouteHelper.getCategoryItemRoute(
                              categoryController.categoryList![index].id,
                              categoryController.categoryList![index].name!,
                            ));
                          }
                        },
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                        child: SizedBox(
                          width: 60,
                          child: Column(children: [
                            Stack(
                              children: [
                                // ⚡ TASK 3: Replace ClipRRect with BoxDecoration for 120Hz scrolling fluidity
                                Container(
                                  height: 60,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(100)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: CustomImage(
                                    image: '${categoryController.categoryList![index].imageFullUrl}',
                                    height: 60,
                                    width: double.infinity,
                                  ),
                                ),
                                (index == 9 && categoryController.categoryList!.length > 10)
                                    ? Positioned(
                                        right: 0,
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.all(Radius.circular(100)),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                                  Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                                  Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '+${categoryController.categoryList!.length - 10}',
                                                style: robotoMedium.copyWith(
                                                    fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            )),
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Expanded(
                                child: Text(
                              (index == 9 && categoryController.categoryList!.length > 10)
                                  ? 'see_all'.tr
                                  : categoryController.categoryList![index].name ?? '',
                              style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: (index == 9 && categoryController.categoryList!.length > 10)
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).textTheme.bodyMedium!.color),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            )),
                          ]),
                        ),
                      ),
                    );
                  },
                  ),
                )
              : FoodCategoryShimmer(categoryController: categoryController),
        ),
      ]),
    ]);
  }
}

class CategoryItemWidget extends StatelessWidget {
  final CategoryModel category;
  final GestureTapCallback? onTap;
  const CategoryItemWidget({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(
            bottom: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
          child: SizedBox(
            width: 100,
            child: Column(children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
                    child: CustomImage(
                      image: category.imageFullUrl ?? '',
                      height: 50,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Expanded(
                  child: Text(
                category.name ?? '',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium!.color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              )),
            ]),
          ),
        ));
  }
}

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.builder(
        itemCount: 8,
        padding: const EdgeInsets.only(
          left: Dimensions.paddingSizeSmall,
          top: Dimensions.paddingSizeSmall,
        ),
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 1,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              child: SizedBox(
                width: 104,
                child: Column(
                  children: [
                    Container(
                      height: CategoryView._homeCategoryImageSize,
                      width: CategoryView._homeCategoryImageSize,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : Dimensions.paddingSizeExtraSmall,
                        right: Dimensions.paddingSizeExtraSmall,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Padding(
                      padding: EdgeInsets.only(
                        right: index == 0 ? Dimensions.paddingSizeExtraSmall : 0,
                      ),
                      child: Container(
                        height: 10,
                        width: 60,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FoodCategoryShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const FoodCategoryShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(
              bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
          child: SizedBox(
            width: 60,
            child: Column(children: [
              ClipOval(
                child: Shimmer(
                  child: Container(
                      height: 60,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).shadowColor,
                      )),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Expanded(
                child: Shimmer(
                  child: Container(
                    height: 10,
                    width: 50,
                    color: Theme.of(context).shadowColor,
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class PharmacyCategoryShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const PharmacyCategoryShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(
              bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              width: 70,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(100), topRight: Radius.circular(100)),
              ),
              child: Column(children: [
                Container(
                    height: 60,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(100), topRight: Radius.circular(100)),
                      color: Colors.grey[300],
                    )),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Container(
                    height: 10,
                    width: 50,
                    color: Colors.grey[300],
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
