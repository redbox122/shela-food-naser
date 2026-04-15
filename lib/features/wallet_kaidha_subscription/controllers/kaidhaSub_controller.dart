
import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/contract_pdf_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/kaidhaSub_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/nafath_checkStatus_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/nafath_random_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/wallet_kaidha_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/services/kaidhaSub_service_interface.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
import 'package:sixam_mart/features/payment/domain/services/myfatoorah_service.dart';
import 'package:sixam_mart/features/payment/domain/repositories/myfatoorah_repository.dart';
import 'package:sixam_mart/features/payment/domain/utils/myfatoorah_mapper.dart';
import 'package:sixam_mart/features/payment/screens/myfatoorah_payment_webview_screen.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/common/exceptions/validation_exception.dart';
import 'dart:io';

class KaidhaSubscriptionController extends GetxController
    implements GetxService {
  final kaidhaSub_ServiceInterface kaidhaSubServiceInterface;
  KaidhaSubscriptionController({required this.kaidhaSubServiceInterface});

  // Performance optimization variables
  Timer? _saveTimer;
  Timer? _apiTimer;
  SharedPreferences? _prefs;
  Map<String, dynamic>? _lastSavedData;
  static const Duration _saveDebounceDelay = Duration(milliseconds: 500);
  static const Duration _apiDebounceDelay = Duration(milliseconds: 1000);

  // Nafath request caching
  NafathRandomModel? _cachedNafathRequest;
  String? _cachedNationalId;
  String? _cachedNafathRandomCode;
  static const String _nafathCacheKey = 'nafath_request_cache';

  GlobalKey<FormState> formstate = GlobalKey<FormState>();

  WalletKaidhaModel? walletKaidhaModel;
  bool paymentMethodIndex = false;

  ContractPdfModel? contract_Pdf_Model;

  bool submit = false;

  // Qidha Wallet Payment Method Selection
  MFPaymentMethod? selectedQidhaPaymentMethod;
  List<MFPaymentMethod> qidhaPaymentMethods = [];
  List<bool> qidhaPaymentMethodsSelected = [];
  bool isLoadingPaymentMethods = false;

  // Qidha Wallet Payment Amount Selection
  // 0 = Full Amount, 1 = Minimum Due, 2 = Custom Amount
  int selectedPaymentOption = 0;

  //

  TextEditingController firstname = TextEditingController();
  TextEditingController fathername = TextEditingController();
  TextEditingController grandfathername = TextEditingController();
  TextEditingController last_name = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  String birthDate = '';
  String nationality = '';
  String marital_status = '';

  TextEditingController number_of_family_members = TextEditingController();
  TextEditingController identity_card_number = TextEditingController();
  String end_date = '';

  String house_type = '';
  String city = '';
  TextEditingController neighborhood = TextEditingController();

  TextEditingController name_of_employer = TextEditingController();
  TextEditingController total_salary = TextEditingController();
  String Installments = '';

  TextEditingController monthlyIncome = TextEditingController();
  TextEditingController salary_day = TextEditingController();

  // ===================================================================================================================

  final FocusNode firstNameFocus = FocusNode();
  final FocusNode fatherNameFocus = FocusNode();
  final FocusNode grandFatherNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode numberOfFamilyFocus = FocusNode();
  final FocusNode identityCardFocus = FocusNode();
  final FocusNode neighborhoodFocus = FocusNode();
  final FocusNode employerFocus = FocusNode();
  final FocusNode totalSalaryFocus = FocusNode();
  final FocusNode birthDateFocus = FocusNode();
  final FocusNode nationalityFocus = FocusNode();
  final FocusNode maritalStatusFocus = FocusNode();
  final FocusNode endDateFocus = FocusNode();
  final FocusNode salaryDayFocus = FocusNode();
  final FocusNode monthlyIncomeFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();

  //

  bool isFirstNameEmpty = false;
  bool isFatherNameEmpty = false;
  bool isGrandFatherNameEmpty = false;
  bool isLastNameEmpty = false;
  bool isPhoneEmpty = false;
  bool isNumberOfFamilyEmpty = false;
  bool isIdentityCardEmpty = false;
  bool isNeighborhoodEmpty = false;
  bool isEmployerEmpty = false;
  bool isTotalSalaryEmpty = false;
  bool isBirthDateEmpty = false;
  bool isNationalityEmpty = false;
  bool isMaritalStatusEmpty = false;
  bool isEndDateEmpty = false;
  bool isSalaryDayEmpty = false;
  bool isMonthlyIncomeEmpty = false;
  final Map<String, String> fieldErrors = {};

  // 2. نعدل دالة التحقق

  static final GlobalKey nationalityKey = GlobalKey();
  static final GlobalKey birthDateKey = GlobalKey();
  static final GlobalKey numberKey = GlobalKey();
  static final GlobalKey identityCardKey = GlobalKey();
  static final GlobalKey numberOfFamilyKey = GlobalKey();
  static final GlobalKey totalSalaryKey = GlobalKey();
  static final GlobalKey endDateKey = GlobalKey();
  final GlobalKey salaryDayKey = GlobalKey();
  final GlobalKey monthlyIncomeKey = GlobalKey();
  static final GlobalKey phoneKey = GlobalKey();

  // =================================================================================================================
  String date = '';

  String jobSpecification = '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool isLoading_wallet = false;
  bool hasWalletError =
      false; // 🔧 FIX: Track wallet API errors (401, 500, etc.)
  String? walletErrorMessage; // Optional error message
  bool hasNoWallet =
      false; // 🔧 FIX: Track when user has no wallet (wallet: null from API)

  bool get isCompleted => currentStage >= 4;

  int _currentStage = 1;
  int get currentStage => _currentStage;

  TextEditingController imgName_Controller = TextEditingController();
  List<NamedFile> All_files = [];

  int maxFiles = 5;

  TextEditingController another_amount = TextEditingController();

  bool _isLoading_Show_Pdf = false;
  bool get isLoading_Show_Pdf => _isLoading_Show_Pdf;

  NafathCheckStatusModel? _nafath_checkStatus;
  NafathCheckStatusModel? get nafath_checkStatus => _nafath_checkStatus;
  String? _lastNafathStatus;
  String? _nafathFailReason;
  DateTime? _nafathRequestCreatedAt;
  String? _nafathFullNameAr;
  String? _nafathSignedFileUrl;

  NafathRandomModel? _nafath_national_id;
  NafathRandomModel? get nafath_national_id => _nafath_national_id;

  bool _isLoading_OTP = false;
  bool get isLoading_OTP => _isLoading_OTP;

  bool _isLoading_Status = false;
  bool get isLoading_Status => _isLoading_Status;

  bool _isShow = false;
  bool get isShow => _isShow;

  // =====================================================================================

  /// Maps job specification values from UI to server-expected values
  String _mapJobSpecificationToServerValue(String jobSpec) {
    switch (jobSpec) {
      case 'government employee':
        return 'government';
      case 'private sector employee':
        return 'private_sector';
      case 'self-employed':
        return 'freelance_work';
      case 'retired':
        return 'retired';
      default:
        return 'government'; // Default fallback
    }
  }

  void update_isShow() {
    _isShow = false;
    update();
  }

  void updatejobSpecification(String newjobSpecification) {
    jobSpecification = newjobSpecification;
    _scheduleUpdate();
  }

  bool _updateScheduled = false;
  void _scheduleUpdate() {
    // Avoid triggering rebuilds during pointer/mouse device updates.
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      update();
    });
  }

  void setFieldErrors(Map<String, String> errors) {
    fieldErrors
      ..clear()
      ..addAll(errors);
    _scheduleUpdate();
  }

  void clearFieldErrors() {
    if (fieldErrors.isNotEmpty) {
      fieldErrors.clear();
      _scheduleUpdate();
    }
  }

  void clearFieldError(String key) {
    if (fieldErrors.containsKey(key)) {
      fieldErrors.remove(key);
      _scheduleUpdate();
    }
  }

  void updateInstallments(String newinstallments) {
    Installments = newinstallments;
    _scheduleUpdate();
  }

  void updateMaritalStatus(String newStatus) {
    marital_status = newStatus;
    _scheduleUpdate();
  }

  void updateNationality(String newNationality) {
    nationality = newNationality;
    isNationalityEmpty = false;
    _scheduleUpdate();
  }

  void updateCity(String updatecity) {
    city = updatecity;
    _scheduleUpdate();
  }

  void updateHousetype(String newhousetype) {
    house_type = newhousetype;
    _scheduleUpdate();
  }

  void updateBirthDate(String newDate) {
    birthDate = newDate;
    update();
  }

  void updateExpirationDate(String newexpirationDate) {
    end_date = newexpirationDate;
    update();
  }

  set isLoading(bool value) {
    _isLoading = value;
    update();
  }

  void nextStage(BuildContext context, {bool isNext = true}) {
    if (isNext) {
      if (_currentStage < 3) {
        _currentStage++;
        update();
      }
    } else {
      if (_currentStage > 1) {
        _currentStage--;
        update();
      }
    }
  }

  void backStage() {
    _currentStage = 1;
    update();
  }

  // =====

  /// Select payment option (0=Full, 1=Minimum, 2=Custom)
  /// Only updates the selection, does NOT reload payment methods
  void selectPaymentOption(int option) {
    selectedPaymentOption = option;
    update();
  }

  /// Get the amount based on selected payment option
  double getSelectedPaymentAmount() {
    if (walletKaidhaModel?.wallet == null) return 0.0;

    if (selectedPaymentOption == 0) {
      // Full Amount
      return double.tryParse(
              walletKaidhaModel!.wallet!.usedBalance?.toString() ?? '0') ??
          0.0;
    } else if (selectedPaymentOption == 1) {
      // Minimum Due
      return double.tryParse(
              walletKaidhaModel!.wallet!.minimumDueLimit?.toString() ?? '0') ??
          0.0;
    } else {
      // Custom Amount
      return double.tryParse(another_amount.text) ?? 0.0;
    }
  }

  void onChange_another_amount(String amount) {
    // Get the full due amount from wallet
    final double fullDueAmount = double.tryParse(
            walletKaidhaModel?.wallet?.usedBalance?.toString() ?? '0') ??
        0.0;

    // Parse the entered amount
    final double enteredAmount = double.tryParse(amount) ?? 0.0;

    // If there's no due amount (0), clear the input
    if (fullDueAmount == 0) {
      if (enteredAmount > 0) {
        another_amount.text = '';
        showCustomSnackBar('لا يوجد مبلغ مستحق للدفع');
      } else {
        another_amount.text = amount;
      }
    }
    // If entered amount exceeds full due amount, cap it (REAL-TIME)
    else if (enteredAmount > fullDueAmount) {
      another_amount.text = fullDueAmount.toStringAsFixed(2);
      showCustomSnackBar(
          'تم تحديد المبلغ إلى الحد الأقصى المسموح: ${fullDueAmount.toStringAsFixed(2)} ريال',
          isError: false);
    } else {
      another_amount.text = amount;
    }

    // Switch to custom payment option when user types
    if (enteredAmount > 0 && selectedPaymentOption != 2) {
      selectedPaymentOption = 2;
    }

    update();
  }

  /// Validate minimum amount when field loses focus
  /// Called on blur - allows user to type freely without interruption
  void validateMinimumAmount() {
    // Get minimum due amount from wallet
    final double minimumDue = double.tryParse(
            walletKaidhaModel?.wallet?.minimumDueLimit?.toString() ?? '0') ??
        0.0;

    // Get full due amount
        0.0;

    // Parse the entered amount
    final double enteredAmount = double.tryParse(another_amount.text) ?? 0.0;

    // Only validate if there's an entered amount and minimum is set
    if (enteredAmount > 0 && minimumDue > 0) {
      // If amount is less than minimum, cap it to minimum
      if (enteredAmount < minimumDue) {
        another_amount.text = minimumDue.toStringAsFixed(2);
        another_amount.selection = TextSelection.fromPosition(
          TextPosition(offset: another_amount.text.length),
        );
        showCustomSnackBar(
            'تم تحديد المبلغ إلى الحد الأدنى المسموح: ${minimumDue.toStringAsFixed(2)} ريال',
            isError: false);
        update();
      }
    }
  }

  // Nafath   dialog    ================================================================================================

  Future onChange_dialog(BuildContext context, String nationalId) async {
    //

    Get.dialog(
      barrierDismissible: false,
      ConfirmationDialog(
        icon: Images.warning,
        title: 'هل قمت بالمصادقة داخل تطبيق نفاذ ؟',
        description: 'هذه مرحه تحقق هل تم تأكيد الكود بنجاح أم لا ',
        onYesPressed: () async {
          //
          Get.back();
          await Nafath_send_checkStatus(context, nationalId);
        },
      ),
    );
  }

  // Status  ==========

  Future<NafathCheckStatusModel?> Nafath_send_checkStatus(
      BuildContext context, String nationalId,
      {bool silent = false, bool allowAutoRetry = true}) async {
    if (!silent) {
      _isLoading_Status = true;
      update();
    }

    final onValue = await kaidhaSubServiceInterface.Nafath_send_checkStatus(
        context, nationalId);
    if (!context.mounted) {
      return null;
    }

    if (onValue != null) {
      _nafath_checkStatus = onValue;
      _nafathFailReason = onValue.failReason;
      _nafathRequestCreatedAt =
          _parseServerDate(onValue.createdAt) ?? _nafathRequestCreatedAt;
      _nafathFullNameAr = onValue.fullNameAr ?? _nafathFullNameAr;
      _nafathSignedFileUrl =
          onValue.signedFileUrl?.toString() ?? _nafathSignedFileUrl;
      final String? currentStatus = onValue.status;
      final bool statusChanged = _lastNafathStatus != currentStatus;
      _lastNafathStatus = currentStatus;
      final String randomCode = getNafathDisplayCode();
      debugPrint(
          'Nafath checkStatus: status=$currentStatus, request_id=${onValue.requestId}, random=$randomCode, created_at=${onValue.createdAt}, silent=$silent, at=${DateTime.now().toIso8601String()}');
      debugPrint(
          'Parsed Nafath: status=${onValue.status}, requestId=${onValue.requestId}, random=${onValue.random}');

      await _updateNafathCacheFromCheckStatus(onValue, nationalId);

      if (onValue.status == 'approved') {
        debugPrint('\x1B[32m  /${onValue.status}  \x1B[0m');

        _isShow = true;
        update();

        // Clear cache since verification is complete
        await _clearNafathRequestCache();
        if (!context.mounted) {
          return null;
        }

        // Proceed to contract signing immediately after Nafath approval
        if (!silent && statusChanged) {
          showCustomSnackBar('لقد تم تحقق المصادقة بنجاح', isError: false);
        }

        await Nafath_send_All_Data(
          context,
          identity_card_number.text,
          city,
          neighborhood.text,
          house_type,
        ).then((onValue) async {
          if (!context.mounted) {
            return;
          }
          debugPrint(
              '\x1B[32m  Contract Signing API Call   ${onValue?.statusCode}  \x1B[0m');

          if (onValue != null &&
              (onValue.statusCode == 200 ||
                  onValue.statusCode == 201 ||
                  onValue.statusCode == 302)) {
            // Navigate directly to waiting screen
            showCustomSnackBar('wallet_created_success'.tr, isError: false);
            Get.toNamed(RouteHelper.getKiadaWalletSubscription());
          } else if (onValue?.statusCode == 404) {
            showCustomSnackBar('try_again_later'.tr);
          } else {
            showCustomSnackBar('wallet_creation_error'.tr);
          }
        });
      } else if (onValue.status == 'rejected') {
        _nafath_checkStatus = NafathCheckStatusModel(
          status: 'rejected',
          requestId: onValue.requestId,
          nationalId: onValue.nationalId,
          createdAt: onValue.createdAt,
          random: onValue.random,
          failReason: onValue.failReason ?? 'rejected',
          fullNameAr: onValue.fullNameAr,
          signedFileUrl: onValue.signedFileUrl,
        );
        _isShow = false;
        update();

        if (!context.mounted) {
          return null;
        }
        if (!silent && statusChanged) {
          showCustomSnackBar('تم رفض طلب التحقق من نفاذ.');
        }
      } else if (onValue.status == 'expired') {
        _nafath_checkStatus = NafathCheckStatusModel(
          status: 'expired',
          requestId: onValue.requestId,
          nationalId: onValue.nationalId,
          createdAt: onValue.createdAt,
          random: onValue.random,
          failReason: onValue.failReason ?? 'expired',
          fullNameAr: onValue.fullNameAr,
          signedFileUrl: onValue.signedFileUrl,
        );
        _isShow = false;
        update();
        if (!silent && statusChanged) {
          showCustomSnackBar('انتهت صلاحية طلب نفاذ.');
        }
      } else if (onValue.status == 'cancelled' ||
          onValue.status == 'no_request') {
        _nafath_checkStatus = NafathCheckStatusModel(
          status: onValue.status,
          requestId: onValue.requestId,
          nationalId: onValue.nationalId,
          createdAt: onValue.createdAt,
          random: onValue.random,
          failReason: onValue.failReason ?? onValue.status,
          fullNameAr: onValue.fullNameAr,
          signedFileUrl: onValue.signedFileUrl,
        );
        _isShow = false;
        update();
      } else {
        // pending
        debugPrint('⏳ Nafath verification pending: ${onValue.status}');
        _nafath_checkStatus = NafathCheckStatusModel(
          status: 'pending',
          requestId: onValue.requestId,
          nationalId: onValue.nationalId,
          createdAt: onValue.createdAt,
          random: onValue.random,
          fullNameAr: onValue.fullNameAr,
          signedFileUrl: onValue.signedFileUrl,
        );
        _isShow = false;
        update();
        if (!silent && statusChanged) {
          showCustomSnackBar('يرجى إكمال التحقق في تطبيق نفاذ');
        }
      }
    } else {
      _isShow = false;
      update();
      if (!silent) {
        showCustomSnackBar('حدث خطأ أثناء التحقق من المصادقة');
      }
    }

    _isLoading_Status = false;

    if (!silent) {
      update();
    }
    return _nafath_checkStatus;
  }

  // send National Id  OTP  ==========

  Future<NafathRandomModel?> Nafath_send_National_Id(
      BuildContext context, String nationalId,
      {bool forceNew = false}) async {
    // Only use cached data if we're not forcing a new request
    if (!forceNew &&
        _cachedNafathRequest != null &&
        _cachedNationalId == nationalId) {
      debugPrint('🔄 Using cached Nafath request for national ID: $nationalId');
      _nafath_national_id = _cachedNafathRequest;
      _isLoading_OTP = false;
      update();
      return _cachedNafathRequest;
    }

    debugPrint('🚀 Initiating new Nafath request for national ID: $nationalId');
    _nafath_national_id = null;
    _isLoading_OTP = true;
    update();

    _nafath_national_id =
        await kaidhaSubServiceInterface.Nafath_send_National_Id(
            context, nationalId);
    if (!context.mounted) {
      _isLoading_OTP = false;
      update();
      return null;
    }

    // Cache the request if it was successful
    if (_nafath_national_id != null) {
      _cachedNafathRequest = _nafath_national_id;
      _cachedNationalId = nationalId;
      _cachedNafathRandomCode = _nafath_national_id!.code;
      _nafathRequestCreatedAt =
          _parseServerDate(_nafath_national_id!.createdAt) ?? DateTime.now();
      _nafath_checkStatus = NafathCheckStatusModel(
        status: 'pending',
        requestId: _nafath_national_id!.requestId,
        nationalId: nationalId,
        createdAt: _nafath_national_id!.createdAt,
        random: int.tryParse(_nafath_national_id!.code ?? ''),
      );
      await _saveNafathRequestToCache();
      debugPrint('✅ New Nafath request cached for national ID: $nationalId');
    } else {
      // initiate failed (e.g. request already approved). Ask server state and
      // continue from source of truth instead of crashing or looping.
      final NafathCheckStatusModel? statusModel = await Nafath_send_checkStatus(
        context,
        nationalId,
        silent: true,
        allowAutoRetry: false,
      );
      if (!context.mounted) {
        _isLoading_OTP = false;
        update();
        return null;
      }
      if (statusModel != null) {
        _nafath_checkStatus = statusModel;
        _lastNafathStatus = statusModel.status;
        _nafathRequestCreatedAt =
            _parseServerDate(statusModel.createdAt) ?? _nafathRequestCreatedAt;

        if (statusModel.status == 'pending') {
          _cachedNationalId = nationalId;
          _cachedNafathRandomCode = statusModel.random?.toString();
          _nafathRequestCreatedAt =
              _parseServerDate(statusModel.createdAt) ?? DateTime.now();
        }
      }
    }

    _isLoading_OTP = false;
    update();
    return _nafath_national_id;
  }

  // send All  Data   =============

  Future<Response?> Nafath_send_All_Data(
    BuildContext context,
    String national_id,
    String city,
    String neighborhood,
    String house_type,
  ) async {
    _isLoading = true;
    update();

    debugPrint('\x1B[32m  /$national_id  \x1B[0m');
    debugPrint('\x1B[32m city /$city  \x1B[0m');
    debugPrint('\x1B[32m  neighborhood/ $neighborhood  \x1B[0m');
    debugPrint('\x1B[32m  house_type/ $house_type  \x1B[0m');

    try {
      if (!await _ensureMobileReady()) {
        _isLoading = false;
        update();
        return null;
      }
      // Create KaidhaSubModel from current form data
      final KaidhaSubModel kaidhaSub = KaidhaSubModel(
        first_name: firstname.text,
        father_name: fathername.text,
        grandfather_name: grandfathername.text,
        last_name: last_name.text,
        birth_date: birthDate,
        national_id: identity_card_number.text,
        nationality: nationality,
        marital_status: marital_status,
        number_of_family_members: _getFamilyMembersCount(),
        identity_card_number: identity_card_number.text,
        end_date: end_date,
        mobile: _getUserPhoneForForm(),
        house_type: house_type.isNotEmpty ? house_type : 'apartment',
        city: city.isNotEmpty ? city : 'الرياض',
        neighborhood: this.neighborhood.text,
        name_of_employer: name_of_employer.text,
        total_salary: total_salary.text,
        installments: Installments,
        source_of_income: _mapJobSpecificationToServerValue(jobSpecification),
        monthly_amount: monthlyIncome.text,
        salary_day: salary_day.text.isNotEmpty ? salary_day.text : '2',
      );

      // STEP 1: Final Nafath Verification
      debugPrint('🔄 Step 3 Phase 1: Final Nafath Verification');
      if (!context.mounted) {
        _isLoading = false;
        update();
        return null;
      }
      final Response response1 =
          await kaidhaSubServiceInterface.Nafath_send_All_Data(
              context,
              national_id,
              city,
              neighborhood,
              house_type,
              kaidhaSub,
              All_files);

      if (response1.statusCode != 200 &&
          response1.statusCode != 201 &&
          response1.statusCode != 302) {
        debugPrint('❌ Step 3 Phase 1 failed: ${response1.statusCode}');
        _isLoading = false;
        update();
        return response1;
      }

      // STEP 2: Update Signature Status to 1 (signed)
      debugPrint('🔄 Step 3 Phase 2: Updating signature status to 1');
      final userInfo = Get.find<ProfileController>().userInfoModel;
      if (userInfo?.id != null) {
        final Map<String, dynamic> savedData =
            await getState_kaidha_SharedPre();
        await kaidhaSubServiceInterface.SendState_kaidha(
            userInfo!.id!, 'approved', savedData);
      }

      debugPrint('✅ Step 3 completed: Signature status updated to 1');

      // Refresh wallet data after successful signature update
      await get_Wallet_Kaidh(forceRefresh: true);

      // Navigate to pending approval screen
      debugPrint('🔄 Navigating to pending approval screen...');
      Get.toNamed(RouteHelper.getKiadaWalletSubscription());

      _isLoading = false;
      update();
      return response1; // Return the first response for UI handling
    } catch (e) {
      debugPrint('❌ Error in Nafath_send_All_Data: $e');
      _isLoading = false;
      update();
      return null;
    } finally {
      _nafath_checkStatus = null;
      _isLoading = false;
      update();
    }
  }

  //   =====================================================================================================

  void pickFileWithName(BuildContext context) async {
    if (imgName_Controller.text.trim().isEmpty) {
      showCustomSnackBar('يرجى إدخال الاسم');

      return;
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      All_files.add(NamedFile(
          name: imgName_Controller.text.trim(), file: result.files.first));
      update();
    }

    imgName_Controller.clear();
  }

  void removeFile(int index) {
    All_files.removeAt(index);
    update();
  }

//  ----------------------------------------------------------------------------

  /// ⚡ PERFORMANCE: Set wallet state from login response (minimal data for instant menu rendering)
  /// Called by AuthService when login response includes wallet flags
  void setWalletStateFromLogin({
    required bool signed,
    required bool active,
    String? balance,
  }) {
    debugPrint(
        '💳 KaidhaSubscriptionController: Setting wallet state from login response...');
    debugPrint('   - Signed: $signed');
    debugPrint('   - Active: $active');
    debugPrint('   - Balance: ${balance ?? 'null'}');

    // Create minimal wallet model from login response flags
    // This allows menu screen to render wallet buttons immediately without API call
    if (signed && active && balance != null) {
      debugPrint(
          '✅ KaidhaSubscriptionController: Wallet is signed and active - creating minimal wallet model');
      // Convert balance string to double for consistency with API response (API returns double)
      final double? balanceValue = double.tryParse(balance);
      // ⚡ TASK 2: Default creditLimit to 5000.0 if qidha_wallet_balance exists
      const double defaultCreditLimit = 5000.0;
      // Create minimal wallet object with just the data needed for menu display
      // All fields are required by Wallet constructor, but we only need balance, status, and signatureStatus
      walletKaidhaModel = WalletKaidhaModel(
        message: 'Wallet loaded from login',
        hasWallet: true,
        wallet: Wallet(
          id: 0, // Placeholder - not used for menu display
          serialNumber: '',
          userId: 0,
          createdAt: '',
          updatedAt: '',
          completedAt: '',
          completedBy: 0,
          creditLimit:
              defaultCreditLimit, // ⚡ TASK 2: Default to 5000.0 for instant display
          minimumDue: '',
          availableBalance:
              balanceValue, // Key field for menu display - converted to double to match API
          usedBalance:
              null, // ⚡ TASK 1: Use null to represent "No Data", not truthy empty string
          usagePercentageLimit: '',
          status: 'Active',
          autoLockDay: '',
          manualUnlockExpiryDate: '',
          usagePercentageLimitByMonthly: '',
          signaturePath: '',
          signatureStatus: 1, // Signed - key field for menu logic
          lockDay: '',
          minimumDueLimit:
              null, // ⚡ TASK 1: Use null to represent "No Data", not truthy empty string
          purchaseLimit: '',
          usedPercentage: '',
          totalAvilableBalance: '',
        ),
      );
      hasWalletError = false;
      hasNoWallet = false;
      isLoading_wallet = false;
      debugPrint(
          '✅ KaidhaSubscriptionController: Wallet state set - menu can show Qidha Wallet button immediately');
    } else {
      // Wallet exists but not signed/active - set flags for menu logic
      debugPrint(
          'ℹ️ KaidhaSubscriptionController: Wallet exists but not signed/active - menu will show subscription button');
      walletKaidhaModel = null; // Menu will show subscription button
      hasWalletError = false;
      hasNoWallet = false; // Wallet exists, just not active
      isLoading_wallet = false;
    }
    update();
    debugPrint(
        '✅ KaidhaSubscriptionController: Wallet state updated - UI notified');
  }

  Future get_Wallet_Kaidh({bool forceRefresh = false}) async {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint(
          '💳 [KaidhaSubscriptionController] get_Wallet_Kaidh() called');
      debugPrint('   🔄 forceRefresh: $forceRefresh');
      debugPrint('   ⏰ Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('═══════════════════════════════════════════════════════════');
    }

    // Preserve existing wallet state if already set (from login response)
    final existingWallet = walletKaidhaModel;
    final bool hadExistingWallet = existingWallet != null;

    if (kDebugMode) {
      debugPrint('💳 [KaidhaSubscriptionController] Current wallet state:');
      debugPrint('   📊 hadExistingWallet: $hadExistingWallet');
      if (hadExistingWallet) {
        debugPrint('   💰 Status: ${existingWallet.wallet?.status}');
        debugPrint(
            '   💵 availableBalance: ${existingWallet.wallet?.availableBalance}');
        debugPrint('   💵 usedBalance: ${existingWallet.wallet?.usedBalance}');
        debugPrint(
            '   💵 minimumDueLimit: ${existingWallet.wallet?.minimumDueLimit}');
        debugPrint(
            '   📝 signatureStatus: ${existingWallet.wallet?.signatureStatus}');
      }
    }

    // ⚡ TASK 2: Hardened bypass logic - only skip API call if we have FULL wallet data
    // Must have creditLimit, usedBalance, and minimumDueLimit all as valid numbers
    final creditLimit = existingWallet?.wallet?.creditLimit;
    final usedBalance = existingWallet?.wallet?.usedBalance;
    final minimumDueLimit = existingWallet?.wallet?.minimumDueLimit;

    // Validate usedBalance is a valid number (not null, not empty string, parseable as number)
    final hasValidUsedBalance = usedBalance != null &&
        usedBalance.toString().trim().isNotEmpty &&
        (usedBalance is num || double.tryParse(usedBalance.toString()) != null);

    // Validate minimumDueLimit is a valid number
    final hasValidMinimumDueLimit = minimumDueLimit != null &&
        minimumDueLimit.toString().trim().isNotEmpty &&
        (minimumDueLimit is num ||
            double.tryParse(minimumDueLimit.toString()) != null);

    final hasFullWalletData = hadExistingWallet &&
        creditLimit != null &&
        creditLimit.toString().trim().isNotEmpty &&
        hasValidUsedBalance &&
        hasValidMinimumDueLimit;

    if (!forceRefresh && hasFullWalletData) {
      if (kDebugMode) {
        debugPrint(
            '💳 [KaidhaSubscriptionController] ⏭️ Full wallet data already set - skipping API call');
        debugPrint('   💡 Use forceRefresh: true to override');
        debugPrint('   💰 Wallet Status: ${existingWallet.wallet?.status}');
        debugPrint(
            '   💵 Wallet Balance: ${existingWallet.wallet?.availableBalance}');
        debugPrint('   💵 Credit Limit: ${existingWallet.wallet?.creditLimit}');
      }
      return; // Don't overwrite existing state
    }

    if (kDebugMode) {
      debugPrint(
          '💳 [KaidhaSubscriptionController] Starting wallet data fetch...');
      debugPrint('   📡 API: /api/v1/customer/wallet-kaidha');
      if (hadExistingWallet && !hasFullWalletData) {
        debugPrint(
            '   ⚡ Partial data exists (balance only) - fetching to get credit limit');
      }
    }

    // ⚡ FIX: Don't set loading state if we already have wallet data (prevents flicker)
    // Only set loading if we have no wallet data at all
    if (!hadExistingWallet) {
      isLoading_wallet = true;
      hasWalletError = false; // Reset error state
      hasNoWallet = false; // Reset no wallet state
      walletErrorMessage = null;
      update();
    } else {
      // We have partial data - update silently in background without showing loader
      if (kDebugMode) {
        debugPrint(
            '💳 [KaidhaSubscriptionController] ⚡ Background update - not setting loading state');
      }
    }

    try {
      final newWallet = await kaidhaSubServiceInterface.getWalletKaidh(
          forceRefresh: forceRefresh);

      if (kDebugMode) {
        debugPrint('💳 [KaidhaSubscriptionController] API response received');
        debugPrint('   📊 newWallet: ${newWallet != null ? "EXISTS" : "NULL"}');
      }

      // Only update if API returned data
      if (newWallet != null) {
        walletKaidhaModel = newWallet;
        // Debug wallet status
        if (walletKaidhaModel?.wallet != null) {
          // ⚡ TASK 3: Controller Hardening - Check if usedBalance is still null after fetch
          final usedBalance = walletKaidhaModel!.wallet!.usedBalance;
          final hasValidUsedBalance = usedBalance != null &&
              usedBalance.toString().trim().isNotEmpty &&
              (usedBalance is num ||
                  double.tryParse(usedBalance.toString()) != null);

          if (!hasValidUsedBalance) {
            // ⚡ TASK 3: Skeleton data still present - clear ETag and force refresh
            if (kDebugMode) {
              debugPrint(
                  '💳 [KaidhaSubscriptionController] ⚠️ Skeleton data detected after fetch - clearing ETag and retrying');
            }

            // Clear ETag and force refresh
            final cacheService = HiveHomeCacheService();
            await cacheService.clearEtag(AppConstants.get_walletUri);

            // Retry with force refresh
            final retryWallet = await kaidhaSubServiceInterface.getWalletKaidh(
                forceRefresh: true);
            if (retryWallet != null && retryWallet.wallet != null) {
              walletKaidhaModel = retryWallet;
              if (kDebugMode) {
                debugPrint(
                    '💳 [KaidhaSubscriptionController] ✅ Wallet hydrated after ETag clear');
              }
            }
          }

          if (kDebugMode) {
            debugPrint(
                '💳 [KaidhaSubscriptionController] ✅ Wallet loaded successfully');
            debugPrint('   💰 Status: ${walletKaidhaModel!.wallet!.status}');
            debugPrint('   🆔 Wallet ID: ${walletKaidhaModel!.wallet!.id}');
            debugPrint(
                '   💵 availableBalance: ${walletKaidhaModel!.wallet!.availableBalance}');
            debugPrint(
                '   💵 usedBalance: ${walletKaidhaModel!.wallet!.usedBalance}');
            debugPrint(
                '   💵 minimumDueLimit: ${walletKaidhaModel!.wallet!.minimumDueLimit}');
            debugPrint(
                '   💵 creditLimit: ${walletKaidhaModel!.wallet!.creditLimit}');
            debugPrint(
                '   📝 signatureStatus: ${walletKaidhaModel!.wallet!.signatureStatus}');
            debugPrint('   📅 lockDay: ${walletKaidhaModel!.wallet!.lockDay}');
          }
          hasWalletError = false; // Success - no error
          hasNoWallet = false; // User has wallet
        }
      } else if (!hadExistingWallet) {
        // API returned null AND wallet wasn't previously set - user has no wallet
        walletKaidhaModel = null;
        if (kDebugMode) {
          debugPrint(
              '💳 [KaidhaSubscriptionController] ℹ️ No wallet data found - user has no wallet');
        }
        hasWalletError = false;
        hasNoWallet = true;
      } else {
        // ⚡ TASK 3: Controller Hardening - Don't preserve skeleton state if fetch returns null
        // Check if existing wallet is skeleton data (missing critical fields)
        final existingUsedBalance = existingWallet.wallet?.usedBalance;
        final hasValidExistingData = existingUsedBalance != null &&
            existingUsedBalance.toString().trim().isNotEmpty &&
            (existingUsedBalance is num ||
                double.tryParse(existingUsedBalance.toString()) != null);

        if (hasValidExistingData) {
          // Valid existing data - preserve it
          walletKaidhaModel = existingWallet;
          if (kDebugMode) {
            debugPrint(
                '💳 [KaidhaSubscriptionController] ⚠️ API returned null but wallet has valid data - preserving');
            debugPrint(
                '   💰 Preserved Wallet Status: ${existingWallet.wallet?.status}');
            debugPrint(
                '   💵 Preserved Wallet Balance: ${existingWallet.wallet?.availableBalance}');
          }
          hasWalletError = false;
          hasNoWallet = false;
        } else {
          // ⚡ TASK 3: Skeleton data detected - clear it and show loading state
          // Better to show loading shimmer than permanent "0" balance
          walletKaidhaModel = null;
          if (kDebugMode) {
            debugPrint(
                '💳 [KaidhaSubscriptionController] ⚠️ API returned null and existing wallet is skeleton - clearing state');
            debugPrint('   💡 Will show loading state instead of broken UI');
          }
          hasWalletError = false;
          hasNoWallet = true; // Treat as "no wallet" to trigger proper UI state
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            '💳 [KaidhaSubscriptionController] ❌ Error fetching wallet');
        debugPrint('   📋 Error: $e');
        debugPrint('   📋 Stack trace: $stackTrace');
      }

      // On error, preserve existing wallet state if it existed
      if (hadExistingWallet) {
        walletKaidhaModel = existingWallet; // Restore existing state
        if (kDebugMode) {
          debugPrint(
              '💳 [KaidhaSubscriptionController] ⚠️ API error but wallet was already set');
          debugPrint('   💡 Preserving existing state');
          debugPrint(
              '   💰 Preserved Wallet Status: ${existingWallet.wallet?.status}');
        }
        hasWalletError = false; // Don't mark as error if we have existing state
        hasNoWallet = false;
        walletErrorMessage = null;
      } else {
        // No existing wallet - treat as error
        if (kDebugMode) {
          debugPrint(
              '💳 [KaidhaSubscriptionController] ❌ No existing wallet - marking as error');
        }
        hasWalletError = true;
        hasNoWallet = false; // Error is different from no wallet
        walletErrorMessage = e.toString();

        // Check if it's a specific HTTP error
        if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          walletErrorMessage = 'Unauthorized - Please login again';
          if (kDebugMode) {
            debugPrint(
                '💳 [KaidhaSubscriptionController] 🔐 401 Unauthorized error detected');
          }
        } else if (e.toString().contains('500') ||
            e.toString().contains('Internal Server Error')) {
          walletErrorMessage = 'Server error - Please try again later';
          if (kDebugMode) {
            debugPrint(
                '💳 [KaidhaSubscriptionController] 🔥 500 Server error detected');
          }
        }
      }
    }
    isLoading_wallet = false;
    update();

    if (kDebugMode) {
      debugPrint(
          '💳 [KaidhaSubscriptionController] get_Wallet_Kaidh() completed');
      debugPrint('   📊 isLoading_wallet: $isLoading_wallet');
      debugPrint('   ❌ hasWalletError: $hasWalletError');
      debugPrint('   📭 hasNoWallet: $hasNoWallet');
      debugPrint('═══════════════════════════════════════════════════════════');
    }
  }

  /// ⚡ TASK 2: Nuclear Remote Fetch - Bypasses all cache and ETags
  /// Forces a completely fresh download from server, ignoring all local state
  Future<void> nuclearRemoteFetch() async {
    if (kDebugMode) {
      debugPrint(
          '💳 [KaidhaSubscriptionController] 🚨 NUCLEAR FETCH: Bypassing all cache and ETags');
    }

    // Clear ETag first
    final cacheService = HiveHomeCacheService();
    await cacheService.clearEtag(AppConstants.get_walletUri);

    // Also clear in-memory cache
    walletKaidhaModel = null;

    // Set loading state
    isLoading_wallet = true;
    hasWalletError = false;
    hasNoWallet = false;
    walletErrorMessage = null;
    update();

    try {
      // Force fresh fetch with cache-busting headers
      final newWallet =
          await kaidhaSubServiceInterface.getWalletKaidh(forceRefresh: true);

      if (newWallet != null) {
        walletKaidhaModel = newWallet;
        hasWalletError = false;
        hasNoWallet = false;
        if (kDebugMode) {
          debugPrint(
              '💳 [KaidhaSubscriptionController] ✅ Nuclear fetch successful');
          debugPrint('   💰 Status: ${walletKaidhaModel!.wallet?.status}');
          debugPrint(
              '   💵 usedBalance: ${walletKaidhaModel!.wallet?.usedBalance}');
        }
      } else {
        walletKaidhaModel = null;
        hasWalletError = false;
        hasNoWallet = true;
        if (kDebugMode) {
          debugPrint(
              '💳 [KaidhaSubscriptionController] ⚠️ Nuclear fetch returned null - user has no wallet');
        }
      }
    } catch (e) {
      walletKaidhaModel = null;
      hasWalletError = true;
      hasNoWallet = false;
      walletErrorMessage = e.toString();
      if (kDebugMode) {
        debugPrint(
            '💳 [KaidhaSubscriptionController] ❌ Nuclear fetch failed: $e');
      }
    } finally {
      isLoading_wallet = false;
      update();
    }
  }

  // ---------------------------------------------------------------------------

  Future Submit_Store_Info(context) async {
    _isLoading_Status = true;
    update();

    if (!await _ensureMobileReady()) {
      _isLoading_Status = false;
      update();
      return false;
    }

    final existingWallet =
        await kaidhaSubServiceInterface.getWalletKaidh(forceRefresh: true);
    if (existingWallet?.wallet?.id != null) {
      debugPrint('?? Wallet already exists. Skipping create.');
      walletKaidhaModel = existingWallet;
      _isLoading_Status = false;
      update();
      return true;
    }


    final KaidhaSubModel kaidhaSub = KaidhaSubModel(
      first_name: firstname.text,
      father_name: fathername.text,
      grandfather_name: grandfathername.text,
      last_name: last_name.text,
      birth_date: birthDate,
      national_id: identity_card_number.text,
      nationality: nationality,
      marital_status: marital_status,
      number_of_family_members: _getFamilyMembersCount(),
      identity_card_number: identity_card_number.text,
      end_date: end_date,
      mobile: _getUserPhoneForForm(),

      house_type: house_type.isNotEmpty ? house_type : 'apartment',
      city: city.isNotEmpty ? city : 'damascus',
      neighborhood: neighborhood.text,

      name_of_employer: name_of_employer.text,
      total_salary: total_salary.text,
      installments: Installments,
      source_of_income: _mapJobSpecificationToServerValue(jobSpecification),

      monthly_amount: monthlyIncome.text,
      salary_day: salary_day.text.isNotEmpty ? salary_day.text : '2',

      // ------------------------------------------------------------

      //
    );

    debugPrint('\x1B[32m     Stor_info     \x1B[0m');

    await kaidhaSubServiceInterface.Stor_info(context, kaidhaSub, All_files)
        .then((value) async {
      //

      debugPrint('\x1B[32m     Submit_Store_Info  $value      \x1B[0m');

      if (value == true) {
        // Don't call backStage() - keep user in current flow
        // Don't clear form - user might need to see their data
        // Just refresh wallet data to show updated status
        await get_Wallet_Kaidh(forceRefresh: true);
        await get_Pdf();

        // Wait a moment for the UI to update with new wallet data
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to main subscription screen to show waiting for approval UI
        Get.toNamed(RouteHelper.getKiadaWalletSubscription());
      } else {
        debugPrint('\x1B[32m     Stor_info  Errorrrrrrrrrrrrrrr   \x1B[0m');
      }
    });

    _nafath_checkStatus = null;
    _isLoading_Status = false;
    _isShow = false;
    update();
  }

  //

  // Payment =================================================

  Future<bool> add_Payment(BuildContext context,
      CheckoutController checkoutController, double amount) async {
    //

    _isLoading = true;
    update();

    if (checkoutController.select_payment_Methods != null) {
      final bool isSuccess = await checkoutController.Pay(context, '$amount');

      // إعادة تعيين بعد الدفع
      if (isSuccess == true) {
        checkoutController.select_payment_Methods = null;

        update();
      }

      _isLoading = false;
      update();
      return isSuccess;
    } else {
      _isLoading = false;
      update();
      return false;
    }
  }

  // get_Pdf  ================================================

  Future<void> get_Pdf() async {
    _isLoading_Show_Pdf = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });

    try {
      // Don't call get_Wallet_Kaidh() here to avoid duplicate calls
      contract_Pdf_Model = await kaidhaSubServiceInterface.get_Pdf();
    } catch (e) {
      contract_Pdf_Model = null;
      debugPrint('خطأ في تحميل PDF: $e');
    } finally {
      _isLoading_Show_Pdf = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        update();
      });
    }
  }

  // Load Qidha Payment Methods =================================================

  String _getUserPhone() {
    final profilePhone =
        Get.find<ProfileController>().userInfoModel?.phone?.toString().trim();
    if (profilePhone != null && profilePhone.isNotEmpty) {
      return profilePhone;
    }
    if (Get.isRegistered<AuthController>()) {
      final authPhone = Get.find<AuthController>().getUserNumber().trim();
      if (authPhone.isNotEmpty) {
        return authPhone;
      }
    }
    return '';
  }

  String _getUserPhoneForForm() {
    final phone = phoneController.text.trim();
    if (phone.isNotEmpty) {
      return phone;
    }
    return _getUserPhone();
  }

  Future<bool> _ensureMobileReady() async {
    final profileController = Get.find<ProfileController>();
    if (profileController.userInfoModel == null) {
      await profileController.getUserInfo();
    }
    if (phoneController.text.trim().isEmpty) {
      final fallback = _getUserPhone();
      if (fallback.isNotEmpty) {
        phoneController.text = fallback.replaceAll(RegExp(r'\D'), '');
      }
    }
    if (_getUserPhoneForForm().isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
      return false;
    }
    return true;
  }

  String _getFamilyMembersCount() {
    final raw = number_of_family_members.text.trim();
    if (raw.isEmpty || raw == '0') {
      return '1';
    }
    return raw;
  }

  /// Load available payment methods for Qidha wallet credit payment
  /// Now uses backend endpoint instead of direct SDK call
  /// ⚡ CRITICAL: Always pass MAXIMUM due amount (usedBalance) to MyFatoorah
  /// This ensures payment methods support the full amount, even if user selects to pay less
  /// @param amount - The MAXIMUM amount that can be paid (should be usedBalance)
  Future<void> loadQidhaPaymentMethods(double amount) async {
    if (amount <= 0) {
      debugPrint('❌ Cannot load payment methods with amount: $amount');
      debugPrint(
          '   ⚠️ Amount must be > 0 (should be maximum due amount from wallet.usedBalance)');
      return;
    }

    isLoadingPaymentMethods = true;
    update();

    try {
      debugPrint(
          '🔄 Loading payment methods from backend for Qidha - MAXIMUM Amount: $amount SAR');
      debugPrint(
          '   ⚡ This is the maximum due amount - payment methods will support up to this amount');

      // Create service instance
      final apiClient = Get.find<ApiClient>();
      final repository = MyFatoorahRepository(apiClient: apiClient);
      final service = MyFatoorahService(repository: repository);

      // Call backend endpoint
      final Response response = await service.getPaymentMethods(
        amount: amount,
        currency: 'SAR',
      );

      // ⚡ FIX: Handle 304 Not Modified - repository now returns cached data as 200
      // The repository handles 304 by returning cached data with statusCode 200
      // So we don't need special 304 handling here - just process as normal 200

      // Check response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            response.body as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          // Map backend response to MFPaymentMethod objects
          final List<dynamic> backendMethods =
              responseData['data'] as List<dynamic>;
          final List<MFPaymentMethod> allMethods =
              MyFatoorahMapper.mapBackendResponseToPaymentMethods(
                  backendMethods);

          final int inspectCount = allMethods.length < backendMethods.length
              ? allMethods.length
              : backendMethods.length;
          for (int i = 0; i < inspectCount; i++) {
            final dynamic raw = backendMethods[i];
            final MFPaymentMethod mapped = allMethods[i];
            if ((mapped.imageUrl ?? '').trim().isEmpty &&
                raw is Map<String, dynamic>) {
              debugPrint(
                  '[QidhaPay][MethodMap] Missing logo for methodId=${mapped.paymentMethodId} keys=${raw.keys.toList()}');
            }
          }

          // Filter payment methods based on platform
          qidhaPaymentMethods = _filterPaymentMethodsByPlatform(allMethods);
          qidhaPaymentMethodsSelected =
              List.filled(qidhaPaymentMethods.length, false);

          debugPrint(
              '✅ Loaded ${qidhaPaymentMethods.length} payment methods for Qidha wallet from backend');
          for (final method in qidhaPaymentMethods) {
            debugPrint(
                '   - ${method.paymentMethodAr} (ID: ${method.paymentMethodId})');
          }
        } else {
          debugPrint(
              "❌ Backend response indicates failure: ${responseData['message']}");
          qidhaPaymentMethods = [];
          qidhaPaymentMethodsSelected = [];
          showCustomSnackBar(
              (responseData['message'] as String?) ?? 'خطأ في تحميل طرق الدفع');
        }
      } else {
        // Only treat 4xx and 5xx as errors (304 is already handled above)
        debugPrint(
            '❌ Backend request failed with status: ${response.statusCode}');
        qidhaPaymentMethods = [];
        qidhaPaymentMethodsSelected = [];

        // Handle validation errors
        if (response.statusCode == 422) {
          final Map<String, dynamic>? errorData = response.body is Map
              ? response.body as Map<String, dynamic>
              : null;
          final String errorMessage =
              (errorData?['message'] as String?) ?? 'خطأ في البيانات المرسلة';
          showCustomSnackBar(errorMessage);
        } else {
          showCustomSnackBar('خطأ في تحميل طرق الدفع');
        }
      }
    } catch (error) {
      debugPrint('❌ Error loading Qidha payment methods from backend: $error');
      showCustomSnackBar('خطأ في تحميل طرق الدفع');
      qidhaPaymentMethods = [];
      qidhaPaymentMethodsSelected = [];
    } finally {
      isLoadingPaymentMethods = false;
      update();
    }
  }

  /// Filter payment methods based on platform.
  /// Apple Pay remains enabled.
  /// iOS: hide Google Pay methods.
  List<MFPaymentMethod> _filterPaymentMethodsByPlatform(
      List<MFPaymentMethod> paymentMethods) {
    return paymentMethods.where((method) {
      final methodCode = method.paymentMethodCode?.toLowerCase() ?? '';
      final methodEn = method.paymentMethodEn?.toLowerCase() ?? '';
      final methodAr = method.paymentMethodAr?.toLowerCase() ?? '';

      // Keep all methods visible on Android (including Apple Pay).
      if (Platform.isAndroid) {
        return true;
      }

      // On iOS, hide Google Pay methods.
      if (Platform.isIOS) {
        final isGooglePay = methodCode.contains('gp') ||
            methodEn.contains('google') ||
            methodAr.contains('google');
        if (isGooglePay) {
          debugPrint('iOS: Hiding Google Pay - ${method.paymentMethodAr}');
          return false;
        }
        return true;
      }

      return true;
    }).toList();
  }

  /// Select a payment method for Qidha wallet payment
  /// @param index - The index of the selected payment method
  void selectQidhaPaymentMethod(int index) {
    if (index >= 0 && index < qidhaPaymentMethods.length) {
      qidhaPaymentMethodsSelected = List.generate(
        qidhaPaymentMethodsSelected.length,
        (i) => i == index,
      );
      selectedQidhaPaymentMethod = qidhaPaymentMethods[index];

      debugPrint(
          '✅ Selected Qidha payment method: ${qidhaPaymentMethods[index].paymentMethodAr} (ID: ${qidhaPaymentMethods[index].paymentMethodId})');
      debugPrint(
          '✅ Payment method code: ${qidhaPaymentMethods[index].paymentMethodCode}');

      update();
    }
  }

  Future<String> _processQidhaPaymentWithoutOrder(
    BuildContext context, {
    required double amount,
    required MFPaymentMethod paymentMethod,
  }) async {
    try {
      final apiClient = Get.find<ApiClient>();
      final repository = MyFatoorahRepository(apiClient: apiClient);
      final service = MyFatoorahService(repository: repository);
      final profileController = Get.find<ProfileController>();

      final String customerName = profileController.userInfoModel?.fName
                  ?.trim()
                  .isNotEmpty ==
              true
          ? '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}'
              .trim()
          : ((profileController.userInfoModel?.lName ?? '').trim().isNotEmpty
              ? (profileController.userInfoModel?.lName ?? '').trim()
              : 'Customer');
      final String customerPhone = _getUserPhoneForForm().trim();
      final String customerEmail =
          profileController.userInfoModel?.email?.trim().isNotEmpty == true
              ? profileController.userInfoModel!.email!.trim()
              : 'no-reply@shelafood.com';

      if (customerPhone.isEmpty) {
        showCustomSnackBar('رقم الهاتف مطلوب لبدء الدفع');
        return 'error';
      }

      final String? backendMethodCode =
          MyFatoorahMapper.normalizeBackendPaymentMethodCode(
        paymentMethod.paymentMethodCode,
        methodEn: paymentMethod.paymentMethodEn,
        methodAr: paymentMethod.paymentMethodAr,
      );
      final int? backendMethodId = paymentMethod.paymentMethodId;
      debugPrint(
          '[QidhaPay][NoOrder] payload: methodCode=$backendMethodCode methodId=$backendMethodId amount=$amount');
      if ((backendMethodCode == null || backendMethodCode.isEmpty) &&
          backendMethodId == null) {
        showCustomSnackBar('طريقة الدفع غير مدعومة حالياً');
        return 'error';
      }

      final Response response = await service.processPaymentWithoutOrder(
        amount: amount,
        currency: 'SAR',
        paymentMethodId: backendMethodId,
        paymentMethodCode: backendMethodCode,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        callbackUrl:
            '${AppConstants.baseUrl}/api/v1/payment/myfatoorah/success',
        errorUrl: '${AppConstants.baseUrl}/api/v1/payment/myfatoorah/error',
      );

      debugPrint(
          '[QidhaPay][NoOrder] processWithoutOrder status=${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        String backendMessage = 'فشل بدء الدفع';
        final Map<String, dynamic>? errorBody = response.body is Map
            ? Map<String, dynamic>.from(response.body as Map)
            : null;
        if (errorBody != null) {
          backendMessage = (errorBody['message'] as String?) ?? backendMessage;
        }
        showCustomSnackBar(backendMessage);
        return 'error';
      }

      final Map<String, dynamic> body = response.body is Map<String, dynamic>
          ? response.body as Map<String, dynamic>
          : <String, dynamic>{};
      final dynamic data = body['data'];
      final String? paymentUrl =
          data is Map<String, dynamic> ? data['payment_url']?.toString() : null;

      if (paymentUrl == null || paymentUrl.isEmpty) {
        showCustomSnackBar('فشل بدء الدفع - لم يتم استلام رابط الدفع');
        return 'error';
      }

      final String? webResult = await Get.to(
        () => MyFatoorahPaymentWebViewScreen(
          initialUrl: paymentUrl,
          successUrlContains:
              '${AppConstants.baseUrl}/api/v1/payment/myfatoorah/success',
          errorUrlContains:
              '${AppConstants.baseUrl}/api/v1/payment/myfatoorah/error',
        ),
      );

      debugPrint('[QidhaPay][NoOrder] webResult=$webResult');
      if (webResult == 'success') {
        return 'success';
      }
      if (webResult == 'cancelled') {
        return 'cancelled';
      }
      return 'error';
    } catch (error, stackTrace) {
      debugPrint(
          '[QidhaPay][NoOrder][ERROR] $error ; stack=${stackTrace.toString().split('\n').take(5).join(' | ')}');
      showCustomSnackBar('فشلت عملية الدفع: ${error.toString()}');
      return 'error';
    }
  }

  // شحن  =================================================
  Future Send_Pay_Credit(BuildContext context, double total) async {
    // Validate payment method selection
    if (selectedQidhaPaymentMethod == null) {
      showCustomSnackBar('يرجى اختيار طريقة الدفع أولاً');
      return;
    }

    _isLoading = true;
    update();

    final CheckoutController checkoutController =
        Get.find<CheckoutController>();
    final double normalizedTotal = double.parse(total.toStringAsFixed(2));
    final String paymentAmount = normalizedTotal.toStringAsFixed(2);

    // Load methods for exact selected amount, then bind selected method by ID.
    await checkoutController.initiatePaymentWithAmount(context, paymentAmount);
    if (!context.mounted) {
      _isLoading = false;
      update();
      return;
    }

    if (checkoutController.paymentMethods.isEmpty) {
      showCustomSnackBar('لا توجد طرق دفع متاحة للمبلغ المختار');
      _isLoading = false;
      update();
      return;
    }
    debugPrint(
        '[QidhaPay] availableMethodIds=${checkoutController.paymentMethods.map((m) => m.paymentMethodId).toList()}');

    final int selectedMethodId =
        selectedQidhaPaymentMethod!.paymentMethodId ?? -1;
    final int matchedIndex = checkoutController.paymentMethods.indexWhere(
      (method) => method.paymentMethodId == selectedMethodId,
    );

    if (matchedIndex < 0) {
      showCustomSnackBar('طريقة الدفع المختارة غير متاحة لهذا المبلغ');
      _isLoading = false;
      update();
      return;
    }

    checkoutController.isSelected =
        List<bool>.filled(checkoutController.paymentMethods.length, false);
    checkoutController.isSelected[matchedIndex] = true;
    checkoutController.select_payment_Methods =
        checkoutController.paymentMethods[matchedIndex];
    checkoutController.selectedButton = 1;

    debugPrint(
        'Processing Qidha wallet payment with ${checkoutController.select_payment_Methods!.paymentMethodAr}');
    debugPrint('Amount: $paymentAmount SAR');
    debugPrint(
        'PaymentMethodId: ${checkoutController.select_payment_Methods!.paymentMethodId}');

    // Qidha credit payment does not always have an order context.
    // If no order exists, use direct MyFatoorah execution with selected method.
    bool isPaymentSuccessful = false;
    bool isPaymentCancelled = false;
    if (checkoutController.currentOrderId == null) {
      debugPrint(
          '[QidhaPay] No checkout order context. Using backend process-without-order flow.');
      final String noOrderResult = await _processQidhaPaymentWithoutOrder(
        context,
        amount: normalizedTotal,
        paymentMethod: checkoutController.select_payment_Methods!,
      );
      if (!context.mounted) {
        _isLoading = false;
        update();
        return;
      }
      isPaymentSuccessful = noOrderResult == 'success';
      isPaymentCancelled = noOrderResult == 'cancelled';
    } else {
      debugPrint(
          '[QidhaPay] Using checkout order-linked payment flow. orderId=${checkoutController.currentOrderId}');
      // Order-linked payment flow (backend-driven)
      isPaymentSuccessful =
          await checkoutController.Pay(context, paymentAmount);
      if (!context.mounted) {
        _isLoading = false;
        update();
        return;
      }
    }

    if (isPaymentSuccessful == false) {
      if (isPaymentCancelled) {
        showCustomSnackBar('تم إلغاء عملية الدفع', isError: false);
      } else {
        showCustomSnackBar('فشلت عملية الشحن قم بالمحاولة ثانيا ');
      }
      _isLoading = false;
      update();
      return;
    } else {
      // Payment successful, call backend to update Qidha wallet
      await kaidhaSubServiceInterface.send_Pay_credit(context, normalizedTotal);
      if (!context.mounted) {
        _isLoading = false;
        update();
        return;
      }

      // Refresh wallet data
      await get_Wallet_Kaidh();

      debugPrint('Qidha wallet credit payment completed successfully');
    }

    _isLoading = false;
    update();
  }

  // شراء   =============================================
  Future<bool> Send_Pay_Bebit(context, double total, {String? orderId}) async {
    return await kaidhaSubServiceInterface.send_Pay_debit(context, total,
        orderId: orderId);
  }

  // -------------------------------

  void validate_Fields_Screen_1(BuildContext context) {
    isFirstNameEmpty = firstname.text.isEmpty;
    isFatherNameEmpty = fathername.text.isEmpty;
    isGrandFatherNameEmpty = grandfathername.text.isEmpty;
    isLastNameEmpty = last_name.text.isEmpty;
    isNumberOfFamilyEmpty = number_of_family_members.text.isEmpty ||
        number_of_family_members.text.trim() == '0';
    isIdentityCardEmpty = identity_card_number.text.isEmpty;
    isPhoneEmpty = phoneController.text.isEmpty;
    isNeighborhoodEmpty = neighborhood.text.isEmpty;
    isEmployerEmpty = name_of_employer.text.isEmpty;
    isTotalSalaryEmpty = total_salary.text.isEmpty;
    isBirthDateEmpty = birthDate.isEmpty;
    isNationalityEmpty = nationality.isEmpty;
    isMaritalStatusEmpty = marital_status.isEmpty;
    isEndDateEmpty = end_date.isEmpty;
    isSalaryDayEmpty = end_date.isEmpty;

    update();

    if (isFirstNameEmpty) {
      FocusScope.of(context).requestFocus(firstNameFocus);
      return;
    }
    if (isFatherNameEmpty) {
      FocusScope.of(context).requestFocus(fatherNameFocus);
      return;
    }
    if (isGrandFatherNameEmpty) {
      FocusScope.of(context).requestFocus(grandFatherNameFocus);
      return;
    }
    if (isLastNameEmpty) {
      FocusScope.of(context).requestFocus(lastNameFocus);
      return;
    }
    if (birthDate.isEmpty) {
      {
        isBirthDateEmpty = true;
        update();

        Scrollable.ensureVisible(
          birthDateKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        return;
      }
    }

    if (nationality.isEmpty) {
      isNationalityEmpty = true;
      update();
    }
    if (nationality.isEmpty) {
      isNationalityEmpty = true;
      update();

      // التمرير إلى العنصر
      Scrollable.ensureVisible(
        nationalityKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      return;
    }

    if (isMaritalStatusEmpty) {
      showCustomSnackBar('يرجى تحديد الحالة الاجتماعية');
      return;
    }
    if (number_of_family_members.text.isEmpty ||
        number_of_family_members.text.trim() == '0') {
      isNumberOfFamilyEmpty = true;
      update();

      Scrollable.ensureVisible(
        numberKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      numberOfFamilyFocus.requestFocus();
      return;
    }

    if (isIdentityCardEmpty) {
      FocusScope.of(context).requestFocus(identityCardFocus);
      return;
    }
    if (isPhoneEmpty) {
      FocusScope.of(context).requestFocus(phoneFocus);
      return;
    }
    if (end_date.isEmpty) {
      isEndDateEmpty = true;
      update();

      Scrollable.ensureVisible(
        endDateKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      endDateFocus.requestFocus();
      return;
    }

    if (isEmployerEmpty) {
      FocusScope.of(context).requestFocus(employerFocus);
      return;
    }
    if (isNeighborhoodEmpty) {
      FocusScope.of(context).requestFocus(neighborhoodFocus);
      return;
    }
    if (total_salary.text.isEmpty) {
      isTotalSalaryEmpty = true;
      update();
      Scrollable.ensureVisible(
        totalSalaryKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      totalSalaryFocus.requestFocus();
      return;
    }

    // Debug: Show all data that will be sent to backend
    debugPrint('🔍 ===== STEP 1 → STEP 2 DATA DEBUG =====');
    debugPrint('📋 Personal Information:');
    debugPrint("   - first_name: '${firstname.text}'");
    debugPrint("   - father_name: '${fathername.text}'");
    debugPrint("   - grandfather_name: '${grandfathername.text}'");
    debugPrint("   - last_name: '${last_name.text}'");
    debugPrint("   - birth_date: '$birthDate'");
    debugPrint("   - nationality: '$nationality'");
    debugPrint("   - marital_status: '$marital_status'");
    debugPrint(
        "   - number_of_family_members: '${number_of_family_members.text}'");
    debugPrint("   - identity_card_number: '${identity_card_number.text}'");
    debugPrint("   - end_date: '$end_date'");
    debugPrint(
        "   - mobile: '${_getUserPhoneForForm().isNotEmpty ? _getUserPhoneForForm() : 'N/A'}'");
    debugPrint('📋 Address Information:');
    debugPrint("   - house_type: '$house_type'");
    debugPrint("   - city: '$city'");
    debugPrint("   - neighborhood: '${neighborhood.text}'");
    debugPrint('📋 Employment Information:');
    debugPrint("   - name_of_employer: '${name_of_employer.text}'");
    debugPrint("   - total_salary: '${total_salary.text}'");
    debugPrint("   - installments: '$Installments'");
    debugPrint(
        "   - source_of_income: '${_mapJobSpecificationToServerValue(jobSpecification)}'");
    debugPrint("   - monthly_amount: '${monthlyIncome.text}'");
    debugPrint("   - salary_day: '${salary_day.text}'");
    debugPrint('📋 Data Mapping (What will be sent to backend):');
    debugPrint("   - national_id: '${identity_card_number.text}'");
    debugPrint(
        "   - city: '${city.isNotEmpty ? city : 'الرياض'}' (user selection or الرياض default)");
    debugPrint(
        "   - house_type: '${house_type.isNotEmpty ? house_type : 'apartment'}' (user selection or apartment default)");
    debugPrint("   - neighborhood: '${neighborhood.text}'");
    debugPrint('🔍 ===== END STEP 1 DATA DEBUG =====');

    nextStage(context);
  }

  void validate_Fields_Screen_2(BuildContext context, String nationalId) async {
    debugPrint('🔍 Starting Step 2 validation...');

    // 1. Form Validation & Data Preparation
    if (jobSpecification.isEmpty ||
        salary_day.text.isEmpty ||
        monthlyIncome.text.isEmpty) {
      if (salary_day.text.isEmpty) {
        isSalaryDayEmpty = true;
        update();

        // التمرير والتركيز على حقل يوم الراتب
        if (salaryDayFocus.hasFocus == false) {
          salaryDayFocus.requestFocus();
        }

        if (salaryDayKey.currentContext != null) {
          Scrollable.ensureVisible(
            salaryDayKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

        return;
      }

      if (monthlyIncome.text.isEmpty) {
        isMonthlyIncomeEmpty = true;
        update();

        if (!monthlyIncomeFocus.hasFocus) {
          monthlyIncomeFocus.requestFocus();
        }

        if (monthlyIncomeKey.currentContext != null) {
          Scrollable.ensureVisible(
            monthlyIncomeKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

        return;
      }
      return;
    }

    // 2. Document Validation (max 5 files, JPG/PNG/PDF only, each with name/description)
    if (All_files.isEmpty) {
      showCustomSnackBar('لم يتم حفظ اي مستند');
      return;
    }

    if (All_files.length > 5) {
      showCustomSnackBar('يمكن رفع 5 مستندات كحد أقصى');
      return;
    }

    // Validate file formats and names
    for (int i = 0; i < All_files.length; i++) {
      final file = All_files[i];
      final fileName = file.file.name.toLowerCase();
      final fileExtension = fileName.split('.').last;

      if (!['jpg', 'jpeg', 'png', 'pdf'].contains(fileExtension)) {
        showCustomSnackBar(
            'نوع الملف غير مدعوم. يرجى رفع ملفات JPG, PNG, أو PDF فقط');
        return;
      }

      if (file.name.trim().isEmpty) {
        showCustomSnackBar('يرجى إدخال اسم لكل مستند');
        return;
      }
    }

    debugPrint('✅ Form validation passed');
    debugPrint('📁 Files validated: ${All_files.length} files');

    // Debug: Show all data that will be sent to backend
    debugPrint('🔍 ===== STEP 2 → WALLET CREATION DATA DEBUG =====');
    debugPrint('📋 Personal Information:');
    debugPrint("   - first_name: '${firstname.text}'");
    debugPrint("   - father_name: '${fathername.text}'");
    debugPrint("   - grandfather_name: '${grandfathername.text}'");
    debugPrint("   - last_name: '${last_name.text}'");
    debugPrint("   - birth_date: '$birthDate'");
    debugPrint("   - nationality: '$nationality'");
    debugPrint("   - marital_status: '$marital_status'");
    debugPrint(
        "   - number_of_family_members: '${number_of_family_members.text}'");
    debugPrint("   - identity_card_number: '${identity_card_number.text}'");
    debugPrint("   - end_date: '$end_date'");
    debugPrint(
        "   - mobile: '${_getUserPhoneForForm().isNotEmpty ? _getUserPhoneForForm() : 'N/A'}'");
    debugPrint('📋 Address Information:');
    debugPrint("   - house_type: '$house_type'");
    debugPrint("   - city: '$city'");
    debugPrint("   - neighborhood: '${neighborhood.text}'");
    debugPrint('📋 Employment Information:');
    debugPrint("   - name_of_employer: '${name_of_employer.text}'");
    debugPrint("   - total_salary: '${total_salary.text}'");
    debugPrint("   - installments: '$Installments'");
    debugPrint(
        "   - source_of_income: '${_mapJobSpecificationToServerValue(jobSpecification)}'");
    debugPrint("   - monthly_amount: '${monthlyIncome.text}'");
    debugPrint("   - salary_day: '${salary_day.text}'");
    debugPrint('📋 Files to be uploaded:');
    for (int i = 0; i < All_files.length; i++) {
      final file = All_files[i];
      debugPrint("   - File ${i + 1}: '${file.name}' (${file.file.name})");
    }
    debugPrint('📋 Data Mapping (What will be sent to backend):');
    debugPrint("   - national_id: '${identity_card_number.text}'");
    debugPrint(
        "   - city: '${city.isNotEmpty ? city : 'الرياض'}' (user selection or الرياض default)");
    debugPrint(
        "   - house_type: '${house_type.isNotEmpty ? house_type : 'apartment'}' (user selection or apartment default)");
    debugPrint("   - neighborhood: '${neighborhood.text}'");
    debugPrint('🔍 ===== END STEP 2 DATA DEBUG =====');

    // Save state
    await saveState_kaidha_SharedPre();
    if (!context.mounted) {
      return;
    }
    await SendState_kaidha('in_progress');
    if (!context.mounted) {
      return;
    }

    // STEP 2: Create wallet with signature status 0 (pending)
    debugPrint('🔄 Step 2: Creating wallet with signature status 0...');
    final bool walletCreated = await _createWalletWithPendingStatus();
    if (!context.mounted) {
      return;
    }

    if (!walletCreated) {
      debugPrint('❌ Step 2 failed: Wallet creation failed');
      showCustomSnackBar('فشل في إنشاء المحفظة');
      return;
    }

    debugPrint('✅ Step 2 completed: Wallet created with signature status 0');

    // Check Nafath status from server (source of truth)
    debugPrint('?? Checking Nafath status from server...');

    String? nafathStatus;
    try {
      final existingRequest =
          await kaidhaSubServiceInterface.Nafath_send_checkStatus(
              context, identity_card_number.text);
      if (!context.mounted) {
        return;
      }

      _nafath_checkStatus = existingRequest;
      final status = existingRequest?.status ?? 'no_request';
      nafathStatus = status;
      final requestId = existingRequest?.requestId;
      debugPrint(
          '?? Nafath status: $status, request_id: $requestId, at=${DateTime.now().toIso8601String()}');

      switch (status) {
        case 'pending':
          // Never initiate when pending; just wait / check again
          await _loadNafathRequestFromCache();
          if (!context.mounted) {
            return;
          }
          if (hasCachedNafathRequest &&
              _cachedNationalId == identity_card_number.text) {
            _nafath_national_id = _cachedNafathRequest;
          }
          _isShow = false;
          update();
          break;
        case 'approved':
          // Proceed to next step immediately
          _isShow = true;
          update();
          if (!context.mounted) {
            return;
          }
          nextStage(context);
          return;
        case 'rejected':
        case 'expired':
        case 'cancelled':
          // Do not auto-initiate; let user retry explicitly
          _cachedNafathRequest = null;
          _cachedNationalId = null;
          _cachedNafathRandomCode = null;
          _isShow = false;
          update();
          break;
        case 'no_request':
        default:
          // No request -> initiate
          await _clearNafathRequestCache();
          if (!context.mounted) {
            return;
          }
          await Nafath_send_National_Id(context, identity_card_number.text,
              forceNew: true);
          if (_nafath_national_id != null) {
            _nafath_checkStatus = NafathCheckStatusModel(
              status: 'pending',
              requestId: _nafath_national_id!.requestId,
              nationalId: identity_card_number.text,
            );
          }
          if (!context.mounted) {
            return;
          }
          break;
      }
    } catch (e) {
      debugPrint('? Error checking Nafath status: $e');
    }

    // Navigate to Step 3 for all non-approved states.
    if (nafathStatus != 'approved' ||
        (nafath_national_id != null &&
            nafath_national_id!.requestId != null &&
            nafath_national_id!.requestId!.isNotEmpty)) {
      if (!context.mounted) {
        return;
      }
      nextStage(context);
    }
  }

  // Create wallet with pending status and signature status 0
  // API: POST /api/qidha-wallet/store
  Future<bool> _createWalletWithPendingStatus() async {
    try {
      if (!await _ensureMobileReady()) {
        return false;
      }
      final existingWallet =
          await kaidhaSubServiceInterface.getWalletKaidh(forceRefresh: true);
      if (existingWallet?.wallet?.id != null) {
        debugPrint('?? Wallet already exists. Skipping create.');
        walletKaidhaModel = existingWallet;
        return true;
      }

      debugPrint('📋 Preparing wallet data...');
      debugPrint('👤 User: ${firstname.text} ${last_name.text}');
      debugPrint(
          "📱 Phone: ${_getUserPhoneForForm().isNotEmpty ? _getUserPhoneForForm() : 'N/A'}");
      debugPrint('🆔 National ID: ${identity_card_number.text}');
      debugPrint('📁 Files: ${All_files.length} documents');

      // Prepare all form data for submission
      final KaidhaSubModel kaidhaSub = KaidhaSubModel(
        first_name: firstname.text,
        father_name: fathername.text,
        grandfather_name: grandfathername.text,
        last_name: last_name.text,
        birth_date: birthDate,
        national_id: identity_card_number.text,
        nationality: nationality,
        marital_status: marital_status,
        number_of_family_members: _getFamilyMembersCount(),
        identity_card_number: identity_card_number.text,
        end_date: end_date,
        mobile: _getUserPhoneForForm(),
        house_type: house_type.isNotEmpty ? house_type : 'apartment',
        city: city.isNotEmpty ? city : 'الرياض',
        neighborhood: neighborhood.text,
        name_of_employer: name_of_employer.text,
        total_salary: total_salary.text,
        installments: Installments,
        source_of_income: _mapJobSpecificationToServerValue(jobSpecification),
        monthly_amount: monthlyIncome.text,
        salary_day: salary_day.text.isNotEmpty ? salary_day.text : '2',
      );

      debugPrint('🚀 Calling API: POST /api/qidha-wallet/store');
      debugPrint('📤 Sending ${All_files.length} files with wallet data');

      // Create wallet with signature status 0 (pending)
      clearFieldErrors();
      bool success = false;
      try {
        success = await kaidhaSubServiceInterface.Stor_info(
            Get.context!, kaidhaSub, All_files);
      } on ValidationException catch (e) {
        setFieldErrors(e.errors);
        return false;
      }

      if (success) {
        debugPrint('✅ Wallet created with pending status successfully');
        debugPrint('📊 Status: pending, Signature Status: 0');

        // Refresh wallet data to get the new wallet info
        await get_Wallet_Kaidh(forceRefresh: true);
        return true;
      } else {
        debugPrint('❌ Failed to create wallet');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error creating wallet: $e');
      return false;
    }
  }

  /* Future<void> _createWalletWithPendingStatus() async {
    try {
      final address = AddressHelper.getUserAddressFromSharedPref();

      debugPrint("📋 Preparing wallet data...");
      debugPrint("👤 User: ${firstname.text} ${last_name.text}");
      debugPrint(
          "📱 Phone: ${_getUserPhoneForForm().isNotEmpty ? _getUserPhoneForForm() : 'N/A'}");
      debugPrint("🆔 National ID: ${identity_card_number.text}");
      debugPrint("📁 Files: ${All_files.length} documents");

      // Prepare all form data for submission
      KaidhaSubModel kaidhaSub = KaidhaSubModel(
        first_name: firstname.text,
        father_name: fathername.text,
        grandfather_name: grandfathername.text,
        last_name: last_name.text,
        birth_date: birthDate,
        national_id: identity_card_number.text,
        nationality: nationality,
        marital_status: marital_status,
        number_of_family_members: _getFamilyMembersCount(),
        identity_card_number: identity_card_number.text,
        end_date: end_date,
      mobile: _getUserPhoneForForm(),
        house_type: house_type.isNotEmpty ? house_type : 'apartment',
        city: city.isNotEmpty ? city : 'الرياض',
        neighborhood: neighborhood.text,
        name_of_employer: name_of_employer.text,
        total_salary: total_salary.text,
        installments: Installments,
        source_of_income: _mapJobSpecificationToServerValue(jobSpecification),
        monthly_amount: monthlyIncome.text,
        salary_day: salary_day.text.isNotEmpty ? salary_day.text : "2",
      );

      debugPrint("🚀 Calling API: POST /api/qidha-wallet/store");
      debugPrint("📤 Sending ${All_files.length} files with wallet data");
      debugPrint("📋 Wallet data being sent:");
      debugPrint(
          "   - first_name: '${kaidhaSub.first_name}' (${kaidhaSub.first_name?.length ?? 0} chars)");
      debugPrint(
          "   - father_name: '${kaidhaSub.father_name}' (${kaidhaSub.father_name?.length ?? 0} chars)");
      debugPrint(
          "   - grandfather_name: '${kaidhaSub.grandfather_name}' (${kaidhaSub.grandfather_name?.length ?? 0} chars)");
      debugPrint(
          "   - last_name: '${kaidhaSub.last_name}' (${kaidhaSub.last_name?.length ?? 0} chars)");
      debugPrint(
          "   - birth_date: '${kaidhaSub.birth_date}' (${kaidhaSub.birth_date?.length ?? 0} chars)");
      debugPrint(
          "   - national_id: '${kaidhaSub.national_id}' (${kaidhaSub.national_id?.length ?? 0} chars)");
      debugPrint(
          "   - marital_status: '${kaidhaSub.marital_status}' (${kaidhaSub.marital_status?.length ?? 0} chars)");
      debugPrint(
          "   - number_of_family_members: '${kaidhaSub.number_of_family_members}' (${kaidhaSub.number_of_family_members?.length ?? 0} chars)");
      debugPrint(
          "   - identity_card_number: '${kaidhaSub.identity_card_number}' (${kaidhaSub.identity_card_number?.length ?? 0} chars)");
      debugPrint(
          "   - end_date: '${kaidhaSub.end_date}' (${kaidhaSub.end_date?.length ?? 0} chars)");
      debugPrint(
          "   - mobile: '${kaidhaSub.mobile}' (${kaidhaSub.mobile?.length ?? 0} chars)");
      debugPrint(
          "   - house_type: '${kaidhaSub.house_type}' (${kaidhaSub.house_type?.length ?? 0} chars)");
      debugPrint(
          "   - city: '${kaidhaSub.city}' (${kaidhaSub.city?.length ?? 0} chars)");
      debugPrint(
          "   - neighborhood: '${kaidhaSub.neighborhood}' (${kaidhaSub.neighborhood?.length ?? 0} chars)");
      debugPrint(
          "   - name_of_employer: '${kaidhaSub.name_of_employer}' (${kaidhaSub.name_of_employer?.length ?? 0} chars)");
      debugPrint(
          "   - total_salary: '${kaidhaSub.total_salary}' (${kaidhaSub.total_salary?.length ?? 0} chars)");
      debugPrint(
          "   - installments: '${kaidhaSub.installments}' (${kaidhaSub.installments?.length ?? 0} chars)");
      debugPrint(
          "   - source_of_income: '${kaidhaSub.source_of_income}' (${kaidhaSub.source_of_income?.length ?? 0} chars)");
      debugPrint(
          "   - monthly_amount: '${kaidhaSub.monthly_amount}' (${kaidhaSub.monthly_amount?.length ?? 0} chars)");
      debugPrint(
          "   - salary_day: '${kaidhaSub.salary_day}' (${kaidhaSub.salary_day?.length ?? 0} chars)");

      // Check for empty required fields
      List<String> emptyFields = [];
      if (kaidhaSub.first_name?.isEmpty ?? true) emptyFields.add('first_name');
      if (kaidhaSub.father_name?.isEmpty ?? true)
        emptyFields.add('father_name');
      if (kaidhaSub.grandfather_name?.isEmpty ?? true)
        emptyFields.add('grandfather_name');
      if (kaidhaSub.last_name?.isEmpty ?? true) emptyFields.add('last_name');
      if (kaidhaSub.birth_date?.isEmpty ?? true) emptyFields.add('birth_date');
      if (kaidhaSub.national_id?.isEmpty ?? true)
        emptyFields.add('national_id');
      if (kaidhaSub.marital_status?.isEmpty ?? true)
        emptyFields.add('marital_status');
      final members = kaidhaSub.number_of_family_members?.trim();
      if (members == null || members.isEmpty || members == '0')
        emptyFields.add('number_of_family_members');
      if (kaidhaSub.identity_card_number?.isEmpty ?? true)
        emptyFields.add('identity_card_number');
      if (kaidhaSub.end_date?.isEmpty ?? true) emptyFields.add('end_date');
      if (kaidhaSub.mobile?.isEmpty ?? true) emptyFields.add('mobile');
      if (kaidhaSub.house_type?.isEmpty ?? true) emptyFields.add('house_type');
      if (kaidhaSub.city?.isEmpty ?? true) emptyFields.add('city');
      if (kaidhaSub.neighborhood?.isEmpty ?? true)
        emptyFields.add('neighborhood');
      if (kaidhaSub.name_of_employer?.isEmpty ?? true)
        emptyFields.add('name_of_employer');
      if (kaidhaSub.total_salary?.isEmpty ?? true)
        emptyFields.add('total_salary');
      if (kaidhaSub.installments?.isEmpty ?? true)
        emptyFields.add('installments');
      if (kaidhaSub.source_of_income?.isEmpty ?? true)
        emptyFields.add('source_of_income');
      if (kaidhaSub.monthly_amount?.isEmpty ?? true)
        emptyFields.add('monthly_amount');
      if (kaidhaSub.salary_day?.isEmpty ?? true) emptyFields.add('salary_day');

      if (emptyFields.isNotEmpty) {
        debugPrint("❌ Empty required fields: ${emptyFields.join(', ')}");
        showCustomSnackBar(
            "يرجى ملء جميع الحقول المطلوبة: ${emptyFields.join(', ')}");
        return;
      }

      // 2. Wallet Creation API Call (IMMEDIATE)
      // API: POST /api/qidha-wallet/store
      // Headers: Authorization, Content-Type
      // Request Body: All form data + Files Uploaded: All documents from Step 2
      clearFieldErrors();
      bool success = false;
      try {
        success = await kaidhaSubServiceInterface.Stor_info(
            Get.context!, kaidhaSub, All_files);
      } on ValidationException catch (e) {
        setFieldErrors(e.errors);
        return;
      }

      if (success) {
        debugPrint("✅ 3. Server Response - Wallet Created");
        debugPrint("🆔 Wallet created with pending status successfully");
        debugPrint("📊 Status: pending, Signature Status: 0");

        // Refresh wallet data to get the new wallet info
        await get_Wallet_Kaidh(forceRefresh: true);
      } else {
        debugPrint("❌ Failed to create wallet");
        showCustomSnackBar("فشل في إنشاء المحفظة");
      }
    } catch (e) {
      debugPrint("❌ Error creating wallet: $e");
      showCustomSnackBar("حدث خطأ في إنشاء المحفظة");
    }
  } */

  // Update wallet signature status to approved after Step 3 completion
  Future<void> updateWalletSignatureStatusToApproved() async {
    try {
      final userInfo = Get.find<ProfileController>().userInfoModel;
      if (userInfo?.id == null) {
        debugPrint('User ID is null, cannot update wallet signature status');
        return;
      }

      final int user_id = userInfo!.id!;
      final Map<String, dynamic> savedData = await getState_kaidha_SharedPre();

      // Update signature status to approved (1)
      await kaidhaSubServiceInterface.SendState_kaidha(
          user_id, 'approved', savedData);

      debugPrint('✅ Wallet signature status updated to approved (1)');

      // Refresh wallet data
      await get_Wallet_Kaidh(forceRefresh: true);

      // Navigate to pending approval screen
      debugPrint('🔄 Navigating to pending approval screen...');
      Get.toNamed(RouteHelper.getKiadaWalletSubscription());
    } catch (e) {
      debugPrint('❌ Error updating wallet signature status: $e');
      showCustomSnackBar('حدث خطأ في تحديث حالة توقيع المحفظة');
    }
  }

  // Update wallet status to approved after Step 3 completion
  Future<void> updateWalletStatusToApproved() async {
    try {
      final userInfo = Get.find<ProfileController>().userInfoModel;
      if (userInfo?.id == null) {
        debugPrint('User ID is null, cannot update wallet status');
        return;
      }

      final int user_id = userInfo!.id!;
      final Map<String, dynamic> savedData = await getState_kaidha_SharedPre();

      // Update status to approved
      await kaidhaSubServiceInterface.SendState_kaidha(
          user_id, 'approved', savedData);

      debugPrint('✅ Wallet status updated to approved');

      // Refresh wallet data
      await get_Wallet_Kaidh(forceRefresh: true);
    } catch (e) {
      debugPrint('❌ Error updating wallet status: $e');
      showCustomSnackBar('حدث خطأ في تحديث حالة المحفظة');
    }
  }

  DateTime? _parseServerDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(rawDate).toLocal();
    } catch (_) {
      return null;
    }
  }

  // Nafath Request Caching Methods =======================================================================

  /// Save Nafath request to cache
  Future<void> _saveNafathRequestToCache() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      if (_cachedNafathRequest != null && _cachedNationalId != null) {
        final cacheData = {
          'national_id': _cachedNationalId,
          'nafath_request': _cachedNafathRequest!.toJson(),
          'random_code': _cachedNafathRandomCode,
          'created_at': _nafathRequestCreatedAt?.toIso8601String(),
          'full_name_ar': _nafathFullNameAr,
          'signed_file_url': _nafathSignedFileUrl,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        };

        await _prefs!.setString(_nafathCacheKey, jsonEncode(cacheData));
        debugPrint('✅ Nafath request saved to cache');
      }
    } catch (e) {
      debugPrint('❌ Error saving Nafath request to cache: $e');
    }
  }

  /// Load Nafath request from cache
  Future<void> _loadNafathRequestFromCache() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final cachedData = _prefs!.getString(_nafathCacheKey);

      if (cachedData != null) {
        final Map<String, dynamic> data =
            jsonDecode(cachedData) as Map<String, dynamic>;
        final cachedAt =
            DateTime.fromMillisecondsSinceEpoch(data['cached_at'] as int);
        final now = DateTime.now();

        // Check if cache is not older than 1 hour
        if (now.difference(cachedAt).inHours < 1) {
          _cachedNationalId = data['national_id'] as String?;
          _cachedNafathRandomCode = data['random_code'] as String?;
          _nafathRequestCreatedAt =
              _parseServerDate(data['created_at']?.toString());
          _nafathFullNameAr = data['full_name_ar']?.toString();
          _nafathSignedFileUrl = data['signed_file_url']?.toString();
          final dynamic nafathRequest = data['nafath_request'];
          if (nafathRequest is Map<String, dynamic>) {
            _cachedNafathRequest = NafathRandomModel.fromJson(nafathRequest);
          } else {
            _cachedNafathRequest = null;
          }
          debugPrint(
              '✅ Nafath request loaded from cache for national ID: $_cachedNationalId');
        } else {
          // Cache expired, clear it
          await _clearNafathRequestCache();
          debugPrint('⏰ Nafath cache expired, cleared');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading Nafath request from cache: $e');
      await _clearNafathRequestCache();
    }
  }

  Future<void> _updateNafathCacheFromCheckStatus(
      NafathCheckStatusModel status, String nationalId) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final String? cachedData = _prefs!.getString(_nafathCacheKey);
      final Map<String, dynamic> data = cachedData != null
          ? (jsonDecode(cachedData) as Map<String, dynamic>)
          : <String, dynamic>{};

      data['national_id'] = nationalId;
      if (status.requestId != null) {
        data['request_id'] = status.requestId;
      }
      if (status.random != null) {
        data['random_code'] = status.random.toString();
      }
      if (status.createdAt != null && status.createdAt!.isNotEmpty) {
        data['created_at'] = status.createdAt;
      }
      if (status.fullNameAr != null && status.fullNameAr!.isNotEmpty) {
        data['full_name_ar'] = status.fullNameAr;
      }
      if (status.signedFileUrl != null) {
        data['signed_file_url'] = status.signedFileUrl.toString();
      }
      data['cached_at'] = DateTime.now().millisecondsSinceEpoch;

      _cachedNationalId = nationalId;
      if (status.random != null) {
        _cachedNafathRandomCode = status.random.toString();
      }
      _nafathRequestCreatedAt =
          _parseServerDate(status.createdAt) ?? _nafathRequestCreatedAt;
      _nafathFullNameAr = status.fullNameAr ?? _nafathFullNameAr;
      _nafathSignedFileUrl =
          status.signedFileUrl?.toString() ?? _nafathSignedFileUrl;

      await _prefs!.setString(_nafathCacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('? Error updating Nafath cache from checkStatus: $e');
    }
  }

  /// Clear Nafath request cache
  Future<void> _clearNafathRequestCache() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove(_nafathCacheKey);
      _cachedNafathRequest = null;
      _cachedNationalId = null;
      _cachedNafathRandomCode = null;
      _nafathRequestCreatedAt = null;
      _nafathFullNameAr = null;
      _nafathSignedFileUrl = null;
      debugPrint('🗑️ Nafath request cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing Nafath request cache: $e');
    }
  }

  /// Check if we have a valid cached Nafath request
  bool get hasCachedNafathRequest =>
      _cachedNafathRequest != null &&
      _cachedNationalId != null &&
      (_cachedNafathRequest!.requestId?.isNotEmpty ?? false);

  /// Get cached Nafath request for display
  NafathRandomModel? get cachedNafathRequest => _cachedNafathRequest;

  String getNafathDisplayCode() {
    return _cachedNafathRandomCode ?? '';
  }

  DateTime? get nafathRequestCreatedAt => _nafathRequestCreatedAt;
  String? get nafathFullNameAr => _nafathFullNameAr;
  String? get nafathSignedFileUrl => _nafathSignedFileUrl;
  Duration get nafathPendingElapsed {
    if (_nafathRequestCreatedAt == null) return Duration.zero;
    return DateTime.now().difference(_nafathRequestCreatedAt!);
  }

  bool get canManagePendingRequest => nafathPendingElapsed.inSeconds >= 120;
  String? get nafathFailReason => _nafathFailReason;
  bool get nafathCanInitiate => true;

  Future<bool> Nafath_send_retry(
      BuildContext context, String nationalId) async {
    _isLoading_OTP = true;
    update();
    try {
      final model = await kaidhaSubServiceInterface.Nafath_send_retry(
        context,
        nationalId,
      );
      if (!context.mounted || model == null) {
        return false;
      }

      _nafath_national_id = model;
      _cachedNafathRequest = model;
      _cachedNationalId = nationalId;
      _cachedNafathRandomCode = model.code;
      _nafathRequestCreatedAt =
          _parseServerDate(model.createdAt) ?? DateTime.now();

      _nafath_checkStatus = NafathCheckStatusModel(
        status: 'pending',
        requestId: model.requestId,
        nationalId: nationalId,
        createdAt: model.createdAt,
        random: int.tryParse(model.code ?? ''),
      );
      await _saveNafathRequestToCache();
      showCustomSnackBar('تم إرسال رمز جديد عبر نفاذ', isError: false);
      return true;
    } finally {
      _isLoading_OTP = false;
      update();
    }
  }

  Future<bool> Nafath_cancelRequest(
      BuildContext context, String nationalId) async {
    _isLoading_Status = true;
    update();
    try {
      final response = await kaidhaSubServiceInterface.Nafath_send_cancel(
        context,
        nationalId,
      );
      final bool ok = response.statusCode == 200 || response.statusCode == 201;
      if (ok) {
        await _clearNafathRequestCache();
        _nafath_checkStatus = NafathCheckStatusModel(
          status: 'cancelled',
          nationalId: nationalId,
        );
        _isShow = false;
        showCustomSnackBar('تم إلغاء طلب نفاذ', isError: false);
        update();
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      _isLoading_Status = false;
      update();
    }
  }

  //  ترقب حاله المستخدم State kaidha  =======================================================================
  //     =============================================

  Future SendState_kaidha(String status) async {
    try {
      final profileController = Get.find<ProfileController>();
      if (profileController.userInfoModel == null) {
        await profileController.getUserInfo();
      }
      final userInfo = profileController.userInfoModel;
      if (userInfo?.id == null) {
        debugPrint('User ID is null, cannot send kaidha state');
        return;
      }

      final int user_id = userInfo!.id!;
      final Map<String, dynamic> savedData = await getState_kaidha_SharedPre();

      return await kaidhaSubServiceInterface.SendState_kaidha(
          user_id, status, savedData);
    } catch (e) {
      debugPrint('Error sending kaidha state: $e');
      rethrow;
    }
  }

  // ===========

  /// Debounced save method - only saves after user stops typing
  void debouncedSaveState() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounceDelay, () {
      _performSave();
    });
  }

  /// Immediate save method for critical operations
  Future<void> saveState_kaidha_SharedPre() async {
    _saveTimer?.cancel();
    await _performSave();
  }

  /// Internal method to perform the actual save operation
  Future<void> _performSave() async {
    try {
      // Initialize SharedPreferences if not cached
      _prefs ??= await SharedPreferences.getInstance();
      const key = 'qidha';

      final Map<String, dynamic> currentData = {
        'firstname': firstname.text,
        'fathername': fathername.text,
        'grandfathername': grandfathername.text,
        'last_name': last_name.text,
        'birthDate': birthDate,
        'nationality': nationality,
        'marital_status': marital_status,
        'number_of_family_members': number_of_family_members.text,
        'national_id': identity_card_number.text,
        'mobile': phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : _getUserPhone(),
        'identity_card_number': identity_card_number.text,
        'house_type': house_type,
        'city': city,
        'neighborhood': neighborhood.text,
        'name_of_employer': name_of_employer.text,
        'total_salary': total_salary.text,
        'installments': Installments,
        'monthlyIncome': monthlyIncome.text,
        'salary_day': salary_day.text,
        'photo': All_files.isNotEmpty ? 'true' : 'false',
      };

      // Clean empty values
      currentData.removeWhere((key, value) {
        if (value == null) return true;
        if (value is String && value.trim().isEmpty) return true;
        return false;
      });

      // Skip save if data hasn't changed
      if (_lastSavedData != null && _mapsEqual(_lastSavedData!, currentData)) {
        return;
      }

      if (currentData.isEmpty) {
        return;
      }

      final String jsonString = jsonEncode(currentData);
      await _prefs!.setString(key, jsonString);
      _lastSavedData = Map.from(currentData);

      // Trigger debounced API call
      debouncedApiCall();
    } catch (e) {
      debugPrint('Error saving qidha data: $e');
    }
  }

  /// Check if two maps are equal
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final String key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  /// Debounced API call method
  void debouncedApiCall() {
    _apiTimer?.cancel();
    _apiTimer = Timer(_apiDebounceDelay, () {
      _performApiCall();
    });
  }

  /// Internal method to perform API call
  Future<void> _performApiCall() async {
    try {
      final status = _nafath_checkStatus?.status;
      if (status == 'pending' ||
          status == 'rejected' ||
          status == 'expired' ||
          status == 'cancelled' ||
          status == 'no_request') {
        debugPrint('Skipping registration-activity: status=$status');
        return;
      }
      await SendState_kaidha('in_progress');
    } catch (e) {
      debugPrint('Error in API call: $e');
    }
  }

  // ===========

  Future<Map<String, dynamic>> getState_kaidha_SharedPre() async {
    try {
      // Use cached SharedPreferences if available
      _prefs ??= await SharedPreferences.getInstance();
      const key = 'qidha';

      final String? jsonString = _prefs!.getString(key);

      if (jsonString == null) {
        return {};
      }

      try {
        final decoded = jsonDecode(jsonString);

        if (decoded is! Map<String, dynamic>) {
          return {};
        }

        return decoded;
      } catch (e) {
        debugPrint('Error decoding qidha data: $e');
        return {};
      }
    } catch (e) {
      debugPrint('Error getting qidha data: $e');
      return {};
    }
  }

  // ===========

  Future<void> clearState_kaidha_SharedPre() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      const key = 'qidha';

      await _prefs!.remove(key);
      _lastSavedData = null;
    } catch (e) {
      debugPrint('Error clearing qidha data: $e');
    }
  }

  // -----------------------------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    // Load cached Nafath request on controller initialization
    _loadNafathRequestFromCache();
  }

  void clearForm() {
    // Cancel any pending timers
    _saveTimer?.cancel();
    _apiTimer?.cancel();

    // Clear TextEditingControllers
    firstname.clear();
    fathername.clear();
    grandfathername.clear();
    last_name.clear();
    number_of_family_members.clear();
    identity_card_number.clear();
    phoneController.clear();
    neighborhood.clear();
    name_of_employer.clear();
    total_salary.clear();
    salary_day.clear();
    monthlyIncome.clear();
    jobSpecification = '';

    // Clear dropdowns / selected values
    birthDate = '';
    nationality = '';
    marital_status = '';
    end_date = '';
    house_type = '';
    city = '';
    Installments = '';

    // Clear selected files or lists
    All_files = [];

    // Clear Nafath cache when form is cleared
    _clearNafathRequestCache();

    // Reset error states if you use them
    isFirstNameEmpty = false;
    isFatherNameEmpty = false;
    isGrandFatherNameEmpty = false;
    isLastNameEmpty = false;
    isPhoneEmpty = false;
    isNumberOfFamilyEmpty = false;
    isIdentityCardEmpty = false;
    isNeighborhoodEmpty = false;
    isEmployerEmpty = false;
    isTotalSalaryEmpty = false;
    isBirthDateEmpty = false;
    isNationalityEmpty = false;
    isMaritalStatusEmpty = false;
    isEndDateEmpty = false;
    isMonthlyIncomeEmpty = false;

    // Call update to refresh UI if using GetX
    update();
  }
}
