import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/profile/domain/models/update_user_model.dart';
import 'package:sixam_mart/features/profile/domain/models/userinfo_model.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/verification/screens/verification_screen.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/profile/domain/services/profile_service_interface.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

class ProfileController extends GetxController implements GetxService {
  final ProfileServiceInterface profileServiceInterface;
  ProfileController({required this.profileServiceInterface});

  UserInfoModel? _userInfoModel;
  UserInfoModel? get userInfoModel => _userInfoModel;

  XFile? _pickedFile;
  XFile? get pickedFile => _pickedFile;

  XFile? _originalPickedFile;
  XFile? get originalPickedFile => _originalPickedFile;

  /// Locally hides the existing (server) avatar after the user removes their
  /// photo, until a new one is picked. UI-only.
  bool _avatarCleared = false;
  bool get avatarCleared => _avatarCleared;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasProfileError = false;
  bool get hasProfileError => _hasProfileError;

  // Guard against duplicate concurrent getUserInfo calls
  bool _isFetchingUserInfo = false;
  Future<void>? _inFlightGetUserInfo;

  Future<void> getUserInfo({bool forceRefresh = false}) async {
    // A forced refresh (e.g. after a wallet operation) must always run fresh —
    // don't piggy-back on an in-flight ETag fetch that may return a 304/cache.
    final Future<void>? existing = _inFlightGetUserInfo;
    if (!forceRefresh && _isFetchingUserInfo && existing != null) {
      if (kDebugMode) {
        debugPrint('[PROFILE][GET_USER_INFO_SKIP_IN_PROGRESS]');
      }
      return existing;
    }
    _isFetchingUserInfo = true;
    final Future<void> fetchFuture = _runGetUserInfo(forceRefresh: forceRefresh);
    _inFlightGetUserInfo = fetchFuture;
    try {
      await fetchFuture;
    } finally {
      _isFetchingUserInfo = false;
      _inFlightGetUserInfo = null;
    }
  }

  Future<void> _runGetUserInfo({bool forceRefresh = false}) async {
    _hasProfileError = false;
    _pickedFile = null;
    final bool hadExistingData = _userInfoModel != null;
    if (AuthHelper.isLoggedIn() && _userInfoModel == null) {
      if (kDebugMode) {
        debugPrint('[PROFILE][USER_INFO_MISSING_ON_STARTUP] loading=true');
      }
    }
    if (kDebugMode && hadExistingData) {
      debugPrint('[PROFILE][CACHE_USED] hasUser=true');
    }
    if (kDebugMode) {
      debugPrint('[PROFILE][GET_USER_INFO_START]');
    }
    final UserInfoModel? userInfoModel =
        await profileServiceInterface.getUserInfo(forceRefresh: forceRefresh);
    if (userInfoModel != null) {
      _userInfoModel = userInfoModel;
      if (kDebugMode) {
        debugPrint('[PROFILE][GET_USER_INFO_DONE] status=200');
        // Extract wallet flags from user info response (NEW - from /api/v1/customer/info)
        // ⚡ TASK 2: If qidha_wallet_balance exists, default creditLimit to 5000.0
        if (userInfoModel.hasQidhaWallet == true && Get.isRegistered<KaidhaSubscriptionController>()) {
          final kaidhaController = Get.find<KaidhaSubscriptionController>();
          // Only set wallet state if not already set (e.g., from login response)
          if (kaidhaController.walletKaidhaModel == null) {
            debugPrint('💳 ProfileController: Extracting wallet flags from user info response...');
            debugPrint('   - Has Qidha Wallet: ${userInfoModel.hasQidhaWallet}');
            debugPrint('   - Signed: ${userInfoModel.qidhaWalletSigned}');
            debugPrint('   - Active: ${userInfoModel.qidhaWalletActive}');
            debugPrint('   - Balance: ${userInfoModel.qidhaWalletBalance}');
            // ⚡ TASK 2: If qidha_wallet_balance exists, set wallet state with default creditLimit
            if (userInfoModel.qidhaWalletBalance != null) {
              kaidhaController.setWalletStateFromLogin(
                signed: userInfoModel.qidhaWalletSigned == true,
                active: userInfoModel.qidhaWalletActive == true,
                balance: userInfoModel.qidhaWalletBalance?.toString(),
              );
              debugPrint('✅ ProfileController: Wallet state set from user info response with default creditLimit (5000.0) - menu can show wallet button immediately');
            }
          } else {
            // ⚡ TASK 2: If wallet exists but creditLimit is null/empty, default to 5000.0
            if (kaidhaController.walletKaidhaModel?.wallet != null) {
              final wallet = kaidhaController.walletKaidhaModel!.wallet!;
              final currentCreditLimit = wallet.creditLimit;
              // Check if creditLimit is null, empty string, or 0
              final bool needsDefault = currentCreditLimit == null || 
                  (currentCreditLimit is String && (currentCreditLimit.isEmpty || currentCreditLimit == '0')) ||
                  (currentCreditLimit is num && currentCreditLimit == 0);
              
              if (needsDefault && userInfoModel.qidhaWalletBalance != null) {
                // Update creditLimit to 5000.0
                wallet.creditLimit = 5000.0;
                kaidhaController.update();
                if (kDebugMode) {
                  debugPrint('✅ ProfileController: Defaulted creditLimit to 5000.0 (was null/empty)');
                }
              }
            }
            debugPrint('⏭️ ProfileController: Wallet state already set (e.g., from login) - skipping wallet flags extraction');
          }
        }
      }
    } else if (hadExistingData) {
      // ⚡ FIX: Preserve existing _userInfoModel when API returns null (304 Not Modified case)
      // Repository now returns existing userInfoModel on 304, so this should rarely happen
      // But keeping this safety check to preserve existing data
      if (kDebugMode) {
        debugPrint('⚠️ ProfileController: getUserInfo() - API returned null (likely 304), preserving existing userInfoModel');
      }
      // _userInfoModel remains unchanged (preserved)
    } else {
      _hasProfileError = true;
      if (kDebugMode) {
        debugPrint('ℹ️ ProfileController: getUserInfo() - API returned null and no existing data');
      }
    }
    update();
  }

  /// ⚡ BFF API v2: Set user info from unified endpoint
  /// Called by HomeUnifiedController when customer data arrives in unified response
  void setUserInfoFromUnified(UserInfoModel userInfoModel) {
    _userInfoModel = userInfoModel;
    update();
  }

  /// ⚡ PERFORMANCE: Set user info from login response (minimal data for instant menu rendering)
  /// Called by AuthService when login response includes user data
  void setUserInfoFromLogin({
    required int? id,
    required String? fName,
    required String? lName,
    required String? imageFullUrl,
    required int loyaltyPoint,
    required double walletBalance,
  }) {
    debugPrint('👤 ProfileController: Setting user info from login response...');
    debugPrint('   - ID: $id');
    debugPrint('   - Name: $fName $lName');
    debugPrint('   - Image: ${imageFullUrl != null ? 'exists' : 'null'}');
    debugPrint('   - Loyalty Points: $loyaltyPoint');
    debugPrint('   - Wallet Balance: $walletBalance');
    
    _userInfoModel = UserInfoModel(
      id: id,
      fName: fName,
      lName: lName,
      imageFullUrl: imageFullUrl,
      loyaltyPoint: loyaltyPoint,
      walletBalance: walletBalance,
    );
    
    debugPrint('✅ ProfileController: User info set successfully - menu can render immediately');
    update();
  }

  void setForceFullyUserEmpty() {
    _userInfoModel = null;
  }

  Future<ResponseModel> updateUserInfo(UpdateUserModel updateUserModel, String token,
      {bool fromVerification = false, bool fromButton = false}) async {
    if (fromButton) {
      _isLoading = true;
      update();
    }
    final ResponseModel responseModel = await profileServiceInterface.updateProfile(updateUserModel, _pickedFile, token);
    if (!fromVerification) {
      _updateProfileResponseHandle(responseModel, updateUserModel, token);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> _updateProfileResponseHandle(ResponseModel responseModel, UpdateUserModel updateUserModel, String token) async {
    updateUserModel.verificationOn = responseModel.updateProfileResponseModel?.verificationOn;
    updateUserModel.verificationMedium = responseModel.updateProfileResponseModel?.verificationMedium;

    if (responseModel.isSuccess &&
        responseModel.updateProfileResponseModel != null &&
        responseModel.updateProfileResponseModel!.verificationOn != null &&
        responseModel.updateProfileResponseModel!.verificationOn! == 'phone') {
      if (responseModel.updateProfileResponseModel!.verificationMedium! == 'firebase') {
        Get.find<AuthController>()
            .firebaseVerifyPhoneNumber(updateUserModel.phone!, token, '', fromSignUp: false, updateUserModel: updateUserModel);
      } else {
        if (Get.isDialogOpen!) {
          Get.back<void>();
        }
        if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
          Get.dialog<void>(VerificationScreen(
            number: updateUserModel.phone!,
            token: '',
            fromSignUp: false,
            fromForgetPassword: false,
            loginType: '',
            password: '',
            userModel: updateUserModel,
          ));
        } else {
          Get.toNamed<void>(
              RouteHelper.getVerificationRoute(updateUserModel.phone!, null, '', '', null, '', updateUserModel: updateUserModel));
        }
      }
    } else if (responseModel.isSuccess &&
        responseModel.updateProfileResponseModel != null &&
        responseModel.updateProfileResponseModel!.verificationOn != null &&
        responseModel.updateProfileResponseModel!.verificationOn! == 'email') {
      if (Get.isDialogOpen!) {
        Get.back<void>();
      }
      if (Get.context != null && ResponsiveHelper.isDesktop(Get.context!)) {
        Get.dialog<void>(VerificationScreen(
          number: null,
          email: updateUserModel.email!,
          token: '',
          fromSignUp: false,
          fromForgetPassword: false,
          loginType: '',
          password: '',
          userModel: updateUserModel,
        ));
      } else {
        Get.toNamed<void>(
            RouteHelper.getVerificationRoute(null, updateUserModel.email!, '', '', null, '', updateUserModel: updateUserModel));
      }
    } else if (responseModel.isSuccess && responseModel.updateProfileResponseModel == null) {
      if (Get.isDialogOpen!) {
        Get.back<void>();
      }
      await getUserInfo();
      if (Get.context == null || !ResponsiveHelper.isDesktop(Get.context!)) {
        Get.back<void>();
        Get.back<void>();
      }
      _pickedFile = null;
      showCustomSnackBar(responseModel.message, isError: false);
    } else if (!responseModel.isSuccess && responseModel.updateProfileResponseModel != null) {
      if (Get.isDialogOpen!) {
        Get.back<void>();
      }
      showCustomSnackBar(responseModel.updateProfileResponseModel!.message);
    } else {
      if (Get.isDialogOpen!) {
        Get.back<void>();
      }
      showCustomSnackBar(responseModel.message);
    }
  }

  Future<ResponseModel> changePassword(UserInfoModel updatedUserModel) async {
    _isLoading = true;
    update();
    final ResponseModel responseModel = await profileServiceInterface.changePassword(updatedUserModel);
    _isLoading = false;
    update();
    return responseModel;
  }

  void updateUserWithNewData(User? user) {
    _userInfoModel!.userInfo = user;
  }

  void pickImage() async {
    _pickedFile = await profileServiceInterface.pickImageFromGallery();
    _originalPickedFile = _pickedFile;
    _avatarCleared = false;
    update();
  }

  /// Sets the profile avatar to an externally-produced file (e.g. camera +
  /// crop flow). Raw pick, so it also becomes [originalPickedFile].
  void setPickedFile(XFile file) {
    _pickedFile = file;
    _originalPickedFile = file;
    _avatarCleared = false;
    update();
  }

  /// Sets only the framed (zoomed/cropped) preview, keeping
  /// [originalPickedFile] intact so the zoom stays reversible.
  void setFramedFile(XFile file) {
    _pickedFile = file;
    _avatarCleared = false;
    update();
  }

  /// Removes the currently chosen/shown avatar (local preview only).
  void removePickedFile() {
    _pickedFile = null;
    _originalPickedFile = null;
    _avatarCleared = true;
    update();
  }

  void initData({bool isUpdate = false}) {
    _pickedFile = null;
    _originalPickedFile = null;
    _avatarCleared = false;
    if (isUpdate) {
      update();
    }
  }

  Future<void> deleteUser(
    BuildContext context,
  ) async {
    _isLoading = true;
    update();
    final Response<dynamic> response = await profileServiceInterface.deleteUser();
    _isLoading = false;
    if (response.statusCode == 200 || response.statusCode == 203) {
      await Get.find<AuthController>().clearSharedData(removeToken: false);
      await Get.find<AuthController>().clearUserNumberAndPassword();
      await Get.find<CartController>().clearCartList();
      if (Get.find<AuthController>().isActiveRememberMe) {
        Get.find<AuthController>().toggleRememberMe();
      }
      Get.find<FavouriteController>().removeFavourite();
      setForceFullyUserEmpty();
      showCustomSnackBar('your_account_remove_successfully'.tr, isError: false);
      _isLoading = false;
      if (!context.mounted) {
        return;
      }
      Get.find<LocationController>().navigateToLocationScreen(context, 'splash', offNamed: true);
    } else {
      _isLoading = false;
      Get.back<void>();
    }
    update();
  }

  void clearUserInfo() {
    _userInfoModel = null;
    update();
  }
}
