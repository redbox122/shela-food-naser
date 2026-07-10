import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
import 'package:sixam_mart/features/payment/domain/services/myfatoorah_service.dart';
import 'package:sixam_mart/features/payment/domain/repositories/myfatoorah_repository.dart';
import 'package:sixam_mart/features/payment/domain/utils/myfatoorah_mapper.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet/domain/models/wallet_filter_body_model.dart';
import 'package:sixam_mart/features/wallet/domain/models/fund_bonus_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:universal_html/html.dart' as html;
import 'package:sixam_mart/features/wallet/domain/services/wallet_service_interface.dart';
import 'dart:io';

import '../../../common/widgets/custom_snackbar.dart';

class WalletController extends GetxController implements GetxService {
  final WalletServiceInterface walletServiceInterface;
  WalletController({required this.walletServiceInterface});

  List<Transaction>? _transactionList;
  List<Transaction>? get transactionList => _transactionList;

  List<String> _offsetList = [];

  int _offset = 1;
  int get offset => _offset;

  int? _pageSize;
  int? get popularPageSize => _pageSize;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasTransactionError = false;
  bool get hasTransactionError => _hasTransactionError;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  bool _amountEmpty = true;
  bool get amountEmpty => _amountEmpty;

  List<FundBonusModel>? _fundBonusList;
  List<FundBonusModel>? get fundBonusList => _fundBonusList;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  String _type = 'all';
  String get type => _type;

  List<WalletFilterBodyModel> _walletFilterList = [];
  List<WalletFilterBodyModel> get walletFilterList => _walletFilterList;

  // MyFatoorah payment methods
  List<MFPaymentMethod> _paymentMethods = [];
  List<MFPaymentMethod> get paymentMethods => _paymentMethods;

  bool _isLoadingPaymentMethods = false;
  bool get isLoadingPaymentMethods => _isLoadingPaymentMethods;
  bool _isPaymentMethodsLoadInProgress = false;

  MFPaymentMethod? _selectedPaymentMethod;
  MFPaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;

  void setWalletFilerType(String type, {bool isUpdate = true}) {
    _type = type;
    if (isUpdate) {
      update();
    }
  }

  void insertFilterList() {
    _walletFilterList = [];
    for (int i = 0; i < AppConstants.walletTransactionSortingList.length; i++) {
      _walletFilterList.add(WalletFilterBodyModel.fromJson(
          AppConstants.walletTransactionSortingList[i]));
    }
  }

  void changeDigitalPaymentName(String name, {bool isUpdate = true}) {
    _digitalPaymentName = name;
    if (isUpdate) {
      update();
    }
  }

  void setSelectedPaymentMethod(MFPaymentMethod? paymentMethod,
      {bool isUpdate = true}) {
    _selectedPaymentMethod = paymentMethod;
    if (isUpdate) {
      update();
    }
  }

  /// Initialize MyFatoorah SDK for wallet payments
  Future<void> initializeMyFatoorah() async {
    try {
      final String token = AppConstants.useMyFatoorahTestMode
          ? AppConstants.myFatoorahTestToken
          : AppConstants.myFatoorahLiveToken;

      if (token.isEmpty) {
        debugPrint('❌ MyFatoorah token is empty! Cannot initialize.');
        return;
      }

      await MFSDK.init(
        token,
        MFCountry.SAUDIARABIA,
        AppConstants.useMyFatoorahTestMode
            ? MFEnvironment.TEST
            : MFEnvironment.LIVE,
      );
      debugPrint('✅ MyFatoorah SDK initialized for wallet payments');
    } catch (e) {
      debugPrint('❌ Error initializing MyFatoorah SDK: $e');
    }
  }

  /// Load MyFatoorah payment methods for wallet add fund
  /// Now uses backend endpoint instead of direct SDK call
  Future<void> loadPaymentMethodsForWallet(double amount) async {
    if (_isPaymentMethodsLoadInProgress) {
      debugPrint('[ADD_FUND_DIALOG][DUPLICATE_LOAD_BLOCKED]');
      return;
    }
    _isPaymentMethodsLoadInProgress = true;
    _isLoadingPaymentMethods = true;
    _safeUpdate();

    try {
      debugPrint('🔄 Loading payment methods from backend for wallet - Amount: $amount SAR');

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
        final Map<String, dynamic> responseData = response.body as Map<String, dynamic>;
        
        if (responseData['success'] == true && responseData['data'] != null) {
          // Map backend response to MFPaymentMethod objects
          final List<dynamic> backendMethods = responseData['data'] as List<dynamic>;
          _paymentMethods = MyFatoorahMapper.mapBackendResponseToPaymentMethods(backendMethods);

          // Filter payment methods based on platform
          _paymentMethods = _filterPaymentMethodsByPlatform(_paymentMethods);

          if (_paymentMethods.isEmpty) {
            debugPrint(
                '⚠️ WARNING: Backend returned empty payment methods array for wallet');
            debugPrint('   Amount: $amount SAR, Currency: SAR');
            debugPrint('   Response: ${responseData.toString()}');
            debugPrint('   Backend returned success=true but data array is empty');
            debugPrint('   ⚠️ This may indicate a MyFatoorah API issue - check Laravel logs');
          } else {
            debugPrint(
                '✅ Loaded ${_paymentMethods.length} payment methods for wallet from backend');
          }
        } else {
          debugPrint("❌ Backend response indicates failure: ${responseData['message']}");
          debugPrint('   Amount: $amount SAR, Currency: SAR');
          debugPrint('   Full response: ${responseData.toString()}');
          _paymentMethods = [];
        }
      } else {
        // Only treat 4xx and 5xx as errors (304 is already handled above)
        debugPrint('❌ Backend request failed with status: ${response.statusCode}');
        _paymentMethods = [];
      }
    } catch (e) {
      debugPrint('❌ Error loading payment methods from backend: $e');
      _paymentMethods = [];
    }

    _isLoadingPaymentMethods = false;
    _isPaymentMethodsLoadInProgress = false;
    _safeUpdate();
  }

  void _safeUpdate() {
    if (SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks ||
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        update();
      });
      return;
    }
    update();
  }

  /// Filter payment methods based on platform
  /// Apple Pay remains enabled
  /// iOS: Show Apple Pay + other methods (hide Google Pay)
  List<MFPaymentMethod> _filterPaymentMethodsByPlatform(
      List<MFPaymentMethod> paymentMethods) {
    return paymentMethods.where((method) {
      final methodCode = method.paymentMethodCode?.toLowerCase() ?? '';
      final methodEn = method.paymentMethodEn?.toLowerCase() ?? '';
      final methodAr = method.paymentMethodAr?.toLowerCase() ?? '';

      // On Android, keep all methods visible (including Apple Pay).
      if ((!kIsWeb && Platform.isAndroid)) {
        return true;
      }

      // On iOS, hide Google Pay methods but show Apple Pay
      if ((!kIsWeb && Platform.isIOS)) {
        final isGooglePay = methodCode.contains('gp') ||
            methodEn.contains('google') ||
            methodAr.contains('جوجل') ||
            methodAr.contains('google');

        if (isGooglePay) {
          debugPrint('🚫 iOS: Hiding Google Pay - ${method.paymentMethodAr}');
          return false;
        }
        return true;
      }

      // For other platforms, show all methods
      return true;
    }).toList();
  }

  void isTextFieldEmpty(String value, {bool isUpdate = true}) {
    _amountEmpty = value.isNotEmpty;
    if (isUpdate) {
      update();
    }
  }

  void setOffset(int offset) {
    _offset = offset;
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  Future<void> getWalletTransactionList(
      String offset, bool reload, String walletType) async {
    _hasTransactionError = false;
    if (kDebugMode) {
      debugPrint('💰 [WalletController] getWalletTransactionList() called');
      debugPrint('   📄 offset: $offset');
      debugPrint('   🔄 reload: $reload');
      debugPrint('   📊 walletType: $walletType');
      debugPrint('   📋 Current transactions: ${_transactionList?.length ?? 0}');
    }
    
    if (offset == '1' || reload) {
      if (kDebugMode) {
        debugPrint('💰 [WalletController] Resetting transaction list (offset=1 or reload=true)');
      }
      _offsetList = [];
      _offset = 1;
      _transactionList = null;
      if (reload) {
        update();
      }
    }
    if (!_offsetList.contains(offset)) {
      _offsetList.add(offset);
      if (kDebugMode) {
        debugPrint('💰 [WalletController] Calling API for wallet transactions...');
        debugPrint('   📡 API: /api/v1/customer/wallet/transactions?offset=$offset&limit=10&type=$walletType');
      }
      
      TransactionModel? transactionModel;
      try {
        transactionModel = await walletServiceInterface
            .getWalletTransactionList(offset, walletType);
      } catch (e) {
        _hasTransactionError = true;
        _isLoading = false;
        if (kDebugMode) {
          debugPrint('💰 [WalletController] ❌ Exception in getWalletTransactionList: $e');
        }
        update();
        return;
      }

      if (transactionModel != null) {
        if (offset == '1') {
          _transactionList = [];
        }
        final previousCount = _transactionList?.length ?? 0;
        
        // ✅ FIX: Ensure transactionModel.data is not null and not empty before adding
        if (transactionModel.data != null && transactionModel.data!.isNotEmpty) {
          _transactionList!.addAll(transactionModel.data!);
          if (kDebugMode) {
            debugPrint('💰 [WalletController] Added ${transactionModel.data!.length} transactions to list');
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ [WalletController] transactionModel.data is null or empty!');
            debugPrint('   - transactionModel.data: ${transactionModel.data}');
            debugPrint('   - transactionModel.data?.length: ${transactionModel.data?.length ?? "null"}');
          }
        }
        _pageSize = transactionModel.totalSize;

        if (kDebugMode) {
          debugPrint('💰 [WalletController] Wallet transactions loaded successfully');
          debugPrint('   ✅ New transactions: ${transactionModel.data?.length ?? 0}');
          debugPrint('   📊 Total transactions: ${_transactionList!.length} (was $previousCount)');
          debugPrint('   📄 Total pages: ${_pageSize ?? 0}');
          debugPrint('   📋 Page size: ${_pageSize ?? 0}');
          debugPrint('🔍 [WalletController] State After Load:');
          debugPrint('   - _transactionList.length: ${_transactionList?.length ?? 0}');
          debugPrint('   - _transactionList.isEmpty: ${_transactionList?.isEmpty ?? true}');
          debugPrint('   - _transactionList == null: ${_transactionList == null}');
          debugPrint('   - transactionList getter: ${transactionList?.length ?? 0}');
          if (_transactionList != null && _transactionList!.isNotEmpty) {
            debugPrint('   - First transaction ID: ${_transactionList!.first.transactionId ?? "N/A"}');
            debugPrint('   - First transaction type: ${_transactionList!.first.transactionType ?? "N/A"}');
          }
        }

        _isLoading = false;
        update();
        
        if (kDebugMode) {
          debugPrint('   - update() called ✅');
          debugPrint('   - Final state check: _transactionList.length = ${_transactionList?.length ?? 0}');
        }
      } else {
        _hasTransactionError = true;
        if (kDebugMode) {
          debugPrint('💰 [WalletController] ⚠️ API returned null transaction model');
        }
        _isLoading = false;
        update();
      }
    } else {
      if (kDebugMode) {
        debugPrint('💰 [WalletController] ⏭️ Offset $offset already loaded - skipping duplicate request');
      }
      if (isLoading) {
        _isLoading = false;
        update();
      }
    }
  }

  Future<void> addFundToWallet(double amount, String paymentMethod) async {
    if (kDebugMode) {
      debugPrint('💰 [WalletController] addFundToWallet() called');
      debugPrint('   💵 amount: $amount SAR');
      debugPrint('   💳 paymentMethod: $paymentMethod');
    }
    
    _isLoading = true;
    update();
    
    if (kDebugMode) {
      debugPrint('💰 [WalletController] Calling API to add fund to wallet...');
      debugPrint('   📡 API: /api/v1/customer/wallet/add-fund');
    }
    
    final dynamic responseResult =
        await walletServiceInterface.addFundToWallet(amount, paymentMethod);
    final Response response = responseResult is Response ? responseResult : const Response();
    
    if (kDebugMode) {
      debugPrint('💰 [WalletController] Add fund API response received');
      debugPrint('   📊 statusCode: ${response.statusCode}');
    }
    
    if (response.statusCode == 200) {
      final String redirectUrl = (response.body as Map<String, dynamic>)['redirect_link'] as String? ?? '';
      if (kDebugMode) {
        debugPrint('💰 [WalletController] ✅ Fund added successfully - redirecting to payment');
        debugPrint('   🔗 redirectUrl: $redirectUrl');
      }
      Get.back();
      if (GetPlatform.isWeb) {
        html.window.open(redirectUrl, '_self');
      } else {
        Get.toNamed(RouteHelper.getPaymentRoute('0', 0, '', 0, false, '',
            addFundUrl: redirectUrl, guestId: ''));
      }
    } else {
      if (kDebugMode) {
        debugPrint('💰 [WalletController] ❌ Failed to add fund to wallet');
        debugPrint('   📊 statusCode: ${response.statusCode}');
        debugPrint('   📋 response: ${response.body}');
      }
      Get.back();
      _isLoading = false;
      update();

      showCustomSnackBar((response.body as Map<String, dynamic>)['errors']?['message'] as String? ?? 'Error');
    }
    _isLoading = false;
    update();
  }

  /// Process MyFatoorah payment for wallet add fund
  Future<bool> processMyFatoorahWalletPayment(double amount) async {
    if (_selectedPaymentMethod == null) {
      showCustomSnackBar('please_select_payment_method'.tr);
      return false;
    }

    _isLoading = true;
    update();

    try {
      // Initialize MyFatoorah if not already done
      await initializeMyFatoorah();

      // Create payment request
      final request = MFExecutePaymentRequest(
        paymentMethodId: _selectedPaymentMethod!.paymentMethodId!,
        invoiceValue: amount,
      );

      // Execute payment
      String? invoiceId;
      bool paymentSuccess = false;

      await MFSDK.executePayment(request, MFLanguage.ARABIC,
          (receivedInvoiceId) {
        debugPrint(
            'MyFatoorah wallet payment response - Invoice ID: $receivedInvoiceId');

        if (receivedInvoiceId.isNotEmpty) {
          invoiceId = receivedInvoiceId;
          paymentSuccess = true;
          debugPrint('✅ MyFatoorah wallet payment successful: $invoiceId');
        }
      });

      if (paymentSuccess && invoiceId != null) {
        // Call backend to add fund to wallet
        final dynamic walletResponseResult = await walletServiceInterface.addFundToWallet(
            amount, _selectedPaymentMethod!.paymentMethodEn ?? 'myfatoorah');
        final Response walletResponse = walletResponseResult is Response ? walletResponseResult : const Response();

        if (walletResponse.statusCode == 200) {
          // Refresh user info to update wallet balance (force: bypass ETag/304).
          Get.find<ProfileController>().getUserInfo(forceRefresh: true);
          showCustomSnackBar('fund_added_successfully'.tr, isError: false);
          return true;
        } else {
          showCustomSnackBar((walletResponse.body as Map<String, dynamic>)['errors']?['message']?.toString() ?? 'Error');
          return false;
        }
      } else {
        showCustomSnackBar('payment_failed'.tr);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error processing MyFatoorah wallet payment: $e');
      showCustomSnackBar('payment_error'.tr);
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> getWalletBonusList({bool isUpdate = true}) async {
    if (kDebugMode) {
      debugPrint('💰 [WalletController] getWalletBonusList() called');
      debugPrint('   🔄 isUpdate: $isUpdate');
    }
    
    _isLoading = true;
    if (isUpdate) {
      update();
    }

    if (kDebugMode) {
      debugPrint('💰 [WalletController] Calling API for wallet bonuses...');
      debugPrint('   📡 API: /api/v1/customer/wallet/bonuses');
    }
    
    try {
      final List<FundBonusModel>? bonuses =
          await walletServiceInterface.getWalletBonusList();
      if (bonuses != null) {
        _fundBonusList = [];
        _fundBonusList!.addAll(bonuses);
        if (kDebugMode) {
          debugPrint('💰 [WalletController] Wallet bonuses loaded successfully');
          debugPrint('   ✅ Bonuses count: ${bonuses.length}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('💰 [WalletController] ⚠️ API returned null bonus list');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('💰 [WalletController] ❌ Error loading wallet bonuses: $e');
        debugPrint('   📋 Stack trace: $stackTrace');
      }
    }
    
    _isLoading = false;
    if (isUpdate) {
      update();
    }
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) {
      update();
    }
  }

  void setWalletAccessToken(String accessToken) {
    walletServiceInterface.setWalletAccessToken(accessToken);
  }

  String getWalletAccessToken() {
    return walletServiceInterface.getWalletAccessToken();
  }

  Future<bool> requestExchange(number) async {
    final dynamic responseResult = await walletServiceInterface.requestExchange(number as String);
    final Response response = responseResult is Response ? responseResult : const Response();
    return response.statusCode == 200;
  }

  Future<bool> Exchange(number, otp, userOtp, money) async {
    final dynamic responseResult = await walletServiceInterface.exchangeWallet(
        number as String, otp as String, userOtp as String, money as String);
    final Response response = responseResult is Response ? responseResult : const Response();

    if (response.statusCode != 200) {
      showCustomSnackBar(
          'تاكد من ال otp الخاص بك و otp الخاص بالحساب الاخر وتوافر المبلغ المحول معك');
    }
    Get.find<ProfileController>().getUserInfo(forceRefresh: true);
    return response.statusCode == 200;
  }
}
