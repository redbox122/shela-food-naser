# Quick Reference Guide

## File Structure Quick Reference

```
lib/
├── api/                          # API Client & Network Layer
├── common/                       # Shared Components
│   ├── api/                     # API utilities
│   ├── cache/                   # Caching system
│   ├── controllers/             # Shared controllers
│   ├── enums/                   # Enum definitions
│   ├── models/                  # Common models
│   ├── security/                # Security utilities
│   ├── services/                # Platform services
│   ├── utils/                   # Helper utilities
│   └── widgets/                 # Reusable widgets
├── features/                     # Feature Modules
│   ├── auth/                    # Authentication
│   ├── home/                    # Home screen
│   ├── store/                   # Store browsing
│   ├── item/                    # Item details
│   ├── cart/                    # Shopping cart
│   ├── checkout/                # Checkout process
│   ├── order/                   # Order management
│   ├── profile/                 # User profile
│   └── [... 36 more features]
├── helper/                       # Helper classes
├── services/                     # App services
├── theme/                        # App theming
├── util/                         # Utility functions
├── widgets/                      # Global widgets
└── main.dart                     # App entry point
```

## Common Commands

### Get Dependencies

```bash
flutter pub get
```

### Run App

```bash
# Development
flutter run

# Release
flutter run --release

# Specific device
flutter run -d <device_id>
```

### Build App

```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

### Clean Build

```bash
flutter clean
flutter pub get
flutter run
```

## GetX State Management Cheat Sheet

### Controller Lifecycle

```dart
class MyController extends GetxController {
  // Called when controller is created
  @override
  void onInit() {
    super.onInit();
    // Initialize data
  }
  
  // Called after onInit
  @override
  void onReady() {
    super.onReady();
    // Make API calls
  }
  
  // Called when controller is removed
  @override
  void onClose() {
    super.onClose();
    // Cleanup resources
  }
}
```

### Dependency Injection

```dart
// Lazy instantiation
Get.lazyPut(() => MyController());

// Immediate instantiation
Get.put(MyController());

// Find existing instance
final controller = Get.find<MyController>();

// Using bindings
class MyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MyController());
  }
}
```

### Reactive State

```dart
// Observable variable
final count = 0.obs;

// Update
count.value = 10;
count.value++;

// Use in UI
Obx(() => Text('${count.value}'))
```

### State Update

```dart
// Trigger rebuild
update();

// Trigger rebuild with ID
update(['specific_id']);

// Use in UI
GetBuilder<MyController>(
  builder: (controller) => Text(controller.data),
)
```

### Navigation

```dart
// Navigate to route
Get.toNamed('/route');

// Navigate with arguments
Get.toNamed('/route', arguments: {'id': 123});

// Replace current route
Get.offNamed('/route');

// Clear stack and navigate
Get.offAllNamed('/route');

// Go back
Get.back();

// Go back with result
Get.back(result: {'success': true});
```

## Common Widgets

### Custom Button

```dart
CustomButton(
  buttonText: 'Click Me',
  onPressed: () {
    // Action
  },
  isLoading: controller.isLoading.value,
  transparent: false,
  width: double.infinity,
)
```

### Custom Text Field

```dart
CustomTextField(
  hintText: 'Enter text',
  controller: textController,
  inputType: TextInputType.text,
  prefixIcon: Icons.person,
  isPassword: false,
  onChanged: (value) {
    // Handle change
  },
)
```

### Loading Indicator

```dart
// Full screen loading
if (controller.isLoading.value)
  LoadingIndicator()

// Inline loading
controller.isLoading.value
  ? CircularProgressIndicator()
  : YourWidget()
```

### Empty State

```dart
EmptyView(
  message: 'No items found',
  image: Images.emptyBox,
)
```

### Snackbar

```dart
// Success
showCustomSnackBar(
  'Operation successful',
  isError: false,
);

// Error
showCustomSnackBar(
  'Something went wrong',
  isError: true,
);
```

### Paginated List

```dart
PaginatedListView(
  scrollController: scrollController,
  onPaginate: () {
    controller.loadMore();
  },
  itemCount: controller.items.length,
  itemBuilder: (context, index) {
    return ItemWidget(controller.items[index]);
  },
)
```

## API Client Usage

### GET Request

```dart
Response response = await Get.find<ApiClient>().getData(
  '/api/v1/endpoint',
  query: {'param': 'value'},
);

if (response.statusCode == 200) {
  var data = jsonDecode(response.body);
  // Process data
}
```

### POST Request

```dart
Response response = await Get.find<ApiClient>().postData(
  '/api/v1/endpoint',
  {
    'key': 'value',
  },
);
```

### File Upload

```dart
List<MultipartBody> multipartBody = [];
multipartBody.add(MultipartBody('image', file));

Response response = await Get.find<ApiClient>().postMultipartData(
  '/api/v1/upload',
  {'name': 'John'},
  multipartBody,
);
```

### With Cache

```dart
final data = await ApiCallManager.instance.request(
  url: '/api/v1/data',
  method: 'GET',
  cacheKey: 'my_data',
  cacheDuration: Duration(minutes: 5),
);
```

## Common Utilities

### Date Formatting

```dart
// Format date
String formatted = DateConverter.dateToDateAndTime(DateTime.now());

// Time ago
String timeAgo = DateConverter.convertTimeToTime(dateTime);
```

### Responsive Dimensions

```dart
// Font sizes
fontSize: Dimensions.fontSizeDefault
fontSize: Dimensions.fontSizeSmall
fontSize: Dimensions.fontSizeLarge

// Padding
padding: EdgeInsets.all(Dimensions.paddingDefault)

// Margins
margin: EdgeInsets.symmetric(
  horizontal: Dimensions.paddingLarge,
  vertical: Dimensions.paddingSmall,
)
```

### Validation

```dart
// Email
if (!GetUtils.isEmail(email)) {
  // Invalid email
}

// Phone
if (!GetUtils.isPhoneNumber(phone)) {
  // Invalid phone
}

// Length
if (password.length < 6) {
  // Too short
}
```

### Image Assets

```dart
Image.asset(
  Images.logo,
  width: 100,
  height: 100,
)
```

### Cached Network Image

```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => LoadingIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

## Environment Configuration

### Development

```dart
static const String APP_NAME = 'YourApp Dev';
static const String BASE_URL = 'https://dev-api.example.com';
static const bool IS_DEMO = true;
```

### Production

```dart
static const String APP_NAME = 'YourApp';
static const String BASE_URL = 'https://api.example.com';
static const bool IS_DEMO = false;
```

## Module IDs

```dart
// Food Delivery
moduleId: 1

// Grocery
moduleId: 2

// Pharmacy
moduleId: 3

// E-commerce
moduleId: 4

// Parcel
moduleId: 6

// Rental
moduleId: 7 (or custom)
```

## Shared Preferences Keys

```dart
// App Constants
AppConstants.TOKEN              // Auth token
AppConstants.USER_DATA          // User information
AppConstants.LANGUAGE_CODE      // Selected language
AppConstants.ZONE_ID            // Current zone ID
AppConstants.MODULE_ID          // Current module ID
AppConstants.CART_LIST          // Cart items
AppConstants.ADDRESS_LIST       // Saved addresses
```

## Common Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 400 | Bad Request | Show validation errors |
| 401 | Unauthorized | Redirect to login |
| 403 | Forbidden | Show access denied |
| 404 | Not Found | Show not found message |
| 422 | Validation Error | Show field errors |
| 429 | Too Many Requests | Show rate limit message |
| 500 | Server Error | Show generic error |
| 503 | Service Unavailable | Show maintenance message |

## Firebase Configuration

### Android

```
android/app/google-services.json
```

### iOS

```
ios/Runner/GoogleService-Info.plist
```

### Initialize

```dart
await Firebase.initializeApp();
await FirebaseMessaging.instance.getToken();
```

## Theme Colors

```dart
// Primary
Theme.of(context).primaryColor

// Secondary
Theme.of(context).colorScheme.secondary

// Background
Theme.of(context).scaffoldBackgroundColor

// Text
Theme.of(context).textTheme.bodyLarge?.color

// Card
Theme.of(context).cardColor
```

## Routes

```dart
// Authentication
RouteHelper.getSignInRoute()
RouteHelper.getSignUpRoute()

// Main
RouteHelper.getInitialRoute()
RouteHelper.getDashboardRoute()
RouteHelper.getHomeRoute()

// Store & Items
RouteHelper.getStoreRoute(id)
RouteHelper.getItemRoute(id)

// Cart & Checkout
RouteHelper.getCartRoute()
RouteHelper.getCheckoutRoute()

// Orders
RouteHelper.getOrderRoute()
RouteHelper.getOrderDetailsRoute(id)

// Profile
RouteHelper.getProfileRoute()
RouteHelper.getAddressRoute()
```

## Testing Commands

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# With coverage
flutter test --coverage

# Integration tests
flutter drive --target=test_driver/app.dart
```

## Performance Optimization

### 1. Use const constructors

```dart
const Text('Hello')
const SizedBox(height: 10)
```

### 2. Avoid rebuilding

```dart
// Use GetBuilder with specific IDs
GetBuilder<Controller>(
  id: 'specific_widget',
  builder: (controller) => Widget(),
)
```

### 3. Lazy loading

```dart
// Lazy put
Get.lazyPut(() => Controller());

// Lazy list building
ListView.builder() // instead of ListView()
```

### 4. Image optimization

```dart
// Cache images
CachedNetworkImage()

// Resize images
Image.network(url, cacheWidth: 300)
```

### 5. Dispose properly

```dart
@override
void onClose() {
  textController.dispose();
  scrollController.dispose();
  super.onClose();
}
```

## Debugging Tips

### 1. Print API responses

```dart
if (kDebugMode) {
  print('Response: ${response.body}');
}
```

### 2. Check state updates

```dart
void updateState() {
  count++;
  print('Count updated: $count');
  update();
}
```

### 3. Use Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 4. Check network traffic

- Use Charles Proxy or Proxyman
- Enable HTTP logging in ApiClient

### 5. Analyze performance

```bash
flutter run --profile
```

## Common Issues & Solutions

### Issue: "Get.find() called before put"

**Solution**: Register dependency before using

```dart
// In main.dart or binding
Get.put(MyController());
```

### Issue: Widget not updating

**Solution**: Use `.obs` and `update()`

```dart
// Make variable observable
final count = 0.obs;

// Or call update()
update();
```

### Issue: Token not included in request

**Solution**: Check token storage

```dart
String? token = sharedPreferences.getString(AppConstants.TOKEN);
print('Token: $token');
```

### Issue: Cache not working

**Solution**: Enable caching

```dart
ApiCallManager.instance.request(
  url: '/endpoint',
  cacheKey: 'unique_key', // Must provide cache key
);
```

## Best Practices Checklist

- [ ] Use const constructors where possible
- [ ] Dispose controllers and streams
- [ ] Handle null safety properly
- [ ] Add loading states for async operations
- [ ] Validate user input
- [ ] Handle errors gracefully
- [ ] Use meaningful variable names
- [ ] Add comments for complex logic
- [ ] Follow Clean Architecture principles
- [ ] Write unit tests
- [ ] Optimize images
- [ ] Use caching for API calls
- [ ] Implement proper error logging
- [ ] Secure sensitive data
- [ ] Test on multiple devices
- [ ] Handle offline scenarios

## Useful Links

- [Flutter Documentation](https://flutter.dev/docs)
- [GetX Documentation](https://github.com/jonataslaw/getx)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)
- [Firebase Documentation](https://firebase.google.com/docs)
