# 6amMart Visual Architecture Brief
**Product Visionary & Lead Engineer Analysis**  
*Mode: Jobs/Ive Aesthetic Perfection*

---

## Phase 1: Foundation & Dependencies

### Core Technology Stack

**State Management**: GetX v4.6.6  
**HTTP Client**: Dio v5.9.0  
**Maps**: google_maps_flutter v2.9.0  
**Image Caching**: cached_network_image v3.4.1  
**Font Family**: Roboto (Regular 400, Medium 500, Bold 700, Black 900)

**Configuration File**: `lib/util/app_constants.dart`  
**Routing System**: `lib/helper/route_helper.dart`  
**Theme System**: 
- Light Theme: `lib/theme/light_theme.dart`
- Dark Theme: `lib/theme/dark_theme.dart`

---

## Phase 2: State Pattern Analysis

### Data Flow Architecture (GetX Pattern)

```
┌─────────────────┐
│   UI Widget     │ ← GetBuilder / Obx (Reactive UI)
│  (View Layer)   │
└────────┬────────┘
         │ .obs variables
         │ update() / refresh()
         ↓
┌─────────────────┐
│ GetX Controller │ ← Business Logic, State Management
│  (Presentation) │    .obs reactive variables
└────────┬────────┘    update() triggers rebuilds
         │
         │ Repository Interface (Abstract)
         ↓
┌─────────────────┐
│   Repository    │ ← Data Aggregation, Caching Strategy
│  (Data Layer)   │    Maps Models ↔ Entities
└────────┬────────┘
         │
         │ API Client (Dio)
         ↓
┌─────────────────┐
│   ApiClient     │ ← HTTP Requests, Headers Management
│  (Network)      │    updateHeader(zoneId, moduleId, lat, lng)
└─────────────────┘
```

### Critical State Flow Examples

**1. Banner Data Flow:**
```
BannerController.getFeaturedBanner()
  → BannerRepository.getBannerList()
    → ApiClient.getData(AppConstants.bannerUri)
      → BannerModel.fromJson()
        → bannerController.bannerImageList = data (RxList)
          → UI rebuilds via GetBuilder/Obx
```

**2. Module Switching Flow:**
```
SplashController.switchModule(index)
  → setModule(ModuleModel)
    → ApiClient.updateHeader(moduleId: newModuleId)
      → Clear all module-specific controllers
        → HomeScreen.loadData()
          → Load fresh data for new module
            → UI rebuilds with new module layout
```

**3. Home Data Loading (Unified Endpoint):**
```
HomeUnifiedController.loadHomeData(moduleId)
  → ApiClient.post(AppConstants.homeUnifiedUri)
    → HomeUnifiedModel.fromJson()
      → Inject into: BannerController, CategoryController, StoreController, etc.
        → All controllers update simultaneously
          → UI renders with complete data
```

### Key GetX Patterns

- **Controllers**: All extend `GetxController implements GetxService`
- **Reactive Variables**: `.obs` for automatic UI updates
- **Manual Updates**: `update()` or `update(['specificId'])` for targeted rebuilds
- **Dependency Injection**: `Get.find<ControllerName>()` for controller access
- **Route Guards**: `RouteHelper.getRoute()` checks location/auth before navigation

---

## Phase 3: Component Hierarchy

### Base Widgets (Atomic Design System)

**Location**: `lib/common/widgets/`

#### Primary UI Components

1. **CustomButton** (`custom_button.dart`)
   - Primary action button
   - Supports: transparent mode, loading state, icons, custom colors
   - **Usage**: All primary actions, form submissions
   - **Never use**: Standard Flutter `ElevatedButton` or `TextButton`

2. **CustomTextField** (`custom_text_field.dart`)
   - Text input with validation
   - Supports: phone input, country code picker, icons, borders
   - **Usage**: All text inputs, search fields, forms
   - **Never use**: Standard Flutter `TextField`

3. **CustomText** (`custom_text.dart`)
   - Typography wrapper
   - **Usage**: All text display

4. **TitleWidget** (`title_widget.dart`)
   - Section headers with "See All" actions
   - **Usage**: Home screen sections, category headers

5. **QuantityButton** (`quantity_button.dart`)
   - Increment/decrement controls
   - **Usage**: Cart items, product quantity selection

6. **RatingBar** (`rating_bar.dart`)
   - Star rating display/input
   - **Usage**: Reviews, store ratings

7. **CustomImage** (`custom_image.dart`)
   - Image with placeholder, error handling
   - **Usage**: All network images
   - **Note**: Uses `cached_network_image` under the hood

#### Card Components

8. **StoreCard** (`card_design/store_card.dart`)
   - Store list item
   - **Usage**: Store listings, featured stores

9. **ItemCard** (`card_design/item_card.dart`)
   - Product/item card
   - **Usage**: Product listings, featured items

10. **StoreCardWithDistance** (`card_design/store_card_with_distance.dart`)
    - Store card with distance display
    - **Usage**: Nearby stores, location-based lists

#### Navigation Components

11. **CustomAppBar** (`custom_app_bar.dart`)
    - Standardized app bar
    - **Usage**: All screens (unless custom required)

12. **MenuDrawer** (`menu_drawer.dart`)
    - Side navigation drawer
    - **Usage**: Main menu

#### Specialized Components

13. **DiscountTag** (`discount_tag.dart`)
    - Discount badge overlay
    - **Usage**: Product/store discount display

14. **CartCountView** (`cart_count_view.dart`)
    - Cart icon with badge
    - **Usage**: Navigation bar, app bar

15. **FavouriteWidget** (`custom_favourite_widget.dart`)
    - Heart icon for favorites
    - **Usage**: Product/store favorite toggle

16. **NoDataScreen** (`no_data_screen.dart`)
    - Empty state display
    - **Usage**: Empty lists, no results

17. **CustomLoader** (`custom_loader.dart`)
    - Loading indicator
    - **Usage**: Loading states

18. **CustomSnackbar** (`custom_snackbar.dart`)
    - Toast notifications
    - **Usage**: Success/error messages

### Widget Usage Rules

⚠️ **CRITICAL**: Never use standard Flutter widgets if a custom equivalent exists:
- ❌ `ElevatedButton` → ✅ `CustomButton`
- ❌ `TextField` → ✅ `CustomTextField`
- ❌ `Text` → ✅ `CustomText` (when styling needed)
- ❌ `CachedNetworkImage` → ✅ `CustomImage`
- ❌ `AppBar` → ✅ `CustomAppBar` (unless custom design required)

---

## Phase 4: Visual Language (Theme System)

### Color Palette

**Primary Color**: `Color(0xFF31A342)` (Green)  
**Secondary Color**: `Color(0xFFFA9D2B)` (Orange/Yellow)  
**Error Color**: `Color(0xFFE84D4F)` (Light), `Color(0xFFdd3135)` (Dark)

**Location**: `lib/util/app_colors.dart` + Theme Extensions

#### Light Theme Colors
- **Primary**: `Color(0xFF31A342)`
- **Card Background**: `Colors.white`
- **Surface**: `Color(0xFFFCFCFC)`
- **Disabled**: `Color(0xFFBABFC4)`
- **Hint**: `Color(0xFF9F9F9F)`
- **Custom Extension**:
  - `yellow_Color`: `Color(0xFFFA9D2B)`
  - `white_Color`: `Colors.white`

#### Dark Theme Colors
- **Primary**: `Color(0xFF31A342)` (same)
- **Card Background**: `Color(0xFF30313C)`
- **Surface**: `Color(0xFF191A26)`
- **Disabled**: `Color(0xffa2a7ad)`
- **Hint**: `Color(0xFFbebebe)`

### Typography

**Font Family**: Roboto (via `AppConstants.fontFamily`)  
**Responsive Scaling**: `lib/util/dimensions.dart`
- Uses `sp(context, fontSize)` for responsive text sizing
- Scales based on screen width (375px base for mobile, 1420px for web)

**Font Weights Available**:
- Regular: 400
- Medium: 500
- Bold: 700
- Black: 900

**Dimension Constants**: `lib/util/dimensions.dart`
- Padding: `paddingSizeExtraSmall` (5) → `paddingSizeExtraOverLarge` (35)
- Radius: `radiusSmall` (5) → `radiusExtraLarge` (20)
- Font Sizes: `fontSizeOverSmall` (8) → `fontSizeOverLarge` (24)

### Spacing System

**Base Unit**: 5px increments  
**Standard Padding**: 10, 15, 20, 25, 30, 35  
**Border Radius**: 5, 10, 15, 20  
**Web Max Width**: 1170px (via `Dimensions.webMaxWidth`)

---

## Phase 5: Module Logic (Dynamic Rendering)

### Home Screen Module Switching

**Entry Point**: `lib/features/home/screens/home_screen.dart`

#### Module Detection Logic

```dart
// 1. Check for multi-module scenario
bool showMultiModuleScreen = 
  splashController.module == null &&
  moduleList != null &&
  moduleList.length > 1;

// 2. If multiple modules → MultiModuleHomeScreen
if (showMultiModuleScreen) {
  return MultiModuleHomeScreen();
}

// 3. Single module auto-switch (if exactly 1 module)
if (moduleList.length == 1 && module == null) {
  splashController.switchModule(context, 0, true);
}

// 4. Use config module as fallback
if (module == null && configModel.module != null) {
  splashController.setModule(configModel.module);
}
```

#### Module Types

- **Food** (`AppConstants.food = 'food'`)
- **Grocery** (`AppConstants.grocery = 'grocery'`)
- **Parcel** (`AppConstants.parcel = 'parcel'`)
- **eCommerce** (`AppConstants.ecommerce = 'ecommerce'`)
- **Pharmacy** (`AppConstants.pharmacy = 'pharmacy'`)
- **Taxi/Rental** (`AppConstants.taxi = 'rental'`)

#### Module-Specific Rendering

**Multi-Module Screen** (`MultiModuleHomeScreen`):
- Shows module selection grid
- Displays promotional content from Module 3 (eCommerce)
- User selects module → `SplashController.switchModule(index)`

**Single Module Screen**:
- Renders module-specific layout
- Food/Grocery: Store listings, categories, items
- Parcel: Parcel categories, request flow
- eCommerce: Product grid, brands, categories

#### Module Switching Flow

```
User taps module icon
  → SplashController.switchModule(index)
    → setModule(ModuleModel)
      → ApiClient.updateHeader(moduleId: newModuleId)
        → _clearAllControllerData()
          → HomeScreen.loadData(forceRefresh: true)
            → Load module-specific data
              → UI rebuilds with new layout
```

**Critical Controllers Cleared on Switch**:
- `ItemController.clearItemLists()`
- `BannerController.clearBanner()`
- `CategoryController.clearCategoryList()`
- `StoreController.clearAllModuleData()`
- `CartController.clearCartOnline()` (if module type changed)

---

## Phase 6: Initialization Flow (Splash → Home)

### Splash Screen Routing Decision Tree

**Entry**: `lib/features/splash/controllers/splash_controller.dart`

#### Initialization Sequence

```
1. SplashScreen loads
   ↓
2. SplashController.getConfigData()
   ↓
3. Load app-init endpoint (parallel with home-unified pre-fetch)
   ↓
4. Store config, modules, zones in memory + Hive cache
   ↓
5. Pre-warm controllers (BannerController, OffersController)
   ↓
6. Pre-cache banner images (GPU memory)
   ↓
7. Route decision (splash_route_helper.dart)
```

#### Routing Logic (`lib/helper/splash_route_helper.dart`)

```dart
_handleUserRouting(context)
  ├─ Has Token? → _forLoggedInUserRouteProcess()
  │                ├─ Has Address? → DashboardScreen (home)
  │                └─ No Address? → AccessLocationScreen
  │
  ├─ Has Guest ID? → _forGuestUserRouteProcess()
  │                   ├─ Has Address? → DashboardScreen (home)
  │                   └─ No Address? → AccessLocationScreen
  │
  └─ No Token/ID? → _newlyRegisteredRouteProcess()
                     ├─ Multiple Languages? → LanguageScreen
                     └─ Single Language → OnboardingScreen
```

#### Route Decision Criteria

1. **Update Check**: App version vs minimum required
2. **Maintenance Mode**: Config-based maintenance screen
3. **Authentication State**: 
   - Logged in (token exists)
   - Guest (guest ID exists)
   - New user (no token/ID)
4. **Location State**:
   - Has saved address → Proceed to home
   - No address → Location screen
   - Has cache → Render from cache, update location in background

#### Critical Pre-Loading (Splash Phase)

**Parallel Loading** (Non-blocking):
- App-init endpoint (config, modules, zones, business settings)
- Home-unified (module 3 - promotional banners/offers)
- Wallet data (if logged in)

**Controller Pre-Warming**:
- BannerController: Injected with module 3 banners
- OffersController: Injected with module 3 offers
- Static storage: `BannerController.preFetchedBannerData` (survives login)

**Image Pre-Caching**:
- All banner images from module 3
- All offer banner images
- First 4 module icons
- **Result**: Images in GPU memory before splash fades out

---

## Phase 7: Asset Map

### Fonts

**Location**: `assets/font/`
- `Roboto-Regular.ttf` (400)
- `Roboto-Medium.ttf` (500)
- `Roboto-Bold.ttf` (700)
- `Roboto-Black.ttf` (900)

### Image Assets

**Location**: `assets/image/` (via `lib/util/images.dart`)

**Key Assets**:
- `logo.png`, `logo.gif` - App branding
- `placeholder.jpg` - Image fallback
- Language flags: `arabic.png`, `english.png`, `spanish.png`, `bangla.png`
- Onboarding: `onboard_1.png`, `onboard_2.png`, `onboard_3.png`
- Icons: `location.png`, `user.png`, `wallet.png`, `orders.png`, etc.
- Gifs: `logo.gif`, `giftbox.gif`, order status gifs

**Access Pattern**: `Images.assetName` (e.g., `Images.logo`, `Images.placeholder`)

### Asset Organization

- `/assets/image/` - All images
- `/assets/language/` - Translation files
- `/assets/map/` - Map assets
- `/assets/json/` - JSON data files

---

## Phase 8: Critical Design Principles

### Performance Optimization

1. **Parallel Loading**: App-init + home-unified + wallet load simultaneously
2. **Image Pre-Caching**: Banner images loaded into GPU memory during splash
3. **Controller Pre-Warming**: Data injected into controllers before navigation
4. **Cache-First Strategy**: Hive cache checked before API calls
5. **Selective Updates**: `update(['id'])` for targeted widget rebuilds

### State Management Best Practices

1. **Always use GetX controllers** - Never direct API calls from widgets
2. **Repository pattern** - Controllers call repositories, not API clients directly
3. **Reactive variables** - Use `.obs` for automatic UI updates
4. **Manual updates** - Use `update()` sparingly, prefer reactive variables
5. **Dependency injection** - Always use `Get.find<>()` for controller access

### UI Consistency Rules

1. **Custom widgets first** - Always check `lib/common/widgets/` before using Flutter widgets
2. **Theme-based colors** - Use `Theme.of(context).primaryColor`, not hardcoded colors
3. **Responsive sizing** - Use `sp(context, size)` for text, `Dimensions` constants for spacing
4. **Consistent spacing** - Use `Dimensions.paddingSize*` constants
5. **Border radius** - Use `Dimensions.radius*` constants

### Module Switching Rules

1. **Clear controllers** - Always clear module-specific data before switch
2. **Update headers** - Always update ApiClient headers with new moduleId
3. **Cache validation** - Check cache validity before clearing
4. **Shimmer display** - Show loading skeleton during module switch
5. **Background loading** - Load new module data in background while shimmer shows

---

## Phase 9: Mode Confirmation

✅ **Indexed & Ready for Jobs/Ive Mode**

### Operational Principles Confirmed

1. **Physics-Based Animations**: ✅ GetX transitions, Flutter animations
2. **Haptics**: ✅ Ready for integration (platform-specific)
3. **Optimistic UI**: ✅ Cache-first rendering, background updates
4. **Pixel-Perfect Layouts**: ✅ Custom widgets, responsive dimensions
5. **120fps Performance**: ✅ Selective updates, image pre-caching, parallel loading

### Design System Integrity

- ✅ Custom widget hierarchy mapped
- ✅ Color palette documented
- ✅ Typography system understood
- ✅ Spacing system defined
- ✅ Module switching logic clear
- ✅ State management patterns internalized

### Ready for Enhancement

The architecture is now fully mapped. All custom components, state flows, and design tokens are documented. Ready to operate in "Jobs/Ive Mode" with full context of the visual and logical hierarchy.

---

**Document Version**: 1.0  
**Analysis Date**: Current  
**Next Phase**: Design enhancement execution
