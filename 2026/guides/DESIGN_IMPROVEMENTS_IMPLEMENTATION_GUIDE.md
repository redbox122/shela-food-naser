# 🎨 DESIGN IMPROVEMENTS - IMPLEMENTATION GUIDE

## Quick Wins (Implement First)

### 1. Add Shimmer Loading to Store Cards

**File:** `lib/common/widgets/card_design/store_card_with_distance.dart`

**Add shimmer package:**
```yaml
# pubspec.yaml
dependencies:
  shimmer: ^3.0.0
```

**Implementation:**
```dart
import 'package:shimmer/shimmer.dart';

class StoreCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.white,
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 200, color: Colors.white),
                  SizedBox(height: 8),
                  Container(height: 14, width: 150, color: Colors.white),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(height: 12, width: 60, color: Colors.white),
                      SizedBox(width: 8),
                      Container(height: 12, width: 80, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 2. Add Staggered Animations to Module Grid

**File:** `lib/features/home/widgets/modules_view_widget.dart`

**Update the GridView.builder:**
```dart
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Replace the itemBuilder with:
itemBuilder: (context, index) {
  final module = moduleList[index];
  return AnimationConfiguration.staggeredGrid(
    position: index,
    duration: const Duration(milliseconds: 375),
    columnCount: 4,
    child: ScaleAnimation(
      scale: 0.5,
      child: FadeInAnimation(
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: _AnimatedModuleCard(
            module: module,
            onTap: () => _onModuleTap(context, module, index),
          ),
        ),
      ),
    ),
  );
}

// Add new widget:
class _AnimatedModuleCard extends StatefulWidget {
  final ModuleModel module;
  final VoidCallback onTap;
  
  const _AnimatedModuleCard({
    required this.module,
    required this.onTap,
  });
  
  @override
  State<_AnimatedModuleCard> createState() => _AnimatedModuleCardState();
}

class _AnimatedModuleCardState extends State<_AnimatedModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }
  
  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'module_icon_${widget.module.id}',
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getModuleColor(widget.module.id)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                  ),
                  child: CustomImage(
                    image: widget.module.iconFullUrl ?? '',
                    height: 60,
                    width: 60,
                  ),
                ),
              ),
              SizedBox(height: 2),
              Text(
                widget.module.moduleName ?? '',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getModuleColor(int? moduleId) {
    switch (moduleId) {
      case 1: // Food
        return Color(0xFFFF6B35);
      case 2: // Pharmacy
        return Color(0xFF4A90E2);
      case 3: // Grocery
        return Color(0xFF2ECC71);
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
```

---

### 3. Add BlurHash Placeholders for Images

**File:** `lib/common/widgets/custom_image.dart` (or create new widget)

**Add package:**
```yaml
dependencies:
  blurhash_dart: ^1.0.0
```

**Create new widget:**
```dart
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/material.dart';

class BlurHashImage extends StatelessWidget {
  final String hash;
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  
  const BlurHashImage({
    Key? key,
    required this.hash,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // BlurHash placeholder
        if (hash.isNotEmpty)
          BlurHash(
            hash: hash,
            image: DecodeImage(
              imageUrl: imageUrl,
              width: width?.toInt(),
              height: height?.toInt(),
            ),
          ),
        
        // Actual image with fade-in
        Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(Icons.error_outline, color: Colors.grey[400]),
            );
          },
        ),
      ],
    );
  }
}
```

**Update StoreCardWithDistance to use BlurHash:**
```dart
// In store_card_with_distance.dart, replace CustomImage with:
BlurHashImage(
  hash: store.blurHash ?? 'L6PZfSi_.AyE_3t7t7R**0o#DgR4', // Default hash
  imageUrl: store.coverPhotoFullUrl ?? '',
  width: double.infinity,
  height: 140,
  fit: BoxFit.cover,
)
```

---

### 4. Improve Store Screen Loading

**File:** `lib/features/store/screens/store_screen.dart`

**Add optimistic UI:**
```dart
@override
Widget build(BuildContext context) {
  return GetBuilder<StoreController>(
    builder: (storeController) {
      // Show cached store immediately if available
      final displayStore = storeController.store ?? widget.store;
      
      // Show skeleton only if no data at all
      if (displayStore == null && storeController.isLoading) {
        return _StoreScreenSkeleton();
      }
      
      return CustomScrollView(
        slivers: [
          // Hero header - show immediately with cached data
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image with blur placeholder
                  if (displayStore?.coverPhotoFullUrl != null)
                    BlurHashImage(
                      hash: displayStore!.blurHash ?? '',
                      imageUrl: displayStore.coverPhotoFullUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: Colors.grey[200]),
                  
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                displayStore?.name ?? '',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          
          // Store info - show immediately
          SliverToBoxAdapter(
            child: _StoreInfoSection(store: displayStore),
          ),
          
          // Categories - show skeleton if loading
          SliverToBoxAdapter(
            child: GetBuilder<CategoryController>(
              builder: (categoryController) {
                if (categoryController.categoryList == null) {
                  return _CategorySkeleton();
                }
                return _CategorySection(
                  categories: categoryController.categoryList!,
                );
              },
            ),
          ),
          
          // Items - progressive loading
          GetBuilder<ItemController>(
            builder: (itemController) {
              if (itemController.itemList.isEmpty && 
                  storeController.isLoadingItems) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ItemSkeleton(),
                    childCount: 6,
                  ),
                );
              }
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _AnimatedItemCard(
                      item: itemController.itemList[index],
                      index: index,
                    );
                  },
                  childCount: itemController.itemList.length,
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

// Add skeleton widgets
Widget _StoreScreenSkeleton() {
  return CustomScrollView(
    slivers: [
      SliverAppBar(
        expandedHeight: 300,
        pinned: true,
        flexibleSpace: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.white),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 24,
                  width: 200,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _CategorySkeleton() {
  return Container(
    height: 100,
    margin: EdgeInsets.symmetric(vertical: 16),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 80,
          margin: EdgeInsets.only(right: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 60,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _ItemSkeleton() {
  return Container(
    margin: EdgeInsets.all(8),
    padding: EdgeInsets.all(12),
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            color: Colors.white,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: double.infinity, color: Colors.white),
                SizedBox(height: 8),
                Container(height: 14, width: 150, color: Colors.white),
                SizedBox(height: 8),
                Container(height: 14, width: 100, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Add animated item card
class _AnimatedItemCard extends StatelessWidget {
  final Item item;
  final int index;
  
  const _AnimatedItemCard({
    required this.item,
    required this.index,
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: ItemWidget(item: item),
    );
  }
}
```

---

### 5. Add Module Switching Animation

**File:** `lib/features/splash/controllers/splash_controller.dart`

**Update switchModule method:**
```dart
Future<void> switchModule(
  BuildContext context,
  int index,
  bool fromMultiModule,
) async {
  if (moduleList == null || index >= moduleList!.length) return;
  
  final newModule = moduleList![index];
  final oldModuleId = module?.id;
  
  // Set loading state
  isModuleSwitching = true;
  update(['module']);
  
  // Pre-load data for new module in background
  _preloadModuleData(newModule.id);
  
  // Update module
  setModule(newModule);
  
  // Navigate with animation
  if (fromMultiModule) {
    // Smooth transition from multi-module screen
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionDuration: Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Shared element transition for module icon
          return Stack(
            children: [
              // Fade out old screen
              FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Interval(0.0, 0.5, curve: Curves.easeOut),
                  ),
                ),
                child: MultiModuleHomeScreen(),
              ),
              
              // Slide in new screen
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                  ),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Interval(0.3, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  } else {
    // Update current screen
    Get.offNamedUntil(
      RouteHelper.getInitialRoute(),
      (route) => false,
    );
  }
  
  isModuleSwitching = false;
  update(['module']);
}

void _preloadModuleData(int? moduleId) {
  // Pre-load data in background
  Future.microtask(() async {
    if (Get.isRegistered<HomeUnifiedController>()) {
      final controller = Get.find<HomeUnifiedController>();
      await controller.loadHomeData(
        moduleId: moduleId,
        forceRefresh: false,
        showLoading: false,
      );
    }
  });
}
```

---

### 6. Add Progressive Image Loading

**File:** `lib/common/widgets/custom_image.dart`

**Update to support progressive loading:**
```dart
class CustomImage extends StatefulWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit fit;
  final String? placeholder;
  final String? blurHash;
  
  const CustomImage({
    Key? key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.blurHash,
  }) : super(key: key);
  
  @override
  State<CustomImage> createState() => _CustomImageState();
}

class _CustomImageState extends State<CustomImage> {
  bool _imageLoaded = false;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // BlurHash placeholder
        if (widget.blurHash != null && !_imageLoaded)
          BlurHashImage(
            hash: widget.blurHash!,
            imageUrl: widget.image,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          ),
        
        // Actual image
        Image.network(
          widget.image,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              if (mounted) {
                setState(() => _imageLoaded = true);
              }
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _imageLoaded = true);
                }
              });
              return child;
            }
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.error_outline,
                color: Colors.grey[400],
                size: widget.height != null ? widget.height! * 0.3 : 24,
              ),
            );
          },
        ),
      ],
    );
  }
}
```

---

## Package Dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies...
  
  # New dependencies for design improvements
  shimmer: ^3.0.0
  blurhash_dart: ^1.0.0
  flutter_staggered_animations: ^1.1.1
```

---

## Testing Checklist

- [ ] Module grid has staggered animations
- [ ] Store cards show shimmer while loading
- [ ] Images use BlurHash placeholders
- [ ] Store screen shows cached data immediately
- [ ] Module switching has smooth transitions
- [ ] List items animate in with stagger
- [ ] No blank screens during loading
- [ ] All animations are smooth (60fps)

---

## Performance Targets

- **Time to first content:** < 200ms
- **Module switch time:** < 300ms
- **Image load time:** < 500ms (with placeholder)
- **Animation frame rate:** 60fps
- **Memory usage:** < 150MB

---

## Next Steps

1. Implement shimmer loading (1 day)
2. Add BlurHash placeholders (1 day)
3. Implement staggered animations (1 day)
4. Add module switching animation (1 day)
5. Optimize store screen loading (2 days)
6. Test and polish (2 days)

**Total: ~1 week for all improvements**
