
// ignore_for_file: file_names

// ============================================================================
// 1. ADD TO pubspec.yaml
// ============================================================================
/*
dependencies:
  shimmer: ^3.0.0
  flutter_staggered_animations: ^1.1.1
*/

// ============================================================================
// 2. CREATE: lib/core/theme/module_themes.dart
// ============================================================================
import 'package:flutter/material.dart';
// ============================================================================
// 3. CREATE: lib/common/widgets/animated_section.dart
// ============================================================================
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// ============================================================================
// 4. CREATE: lib/common/widgets/premium_skeleton.dart
// ============================================================================
import 'package:shimmer/shimmer.dart';

class ModuleTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Gradient heroGradient;
  
  const ModuleTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.heroGradient,
  });
  
  static const ModuleTheme food = ModuleTheme(
    primary: Color(0xFFFF6B35),
    secondary: Color(0xFFFF8C42),
    accent: Color(0xFFFFB347),
    background: Color(0xFFFFF8F5),
    heroGradient: LinearGradient(
      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
    ),
  );
  
  static const ModuleTheme grocery = ModuleTheme(
    primary: Color(0xFF2ECC71),
    secondary: Color(0xFF48D68C),
    accent: Color(0xFF6EE5A7),
    background: Color(0xFFF0FDF4),
    heroGradient: LinearGradient(
      colors: [Color(0xFF2ECC71), Color(0xFF48D68C)],
    ),
  );
  
  static const ModuleTheme pharmacy = ModuleTheme(
    primary: Color(0xFF4A90E2),
    secondary: Color(0xFF5BA3F5),
    accent: Color(0xFF6BB6FF),
    background: Color(0xFFF0F7FF),
    heroGradient: LinearGradient(
      colors: [Color(0xFF4A90E2), Color(0xFF5BA3F5)],
    ),
  );
  
  static const ModuleTheme ecommerce = ModuleTheme(
    primary: Color(0xFF9B59B6),
    secondary: Color(0xFFAF7AC5),
    accent: Color(0xFFC39BD3),
    background: Color(0xFFF8F4FB),
    heroGradient: LinearGradient(
      colors: [Color(0xFF9B59B6), Color(0xFFAF7AC5)],
    ),
  );
  
  static ModuleTheme getTheme(String? moduleType) {
    switch (moduleType) {
      case 'food': return food;
      case 'grocery': return grocery;
      case 'pharmacy': return pharmacy;
      case 'ecommerce': return ecommerce;
      default: return food;
    }
  }
}



class AnimatedSection extends StatelessWidget {
  final Widget child;
  final int index;
  
  const AnimatedSection({
    super.key,
    required this.child,
    required this.index,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }
}



class PremiumSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const PremiumSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. UPDATE: Food Home Screen Example
// ============================================================================
/*
// In food_home_screen.dart, replace the build method with:

@override
Widget build(BuildContext context) {
  final splashController = Get.find<SplashController>();
  final moduleType = splashController.module?.moduleType.toString();
  final theme = ModuleTheme.getTheme(moduleType);
  
  return GetBuilder<HomeUnifiedController>(
    builder: (unifiedController) {
      if (!unifiedController.hasCachedData && unifiedController.isLoading) {
        return Container(
          color: theme.background,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Container(
        color: theme.background,
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            // Hero Banner
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: theme.heroGradient,
                  ),
                  child: GetBuilder<BannerController>(
                    builder: (controller) {
                      if (controller.featuredBannerList == null || 
                          controller.featuredBannerList!.isEmpty) {
                        return Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 64,
                            color: Colors.white,
                          ),
                        );
                      }
                      return PageView.builder(
                        itemCount: controller.featuredBannerList!.length,
                        itemBuilder: (context, index) {
                          final banner = controller.featuredBannerList![index];
                          return Image.network(
                            banner.imageFullUrl ?? '',
                            fit: BoxFit.cover,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              backgroundColor: theme.primary,
            ),
            
            // Content Sections
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Categories
                  AnimatedSection(
                    index: 0,
                    child: GetBuilder<CategoryController>(
                      builder: (controller) {
                        if (controller.categoryList == null) {
                          return Container(
                            height: 120,
                            margin: EdgeInsets.symmetric(vertical: 16),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: 6,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 80,
                                  margin: EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      PremiumSkeleton(
                                        width: 60,
                                        height: 60,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      SizedBox(height: 8),
                                      PremiumSkeleton(
                                        width: 60,
                                        height: 12,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }
                        return CategoryView();
                      },
                    ),
                  ),
                  
                  // Top Restaurants
                  AnimatedSection(
                    index: 1,
                    child: GetBuilder<StoreController>(
                      builder: (controller) {
                        if (controller.popularStoreList == null) {
                          return Container(
                            height: 200,
                            margin: EdgeInsets.symmetric(vertical: 16),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 260,
                                  margin: EdgeInsets.only(right: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      PremiumSkeleton(
                                        width: double.infinity,
                                        height: 140,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      SizedBox(height: 8),
                                      PremiumSkeleton(width: 200, height: 16),
                                      SizedBox(height: 4),
                                      PremiumSkeleton(width: 150, height: 14),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }
                        return TopRestaurantsViewWidget();
                      },
                    ),
                  ),
                  
                  // All Restaurants
                  AnimatedSection(
                    index: 2,
                    child: AllRestaurantsView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
*/

// ============================================================================
// 6. QUICK FIX: Replace CircularProgressIndicator with Skeleton
// ============================================================================
/*
// Find all instances of:
return Center(child: CircularProgressIndicator());

// Replace with:
return Container(
  color: theme.background,
  child: CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Column(
          children: [
            // Category skeleton
            Container(
              height: 120,
              margin: EdgeInsets.all(16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    margin: EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        PremiumSkeleton(
                          width: 60,
                          height: 60,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        SizedBox(height: 8),
                        PremiumSkeleton(width: 60, height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Store skeleton
            Container(
              height: 200,
              margin: EdgeInsets.all(16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    width: 260,
                    margin: EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PremiumSkeleton(
                          width: double.infinity,
                          height: 140,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        SizedBox(height: 8),
                        PremiumSkeleton(width: 200, height: 16),
                        SizedBox(height: 4),
                        PremiumSkeleton(width: 150, height: 14),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
*/

// ============================================================================
// 7. ADD STAGGERED ANIMATIONS TO LISTS
// ============================================================================
/*
// Wrap any ListView.builder with AnimationLimiter:

AnimationLimiter(
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return AnimationConfiguration.staggeredList(
        position: index,
        duration: Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: YourItemWidget(item: items[index]),
          ),
        ),
      );
    },
  ),
)
*/

// ============================================================================
// 8. ADD MODULE-SPECIFIC SECTION HEADERS
// ============================================================================
/*
class ModuleSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onSeeAll;
  
  const ModuleSectionHeader({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    this.onSeeAll,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text('See All'),
            ),
        ],
      ),
    );
  }
}

// Usage:
ModuleSectionHeader(
  title: 'Trending Now',
  icon: Icons.local_fire_department,
  color: theme.primary,
  onSeeAll: () {},
)
*/

// ============================================================================
// 9. IMPLEMENTATION ORDER
// ============================================================================
/*
1. Add packages to pubspec.yaml (5 min)
2. Create ModuleTheme class (15 min)
3. Create AnimatedSection widget (10 min)
4. Create PremiumSkeleton widget (10 min)
5. Update one module screen (Food) as test (1 hour)
6. Apply to all other modules (2 hours)
7. Add staggered animations (1 hour)
8. Polish and test (1 hour)

Total: ~5 hours for complete transformation
*/
