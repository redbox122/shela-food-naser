# All Stores Section - Complete Technical Report

## Overview
The "All Stores" section appears in each module's homescreen and provides a comprehensive store listing with multiple filtering and sorting options. This section is implemented using `AllRestaurantsView` widget and `AllStoreFilterWidget` for filter controls.

---

## Location & Implementation

### Widget Files
- **Main View Widget**: `lib/features/home/widgets/views/all_restaurants_view.dart`
- **Filter Widget**: `lib/features/home/widgets/all_store_filter_widget.dart`
- **Filter Bottom Sheet**: `lib/features/home/widgets/filter_bottom_sheet.dart`
- **Simple Filter View**: `lib/features/home/widgets/filter_view.dart`

### Controller
- **StoreController**: `lib/features/store/controllers/store_controller.dart`
- **Repository**: `lib/features/store/domain/repositories/store_repository.dart`

### Usage in Home Screens
- **Food Module**: `lib/features/home/screens/all_sections/food_home_screen.dart`
- **Shop/Ecommerce Module**: `lib/features/home/screens/all_sections/shop_home_screen.dart`
- **Web Home Screen**: `lib/features/home/screens/web_new_home_screen.dart`

---

## Filters Available

### 1. Store Type Filters (Horizontal Chip Buttons)

These are displayed as horizontal filter chips in the `AllStoreFilterWidget`:

#### a) **All** (`storeType: 'all'`)
- **Purpose**: Shows all stores without any specific filtering
- **API Method**: `getStoreList(offset, reload)`
- **Endpoint**: `/api/v1/stores/get-stores/all?store_type=all&offset={offset}&limit=12`
- **Pagination**: ✅ Supports pagination
- **Data Source**: Uses `allStoreModel` (legacy pagination engine)
- **Behavior**: 
  - For Food module: Automatically adds `&filter=nearby` to sort by distance (nearest first)
  - Loads stores with pagination support (12 items per page)
  - Can be combined with other filters from bottom sheet

#### b) **Newly Joined** (`storeType: 'newly_joined'`)
- **Purpose**: Shows recently added stores
- **API Method**: `getLatestStoreList(reload, type, notify)`
- **Endpoint**: `/api/v1/stores/latest?type=all`
- **Pagination**: ❌ No pagination (single list)
- **Data Source**: Uses `latestStoreList`
- **Behavior**: 
  - Returns a fixed list of newly joined stores
  - No pagination support
  - Module filtering applied client-side

#### c) **Popular** (`storeType: 'popular'`)
- **Purpose**: Shows popular/trending stores
- **API Method**: `getPopularStoreList(reload, type, notify)`
- **Endpoint**: `/api/v1/stores/popular?type=all`
- **Pagination**: ❌ No pagination (single list)
- **Data Source**: Uses `popularStoreList`
- **Behavior**: 
  - Returns a fixed list of popular stores
  - No pagination support
  - Module filtering applied client-side
  - Business settings check: `popularStoresSection == "1"` or always enabled for Food/Ecommerce modules

#### d) **Top Rated** (`storeType: 'top_rated'`)
- **Purpose**: Shows stores with highest ratings
- **API Method**: `getStoreList(offset, reload)` (same as "All" but with different sorting)
- **Endpoint**: `/api/v1/stores/get-stores/all?store_type=top_rated&offset={offset}&limit=12`
- **Pagination**: ✅ Supports pagination
- **Data Source**: Uses `allStoreModel` (legacy pagination engine)
- **Behavior**: 
  - Uses same API as "All" but with `store_type=top_rated` parameter
  - Supports pagination
  - Backend handles rating-based sorting

### 2. Delivery Type Filter (Popup Menu)

Located in `FilterView` widget (filter icon button):

#### Options:
- **All** (`filterType: 'all'`)
  - Shows stores with both delivery and take-away options
  
- **Take Away** (`filterType: 'take_away'`)
  - Shows only stores that support take-away orders
  
- **Delivery** (`filterType: 'delivery'`)
  - Shows only stores that support delivery orders

**API Impact**: 
- Changes the `filterBy` parameter in API call
- Endpoint: `/api/v1/stores/get-stores/{filterType}?store_type={storeType}&offset={offset}&limit=12`
- Triggers full reload when changed

### 3. Advanced Filters (Bottom Sheet)

Accessed via filter button in `Groups` widget, opens `FilterBottomSheet`:

#### a) **Food Type** (Radio Buttons)
- **All** (`filterType: 'all'`)
- **Veg** (`filterType: 'veg'`)
- **Non-Veg** (`filterType: 'non_veg'`)

**API Impact**: 
- Sets `filterType` in StoreController
- Changes endpoint: `/api/v1/stores/get-stores/{filterType}?store_type={storeType}&offset={offset}&limit=12`
- Triggers `getStoreList(1, true)` with new filterType

#### b) **Checkbox Filters**

**Recently Added** (`recentlyAdded: true`)
- **Purpose**: Filter stores that were recently added
- **API Parameter**: `&recently_added=true`
- **Behavior**: Combined with other filters

**Highest Rated** (`highestRated: true`)
- **Purpose**: Filter stores with rating 4.5 or higher
- **API Parameter**: `&min_rating=4.5`
- **Behavior**: Only shows stores with rating >= 4.5

**Fastest Delivery** (`fastestDelivery: true`)
- **Purpose**: Filter stores with delivery time up to 30 minutes
- **API Parameter**: `&max_delivery_time=30`
- **Behavior**: Only shows stores with delivery time <= 30 minutes

#### c) **Price Range** (Range Slider)
- **Purpose**: Filter stores by price range
- **Range**: 0 - 1000 SAR (Saudi Riyal)
- **API Parameters**: 
  - `&min_price={minPrice}` (if minPrice > 0)
  - `&max_price={maxPrice}` (if maxPrice < 1000)
- **Behavior**: Filters stores based on average order price

#### d) **Sort By** (Radio Buttons)
- **Recommended** (`sortBy: 'recommended'`)
  - Default sorting, backend decides
  
- **Distance** (`sortBy: 'distance'`)
  - Sorts by proximity to user location
  
- **Ratings Descending** (`sortBy: 'ratings_desc'`)
  - Highest rated stores first
  
- **Delivery Time Ascending** (`sortBy: 'delivery_time_asc'`)
  - Fastest delivery stores first

**API Parameter**: `&sort_by={sortBy}`

---

## API Endpoints

### Primary Endpoint: Get Stores List
```
GET /api/v1/stores/get-stores/{filterBy}?store_type={storeType}&offset={offset}&limit=12
```

**Parameters:**
- `filterBy`: `'all'`, `'take_away'`, `'delivery'` (delivery type)
- `storeType`: `'all'`, `'top_rated'` (store type filter)
- `offset`: Page number (starts at 1)
- `limit`: Items per page (fixed at 12)

**Additional Query Parameters** (from bottom sheet filters):
- `&filter=nearby` (auto-added for Food module when filterBy='all')
- `&recently_added=true` (if recentlyAdded checkbox is checked)
- `&min_rating=4.5` (if highestRated checkbox is checked)
- `&max_delivery_time=30` (if fastestDelivery checkbox is checked)
- `&min_price={minPrice}` (if price range min > 0)
- `&max_price={maxPrice}` (if price range max < 1000)
- `&sort_by={sortBy}` (if sortBy is selected)

**Headers:**
- `module-id`: Current module ID
- `zone-id`: User's zone ID
- `latitude`: User's latitude
- `longitude`: User's longitude
- `Authorization`: Bearer token (if authenticated)
- `language-code`: Current language

**Response:**
```json
{
  "stores": [...],
  "total_size": 300,
  "offset": 1,
  "limit": 12
}
```

### Secondary Endpoint: Popular Stores
```
GET /api/v1/stores/popular?type={type}
```

**Parameters:**
- `type`: `'all'`, `'veg'`, `'non_veg'` (food type filter)

**Response:**
```json
{
  "stores": [...]
}
```

### Tertiary Endpoint: Latest Stores
```
GET /api/v1/stores/latest?type={type}
```

**Parameters:**
- `type`: `'all'`, `'veg'`, `'non_veg'` (food type filter)

**Response:**
```json
{
  "stores": [...]
}
```

---

## Filter Behavior & Logic

### Filter Application Flow

1. **User selects Store Type chip** (All, Newly Joined, Popular, Top Rated)
   - Calls `storeController.setStoreType(type)`
   - Triggers appropriate API method:
     - `'all'` or `'top_rated'` → `getStoreList(1, true)`
     - `'popular'` → `getPopularStoreList(true, 'all', true)`
     - `'newly_joined'` → `getLatestStoreList(true, 'all', true)`

2. **User clicks filter icon** (FilterView)
   - Opens popup menu with delivery type options
   - Calls `storeController.setFilterType(type)`
   - Triggers `getStoreList(1, true)` with new filterType

3. **User opens bottom sheet** (FilterBottomSheet)
   - User selects multiple filters:
     - Food type (radio)
     - Recently added (checkbox)
     - Highest rated (checkbox)
     - Fastest delivery (checkbox)
     - Price range (slider)
     - Sort by (radio)
   - User clicks "Apply"
   - Calls `storeController.applyStoreFilters(filters)`
   - Triggers `getStoreList(1, true)` with all filter parameters

4. **User clears filters**
   - Calls `storeController.clearFilters()`
   - Resets all filter values to null
   - Triggers `getStoreList(1, true)` without filters

### Module-Specific Behavior

#### Food Module
- **Auto-filter**: Automatically adds `&filter=nearby` when `filterBy='all'` to sort by distance
- **Text Labels**: Uses "restaurants" instead of "stores" if `showRestaurantText=true`
- **Subtitle**: Uses "nearest_restaurants_to_you" translation key

#### Shop/Ecommerce Module
- **Text Labels**: Uses "stores" (not "restaurants")
- **Subtitle**: Uses "stores_near_you" translation key
- **No auto nearby filter**: Does not automatically add distance sorting

### Pagination Logic

**Supports Pagination:**
- ✅ `storeType: 'all'` - Uses `allStoreModel` with pagination
- ✅ `storeType: 'top_rated'` - Uses `allStoreModel` with pagination

**No Pagination:**
- ❌ `storeType: 'popular'` - Fixed list, no pagination
- ❌ `storeType: 'newly_joined'` - Fixed list, no pagination

**Pagination Trigger:**
- Scroll listener detects when user is within 300px of bottom
- Automatically loads next page: `getStoreList(currentOffset + 1, false)`
- Shows loading indicator while fetching

### Module Isolation

**Critical Feature**: Each module only shows its own stores
- **Client-side filtering**: `StoreRepository._filterStoresByModule()` filters stores by `moduleId`
- **Header-based filtering**: API receives `module-id` in headers for server-side filtering
- **Double protection**: Both client and server filter by module to prevent cross-module contamination

---

## State Management

### StoreController State Variables

```dart
// Store type filter
String _storeType = 'all';  // 'all', 'popular', 'newly_joined', 'top_rated'

// Delivery type filter
String _filterType = 'all';  // 'all', 'take_away', 'delivery'

// Advanced filters
bool? _recentlyAdded;
bool? _highestRated;
bool? _fastestDelivery;
double? _minPrice;
double? _maxPrice;
String? _sortBy;

// Data models
StoreModel? _allStoreModel;  // For 'all' and 'top_rated' (with pagination)
List<Store>? _popularStoreList;  // For 'popular' (no pagination)
List<Store>? _latestStoreList;  // For 'newly_joined' (no pagination)
```

### State Updates

- **setStoreType()**: Updates `_storeType` and triggers appropriate API call
- **setFilterType()**: Updates `_filterType` and triggers `getStoreList()` reload
- **applyStoreFilters()**: Updates all advanced filter variables and triggers reload
- **clearFilters()**: Resets all filter variables to null and triggers reload

---

## UI Components

### AllStoreFilterWidget
- **Location**: Top of all stores section
- **Desktop**: Horizontal layout with title, subtitle, view toggle, and filters
- **Mobile**: Vertical layout with title/subtitle on top, filters below
- **Features**:
  - Title: "Restaurants" or "Stores" (module-dependent)
  - Subtitle: Shows total count + "near you" text
  - View toggle: Grid/List view switcher
  - Filter chips: All, Newly Joined, Popular, Top Rated
  - Filter icon: Opens delivery type popup menu

### AllRestaurantsView
- **Location**: Main content area below filter widget
- **Features**:
  - Groups widget: Filter chips + filter button
  - Store list: Grid or List view (based on `isVertical` state)
  - Pagination: Auto-loads more on scroll
  - Empty state: Shows "no_restaurant_available" or "no_store_available"
  - Loading state: Shows shimmer/loading indicator

### FilterBottomSheet
- **Location**: Modal bottom sheet
- **Features**:
  - Food type selection (radio buttons)
  - Checkbox filters (Recently Added, Highest Rated, Fastest Delivery)
  - Price range slider (0-1000 SAR)
  - Sort by options (radio buttons)
  - Apply button (yellow)
  - Clear All button (gray)

---

## API Call Flow

### Example: User selects "Popular" filter

1. **User Action**: Taps "Popular" chip
2. **UI Update**: `setStoreType('popular')` called
3. **Controller**: Updates `_storeType = 'popular'` and calls `update()`
4. **API Call**: `getPopularStoreList(true, 'all', true, dataSource: DataSourceEnum.client)`
5. **Repository**: Calls `/api/v1/stores/popular?type=all`
6. **Response**: Receives list of popular stores
7. **Filtering**: `_filterStoresByModule()` filters by current moduleId
8. **State Update**: `_popularStoreList` updated, `update()` called
9. **UI Render**: `AllRestaurantsView` displays filtered stores

### Example: User applies bottom sheet filters

1. **User Action**: Opens filter bottom sheet, selects filters, clicks "Apply"
2. **Filter Application**: `applyStoreFilters(filters)` called
3. **State Update**: All filter variables updated:
   - `_recentlyAdded = true`
   - `_highestRated = true`
   - `_minPrice = 50.0`
   - `_maxPrice = 200.0`
   - `_sortBy = 'ratings_desc'`
4. **API Call**: `getStoreList(1, true, source: DataSourceEnum.client)`
5. **Repository**: Builds query string:
   ```
   /api/v1/stores/get-stores/all?store_type=all&offset=1&limit=12&recently_added=true&min_rating=4.5&min_price=50.00&max_price=200.00&sort_by=ratings_desc
   ```
6. **Response**: Receives filtered and sorted stores
7. **State Update**: `_allStoreModel` updated, `update()` called
8. **UI Render**: `AllRestaurantsView` displays filtered stores

---

## Key Implementation Details

### 1. Hard Isolation Pattern
- Uses `allStoreModel` for pagination-enabled filters (not `storeModel`)
- Prevents state contamination between different filter types
- Ensures correct pagination behavior

### 2. Module Filtering
- **Server-side**: `module-id` header sent with every request
- **Client-side**: `_filterStoresByModule()` filters results by `moduleId`
- **Double protection**: Prevents cross-module store contamination

### 3. V2 API Integration
- Waits for V2 data distribution before loading stores
- Prevents race conditions during module switching
- Checks `HomeUnifiedController.hasCachedData` before API calls

### 4. Cache Strategy
- **First load**: Checks comprehensive cache for default state (no filters)
- **Filter change**: Always bypasses cache (reload=true)
- **Pagination**: Uses cache for subsequent pages if available

### 5. Pagination Retry Logic
- **Issue**: Backend pagination bug with `filter=nearby` returns 0 stores
- **Fix**: Automatically retries without `filter=nearby` if:
  - Response has 0 stores
  - But `total_size > 0`
  - And `filter=nearby` was used
- **Result**: User sees stores instead of blank screen

---

## Business Settings Integration

The all stores section respects business settings flags:

- **allStoresSection**: Controls visibility of entire section
- **popularStoresSection**: Controls "Popular" filter availability
- **topRestaurantsSection**: Controls "Top Rated" filter availability (Food module)

If a section is disabled in business settings, the corresponding filter may not appear or may be hidden.

---

## Error Handling

### Empty States
- Shows "no_restaurant_available" or "no_store_available" message
- Empty list set instead of null to show empty state UI (not shimmer)

### API Errors
- Catches exceptions in try-catch blocks
- Sets empty list on error to show empty state
- Logs errors for debugging

### Loading States
- Shows shimmer/loading indicator while fetching
- Prevents duplicate simultaneous API calls
- Uses `Completer` for popular stores to handle concurrent requests

---

## Summary

The All Stores section provides a comprehensive store browsing experience with:

✅ **4 Store Type Filters**: All, Newly Joined, Popular, Top Rated  
✅ **3 Delivery Type Filters**: All, Take Away, Delivery  
✅ **3 Checkbox Filters**: Recently Added, Highest Rated, Fastest Delivery  
✅ **Price Range Filter**: 0-1000 SAR slider  
✅ **4 Sort Options**: Recommended, Distance, Ratings Desc, Delivery Time Asc  
✅ **Pagination Support**: For "All" and "Top Rated" filters  
✅ **Module Isolation**: Each module shows only its own stores  
✅ **Responsive Design**: Different layouts for mobile and desktop  
✅ **View Toggle**: Grid and List view options  

**Total API Endpoints Used**: 3
- `/api/v1/stores/get-stores/{filterBy}` (main endpoint with pagination)
- `/api/v1/stores/popular` (popular stores, no pagination)
- `/api/v1/stores/latest` (newly joined stores, no pagination)

**Total Filter Combinations**: Hundreds of possible combinations based on user selections.

