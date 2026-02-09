# Authentication Feature Documentation

## Overview

The Authentication feature handles user login, registration, social authentication, phone verification, and session management.

## Location

```
lib/features/auth/
├── controllers/
│   └── auth_controller.dart
├── screens/
│   ├── sign_in_screen.dart
│   ├── sign_up_screen.dart
│   └── social_login_screen.dart
├── widgets/
│   ├── sign_in_widget.dart
│   ├── sign_up_widget.dart
│   └── social_login_button.dart
└── domain/
    ├── models/
    │   ├── signup_body.dart
    │   └── social_login_body.dart
    └── repositories/
        └── auth_service_interface.dart
```

## Features

### 1. Email/Phone Login
- Email address validation
- Phone number validation
- Password authentication
- Remember me functionality
- Forgot password flow

### 2. Registration
- First name & Last name
- Email validation
- Phone number with country code
- Password with confirmation
- Terms & conditions acceptance
- Profile image upload (optional)

### 3. Social Login
- Google Sign-In
- Facebook Sign-In
- Apple Sign-In (iOS)
- Auto account creation

### 4. Phone Verification
- OTP (One-Time Password) generation
- SMS delivery
- OTP validation
- Resend OTP functionality
- Timer countdown

### 5. Session Management
- Token storage
- Auto-login
- Session expiry handling
- Logout functionality

## Authentication Controller

### State Management

```dart
class AuthController extends GetxController {
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isGuestMode = true.obs;
  
  // User data
  final Rx<UserInfoModel?> userInfoModel = Rx<UserInfoModel?>(null);
  
  // Form data
  final RxString countryCode = '+966'.obs;
  
  // Password visibility
  final RxBool obscurePassword = true.obs;
  
  // Dependencies
  final AuthServiceInterface authService;
  
  AuthController({required this.authService});
}
```

### Key Methods

#### Login

```dart
Future<void> login(String phone, String password) async {
  isLoading.value = true;
  
  try {
    Response response = await authService.login(phone, password);
    
    if (response.statusCode == 200) {
      // Parse response
      var data = response.body;
      
      // Save token
      await authService.saveUserToken(data['token']);
      
      // Save user data
      await authService.saveUserData(data['user']);
      
      // Update state
      userInfoModel.value = UserInfoModel.fromJson(data['user']);
      isGuestMode.value = false;
      
      // Navigate to home
      Get.offAllNamed(RouteHelper.getInitialRoute());
      
      showCustomSnackBar('Login successful', isError: false);
    } else {
      showCustomSnackBar(response.statusText ?? 'Login failed');
    }
  } catch (e) {
    showCustomSnackBar('An error occurred: $e');
  } finally {
    isLoading.value = false;
  }
}
```

#### Registration

```dart
Future<void> registration(SignUpBody signUpBody) async {
  isLoading.value = true;
  
  try {
    Response response = await authService.registration(signUpBody);
    
    if (response.statusCode == 200) {
      var data = response.body;
      
      // Check if phone verification required
      if (data['is_phone_verified'] == 0) {
        // Navigate to verification screen
        Get.toNamed(
          RouteHelper.getVerificationRoute(),
          arguments: {'phone': signUpBody.phone},
        );
      } else {
        // Save tokens and proceed
        await authService.saveUserToken(data['token']);
        await authService.saveUserData(data['user']);
        
        userInfoModel.value = UserInfoModel.fromJson(data['user']);
        isGuestMode.value = false;
        
        Get.offAllNamed(RouteHelper.getInitialRoute());
        showCustomSnackBar('Registration successful', isError: false);
      }
    } else {
      showCustomSnackBar(response.statusText ?? 'Registration failed');
    }
  } catch (e) {
    showCustomSnackBar('An error occurred: $e');
  } finally {
    isLoading.value = false;
  }
}
```

#### Social Login

```dart
Future<void> socialLogin(SocialLoginBody socialBody) async {
  isLoading.value = true;
  
  try {
    Response response = await authService.socialLogin(socialBody);
    
    if (response.statusCode == 200) {
      var data = response.body;
      
      await authService.saveUserToken(data['token']);
      await authService.saveUserData(data['user']);
      
      userInfoModel.value = UserInfoModel.fromJson(data['user']);
      isGuestMode.value = false;
      
      Get.offAllNamed(RouteHelper.getInitialRoute());
      showCustomSnackBar('Login successful', isError: false);
    } else {
      showCustomSnackBar(response.statusText ?? 'Social login failed');
    }
  } catch (e) {
    showCustomSnackBar('An error occurred: $e');
  } finally {
    isLoading.value = false;
  }
}
```

#### Logout

```dart
Future<void> logout() async {
  isLoading.value = true;
  
  try {
    // Clear local data
    await authService.clearUserData();
    await authService.clearUserToken();
    
    // Update state
    userInfoModel.value = null;
    isGuestMode.value = true;
    
    // Clear cart
    Get.find<CartController>().clearCart();
    
    // Navigate to login
    Get.offAllNamed(RouteHelper.getSignInRoute());
    
    showCustomSnackBar('Logged out successfully', isError: false);
  } catch (e) {
    showCustomSnackBar('An error occurred: $e');
  } finally {
    isLoading.value = false;
  }
}
```

## UI Screens

### Sign In Screen

**Key Components:**
- Email/Phone input field
- Password input field
- Remember me checkbox
- Forgot password link
- Sign in button
- Social login buttons
- Sign up navigation

**Validation:**
```dart
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  if (!GetUtils.isEmail(value) && !GetUtils.isPhoneNumber(value)) {
    return 'Enter a valid email or phone';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
```

### Sign Up Screen

**Key Components:**
- First name & Last name fields
- Email field
- Phone number with country picker
- Password & Confirm password fields
- Profile image picker
- Terms & conditions checkbox
- Sign up button
- Sign in navigation

**Features:**
- Real-time validation
- Password strength indicator
- Image cropping
- Country code selection

### Social Login Buttons

**Supported Platforms:**
- Google (Android & iOS)
- Facebook (Android & iOS)
- Apple (iOS only)

**Implementation:**
```dart
// Google Sign In
Future<void> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    
    if (googleUser != null) {
      final GoogleSignInAuthentication auth = await googleUser.authentication;
      
      SocialLoginBody body = SocialLoginBody(
        email: googleUser.email,
        token: auth.idToken,
        uniqueId: googleUser.id,
        provider: 'google',
      );
      
      await authController.socialLogin(body);
    }
  } catch (e) {
    showCustomSnackBar('Google sign in failed: $e');
  }
}
```

## Data Models

### SignUp Body

```dart
class SignUpBody {
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? password;
  String? countryCode;
  String? referCode;
  String? image;
  
  SignUpBody({
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.password,
    this.countryCode,
    this.referCode,
    this.image,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'f_name': fName,
      'l_name': lName,
      'phone': phone,
      'email': email,
      'password': password,
      'country_code': countryCode,
      'ref_code': referCode,
    };
  }
}
```

### Social Login Body

```dart
class SocialLoginBody {
  String? email;
  String? token;
  String? uniqueId;
  String? provider; // 'google', 'facebook', 'apple'
  
  SocialLoginBody({
    this.email,
    this.token,
    this.uniqueId,
    this.provider,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'token': token,
      'unique_id': uniqueId,
      'medium': provider,
    };
  }
}
```

## API Endpoints

```dart
// Login
POST /api/v1/auth/login
Body: {
  "phone": "+1234567890",
  "password": "password123"
}

// Register
POST /api/v1/auth/register
Body: {
  "f_name": "John",
  "l_name": "Doe",
  "email": "user@example.com",
  "phone": "+1234567890",
  "password": "password123",
  "country_code": "+1"
}

// Social Login
POST /api/v1/auth/social-login
Body: {
  "email": "user@example.com",
  "token": "social_token",
  "unique_id": "social_user_id",
  "medium": "google"
}

// Verify Phone
POST /api/v1/auth/verify-phone
Body: {
  "phone": "+1234567890",
  "otp": "123456"
}

// Logout
POST /api/v1/auth/logout
Headers: {
  "Authorization": "Bearer {token}"
}
```

## Security Features

### 1. Password Security
- Minimum 6 characters
- Password hashing on backend
- Secure storage using Flutter Secure Storage

### 2. Token Management
- JWT tokens
- Secure token storage
- Auto token refresh
- Token expiry handling

### 3. Data Validation
- Email format validation
- Phone number validation
- Input sanitization
- XSS prevention

### 4. Session Management
- Auto-logout on token expiry
- Device-based session tracking
- Concurrent session handling

## Guest Mode

Users can browse the app without logging in:

```dart
void continueAsGuest() {
  isGuestMode.value = true;
  Get.offAllNamed(RouteHelper.getInitialRoute());
}
```

**Limitations in Guest Mode:**
- Cannot add to cart
- Cannot place orders
- Cannot save favorites
- Cannot view order history
- Cannot access wallet

## Error Handling

Common error scenarios:

### 1. Invalid Credentials
```dart
if (response.statusCode == 401) {
  showCustomSnackBar('Invalid email or password');
}
```

### 2. Account Not Verified
```dart
if (data['is_phone_verified'] == 0) {
  // Redirect to verification
  Get.toNamed(RouteHelper.getVerificationRoute());
}
```

### 3. Account Suspended
```dart
if (data['is_active'] == 0) {
  showCustomSnackBar('Your account has been suspended');
}
```

### 4. Network Error
```dart
catch (e) {
  showCustomSnackBar('Connection error. Please try again.');
}
```

## Integration with Other Features

### Profile Feature
- User data sync
- Profile image update
- Personal information edit

### Order Feature
- User identification for orders
- Order history access

### Cart Feature
- Persistent cart for logged-in users
- Guest cart conversion on login

### Notification Feature
- FCM token registration
- User-specific notifications

## Best Practices

1. **Always validate input** before sending to API
2. **Use secure storage** for sensitive data
3. **Handle token expiry** gracefully
4. **Clear data on logout** completely
5. **Support biometric authentication** for quick login
6. **Implement rate limiting** for login attempts
7. **Use SSL pinning** for API calls
8. **Log security events** for audit

## Testing

### Unit Tests

```dart
test('Login with valid credentials should succeed', () async {
  // Arrange
  var controller = AuthController(authService: mockAuthService);
  
  // Act
  await controller.login('user@example.com', 'password123');
  
  // Assert
  expect(controller.isLoading.value, false);
  expect(controller.userInfoModel.value, isNotNull);
  expect(controller.isGuestMode.value, false);
});
```

### Widget Tests

```dart
testWidgets('Sign in form should validate inputs', (tester) async {
  await tester.pumpWidget(SignInScreen());
  
  // Find sign in button
  final signInButton = find.text('Sign In');
  
  // Tap without entering data
  await tester.tap(signInButton);
  await tester.pump();
  
  // Expect validation errors
  expect(find.text('Email is required'), findsOneWidget);
  expect(find.text('Password is required'), findsOneWidget);
});
```

## Troubleshooting

### Issue: Login button not working
**Solution**: Check network connection and API endpoint configuration

### Issue: Social login fails
**Solution**: Verify Google/Facebook app configuration and API keys

### Issue: Token expired
**Solution**: Implement token refresh mechanism

### Issue: OTP not received
**Solution**: Check SMS gateway configuration and phone number format
