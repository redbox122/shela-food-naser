import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/loyalty/domain/services/loyalty_service_interface.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';

class LoyaltyController extends GetxController implements GetxService {
  final LoyaltyServiceInterface loyaltyServiceInterface;

  LoyaltyController({required this.loyaltyServiceInterface});

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

  Future<void> getLoyaltyTransactionList(String offset, bool reload) async {
    _hasTransactionError = false;
    if (kDebugMode) {
      debugPrint('🎁 [LoyaltyController] getLoyaltyTransactionList() called');
      debugPrint('   📄 offset: $offset');
      debugPrint('   🔄 reload: $reload');
      debugPrint('   📋 Current transactions: ${_transactionList?.length ?? 0}');
    }
    
    if(offset == '1' || reload) {
      if (kDebugMode) {
        debugPrint('🎁 [LoyaltyController] Resetting transaction list (offset=1 or reload=true)');
      }
      _offsetList = [];
      _offset = 1;
      _transactionList = null;
      if(reload) {
        update();
      }
    }
    if (!_offsetList.contains(offset)) {
      _offsetList.add(offset);
      if (kDebugMode) {
        debugPrint('🎁 [LoyaltyController] Calling API for loyalty transactions...');
        debugPrint('   📡 API: /api/v1/customer/loyalty-point/transactions?offset=$offset&limit=10');
      }
      
      TransactionModel? transactionModel;
      try {
        transactionModel =
            await loyaltyServiceInterface.getLoyaltyTransactionList(offset);
      } catch (e) {
        _hasTransactionError = true;
        _isLoading = false;
        if (kDebugMode) {
          debugPrint(
              '🎁 [LoyaltyController] ❌ Exception in getLoyaltyTransactionList: $e');
        }
        update();
        return;
      }

      if (transactionModel != null) {
        if (offset == '1') {
          _transactionList = [];
        }
        final previousCount = _transactionList?.length ?? 0;
        _transactionList!.addAll(transactionModel.data!);
        _pageSize = transactionModel.totalSize;

        if (kDebugMode) {
          debugPrint('🎁 [LoyaltyController] Loyalty transactions loaded successfully');
          debugPrint('   ✅ New transactions: ${transactionModel.data?.length ?? 0}');
          debugPrint('   📊 Total transactions: ${_transactionList!.length} (was $previousCount)');
          debugPrint('   📄 Total pages: ${_pageSize ?? 0}');
        }

        _isLoading = false;
        update();
      } else {
        _hasTransactionError = true;
        if (kDebugMode) {
          debugPrint('🎁 [LoyaltyController] ⚠️ API returned null transaction model');
        }
        _isLoading = false;
        update();
      }
    } else {
      if (kDebugMode) {
        debugPrint('🎁 [LoyaltyController] ⏭️ Offset $offset already loaded - skipping duplicate request');
      }
      if(isLoading) {
        _isLoading = false;
        update();
      }
    }
  }

  Future<void> pointToWallet(int point) async {
    if (kDebugMode) {
      debugPrint('🎁 [LoyaltyController] pointToWallet() called');
      debugPrint('   🎯 points: $point');
    }
    
    _isLoading = true;
    update();
    
    if (kDebugMode) {
      debugPrint('🎁 [LoyaltyController] Calling API to convert points to wallet...');
      debugPrint('   📡 API: /api/v1/customer/loyalty-point/convert-to-wallet');
    }
    
    final Response response = await loyaltyServiceInterface.pointToWallet(point: point);
    
    if (kDebugMode) {
      debugPrint('🎁 [LoyaltyController] Convert points API response received');
      debugPrint('   📊 statusCode: ${response.statusCode}');
    }
    
    if (response.statusCode == 200) {
      if (kDebugMode) {
        debugPrint('🎁 [LoyaltyController] ✅ Points converted successfully');
      }
      Get.back();
      getLoyaltyTransactionList('1', true);
      Get.find<ProfileController>().getUserInfo();
      showCustomSnackBar('converted_successfully_transfer_to_your_wallet'.tr, isError: false);
    } else {
      if (kDebugMode) {
        debugPrint('🎁 [LoyaltyController] ❌ Failed to convert points');
        debugPrint('   📊 statusCode: ${response.statusCode}');
        debugPrint('   📋 response: ${response.body}');
      }
    }
    _isLoading = false;
    update();
  }


  void setOffset(int offset) {
    _offset = offset;
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

}