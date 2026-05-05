import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/saved_recipient_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/transfer_request_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/transfer_response_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/validate_recipient_response_model.dart';
import 'package:sixam_mart/features/wallet_transfer/domain/services/wallet_transfer_service_interface.dart';

/// Controller for wallet transfer operations
/// Manages state and business logic for peer-to-peer transfers
class WalletTransferController extends GetxController implements GetxService {
  final WalletTransferServiceInterface walletTransferServiceInterface;

  WalletTransferController({required this.walletTransferServiceInterface});

  // State variables
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isValidating = false;
  bool get isValidating => _isValidating;

  bool _isTransferring = false;
  bool get isTransferring => _isTransferring;

  ValidatedUser? _validatedRecipient;
  ValidatedUser? get validatedRecipient => _validatedRecipient;

  List<SavedRecipientModel>? _savedRecipients;
  List<SavedRecipientModel>? get savedRecipients => _savedRecipients;

  String? _lastError;
  String? get lastError => _lastError;

  /// Validates recipient phone number
  Future<bool> validateRecipient(String phone) async {
    debugPrint('[WALLET_TRANSFER][RECIPIENT_INPUT] raw=$phone');
    _isValidating = true;
    _validatedRecipient = null;
    _lastError = null;
    update();

    try {
      final String normalizedPhone = _normalizePhoneNumber(phone);
      debugPrint(
          '[WALLET_TRANSFER][PHONE_NORMALIZED] raw=$phone normalized=$normalizedPhone');
      debugPrint('[WALLET_TRANSFER][VALIDATE_START] phone=$normalizedPhone');

      final ValidateRecipientResponseModel? response =
          await walletTransferServiceInterface
              .validateRecipient(normalizedPhone);

      if (response != null &&
          response.success == true &&
          response.user != null) {
        _validatedRecipient = response.user;
        debugPrint(
            '[WALLET_TRANSFER][VALIDATE_RESPONSE] success=true recipientId=${response.user?.id} name=${response.user?.name} phone=${response.user?.phone}');
        _isValidating = false;
        update();
        return true;
      } else {
        _lastError = response?.errorCode ??
            _inferValidationErrorCode(response?.message);
        debugPrint(
            '[WALLET_TRANSFER][VALIDATE_ERROR] status=failed code=${_lastError ?? 'UNKNOWN'} message=${response?.message ?? ''}');
        showCustomSnackBar(getErrorMessage(_lastError!));
        _isValidating = false;
        update();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error validating recipient: $e');
      _lastError = 'VALIDATION_FAILED';
      debugPrint(
          '[WALLET_TRANSFER][VALIDATE_ERROR] status=exception code=$_lastError message=$e');
      showCustomSnackBar(getErrorMessage(_lastError!));
      _isValidating = false;
      update();
      return false;
    }
  }

  /// Normalizes phone number to ensure it starts with +966
  String _normalizePhoneNumber(String phone) {
    // Remove all spaces and special characters except +
    // ignore: deprecated_member_use
    final String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If already starts with +966, return as is
    if (cleanPhone.startsWith('+966')) {
      return cleanPhone;
    }

    // If starts with 966 (without +), add +
    if (cleanPhone.startsWith('966')) {
      return '+$cleanPhone';
    }

    // If starts with 05, remove the 0 and add +966
    if (cleanPhone.startsWith('05')) {
      return '+966${cleanPhone.substring(1)}';
    }

    // If starts with 5 (local format), add +966
    if (cleanPhone.startsWith('5')) {
      return '+966$cleanPhone';
    }

    // If starts with 0, remove 0 and add +966
    if (cleanPhone.startsWith('0')) {
      return '+966${cleanPhone.substring(1)}';
    }

    // Otherwise, assume it's a local number and add +966
    return '+966$cleanPhone';
  }

  /// Executes money transfer
  Future<TransferResponseModel?> executeTransfer(
      TransferRequestModel request) async {
    _isTransferring = true;
    _lastError = null;
    update();

    try {
      final normalizedRequest = TransferRequestModel(
        recipientPhone: _normalizePhoneNumber(request.recipientPhone),
        amount: request.amount,
        paymentSource: request.paymentSource,
        saveRecipient: request.saveRecipient,
        recipientNickname: request.recipientNickname,
        message: request.message,
      );
      debugPrint(
          '[WALLET_TRANSFER][TRANSFER_START] recipientPhone=${normalizedRequest.recipientPhone} amount=${normalizedRequest.amount}');

      final TransferResponseModel? response =
          await walletTransferServiceInterface
              .executeTransfer(normalizedRequest);

      _isTransferring = false;
      update();

      if (response != null && response.success == true) {
        debugPrint('[WALLET_TRANSFER][TRANSFER_RESPONSE] success=true');
        // Update user's wallet balance
        await _updateWalletBalance(
            request.paymentSource, response.data?.senderNewBalance);

        // Refresh saved recipients if user chose to save
        if (request.saveRecipient) {
          await getSavedRecipients();
        }

        return response;
      } else {
        debugPrint('[WALLET_TRANSFER][TRANSFER_RESPONSE] success=false');
        _lastError = response?.errorCode ?? 'TRANSFER_FAILED';
        _showTransferErrorDialog(response);
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error executing transfer: $e');
      debugPrint('[WALLET_TRANSFER][TRANSFER_RESPONSE] success=false');
      _lastError = 'TRANSFER_FAILED';
      showCustomSnackBar(getErrorMessage(_lastError!));
      _isTransferring = false;
      update();
      return null;
    }
  }

  /// Updates wallet balance after successful transfer
  Future<void> _updateWalletBalance(
      String paymentSource, double? newBalance) async {
    if (newBalance == null) return;

    if (paymentSource == 'wallet') {
      // Update regular wallet balance
      await Get.find<ProfileController>().getUserInfo();
    } else if (paymentSource == 'wallet_qidha') {
      // Update Qidha wallet balance
      await Get.find<KaidhaSubscriptionController>().get_Wallet_Kaidh();
    }
  }

  /// Shows detailed error dialog for transfer failures
  void _showTransferErrorDialog(TransferResponseModel? response) {
    if (response == null) {
      showCustomSnackBar(getErrorMessage('TRANSFER_FAILED'));
      return;
    }

    String errorMessage = response.message ??
        getErrorMessage(response.errorCode ?? 'TRANSFER_FAILED');

    // Add additional details for specific errors
    if (response.errorCode == 'INSUFFICIENT_BALANCE' ||
        response.errorCode == 'INSUFFICIENT_QIDHA_BALANCE') {
      errorMessage +=
          '\n${'available_balance'.tr}: ${response.availableBalance?.toStringAsFixed(2)} ${'currency_symbol'.tr}';
      errorMessage +=
          '\n${'required_amount'.tr}: ${response.requiredAmount?.toStringAsFixed(2)} ${'currency_symbol'.tr}';
    } else if (response.errorCode == 'DAILY_LIMIT_EXCEEDED') {
      errorMessage +=
          '\n${'daily_limit'.tr}: ${response.dailyLimit?.toStringAsFixed(2)} ${'currency_symbol'.tr}';
      errorMessage +=
          '\n${'already_spent'.tr}: ${response.alreadySpent?.toStringAsFixed(2)} ${'currency_symbol'.tr}';
      errorMessage +=
          '\n${'remaining'.tr}: ${response.remaining?.toStringAsFixed(2)} ${'currency_symbol'.tr}';
    }

    showCustomSnackBar(errorMessage);
  }

  /// Gets list of saved recipients
  Future<void> getSavedRecipients() async {
    _isLoading = true;
    update();

    try {
      final List<SavedRecipientModel>? recipients =
          await walletTransferServiceInterface.getSavedRecipients();

      _savedRecipients = recipients ?? [];
      _isLoading = false;
      update();
    } catch (e) {
      debugPrint('❌ Error getting saved recipients: $e');
      _savedRecipients = [];
      _isLoading = false;
      update();
    }
  }

  /// Adds a new saved recipient
  Future<bool> addSavedRecipient(String phone, String? nickname) async {
    try {
      // Normalize phone number before saving
      final String normalizedPhone = _normalizePhoneNumber(phone);

      final SavedRecipientModel? recipient =
          await walletTransferServiceInterface.addSavedRecipient(
              normalizedPhone, nickname);

      if (recipient != null) {
        await getSavedRecipients();
        showCustomSnackBar('recipient_saved_successfully'.tr, isError: false);
        return true;
      } else {
        showCustomSnackBar('failed_to_save_recipient'.tr);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error adding saved recipient: $e');
      showCustomSnackBar('failed_to_save_recipient'.tr);
      return false;
    }
  }

  /// Deletes a saved recipient
  Future<bool> deleteSavedRecipient(int recipientId) async {
    try {
      await walletTransferServiceInterface.deleteSavedRecipient(recipientId);
      await getSavedRecipients();
      showCustomSnackBar('recipient_deleted_successfully'.tr, isError: false);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting saved recipient: $e');
      showCustomSnackBar('failed_to_delete_recipient'.tr);
      return false;
    }
  }

  /// Checks if user can transfer the specified amount
  bool canTransfer(double amount, String paymentSource) {
    if (amount <= 0) return false;

    if (paymentSource == 'wallet') {
      final double balance =
          Get.find<ProfileController>().userInfoModel?.walletBalance ?? 0;
      return amount <= balance;
    }

    if (paymentSource == 'wallet_qidha') {
      final wallet =
          Get.find<KaidhaSubscriptionController>().walletKaidhaModel?.wallet;

      final double availableBalance = wallet?.availableBalance is num
          ? (wallet!.availableBalance as num).toDouble()
          : double.tryParse(wallet?.availableBalance?.toString() ?? '0') ?? 0;

      return amount <= availableBalance;
    }

    // ✅ fallback mandatory
    return false;
  }

  /// Gets available balance for the specified payment source
  double getAvailableBalance(String paymentSource) {
    if (paymentSource == 'wallet') {
      return Get.find<ProfileController>().userInfoModel?.walletBalance ?? 0;
    } else if (paymentSource == 'wallet_qidha') {
      final balanceValue = Get.find<KaidhaSubscriptionController>()
          .walletKaidhaModel
          ?.wallet
          ?.availableBalance;
      if (balanceValue != null) {
        return balanceValue is double
            ? balanceValue
            : (double.tryParse(balanceValue.toString()) ?? 0);
      }
      return 0;
    }
    return 0;
  }

  /// Gets user-friendly error message for error code
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'USER_NOT_FOUND':
        return 'لا يوجد مستخدم بهذا الرقم';
      case 'USER_INACTIVE':
        return 'هذا المستخدم غير متاح للتحويل';
      case 'CANNOT_TRANSFER_TO_SELF':
        return 'لا يمكنك التحويل لنفسك';
      case 'INSUFFICIENT_BALANCE':
        return 'insufficient_balance'.tr;
      case 'INSUFFICIENT_QIDHA_BALANCE':
        return 'insufficient_qidha_balance'.tr;
      case 'PURCHASE_LIMIT_EXCEEDED':
        return 'purchase_limit_exceeded'.tr;
      case 'DAILY_LIMIT_EXCEEDED':
        return 'daily_limit_exceeded'.tr;
      case 'QIDHA_WALLET_NOT_FOUND':
        return 'qidha_wallet_not_found'.tr;
      case 'QIDHA_WALLET_INACTIVE':
        return 'qidha_wallet_inactive'.tr;
      case 'RECIPIENT_ALREADY_SAVED':
        return 'recipient_already_saved'.tr;
      case 'RECIPIENT_NOT_FOUND':
        return 'recipient_not_found'.tr;
      case 'TRANSFER_FAILED':
        return 'transfer_failed'.tr;
      case 'VALIDATION_FAILED':
        return 'validation_failed'.tr;
      default:
        return 'something_went_wrong'.tr;
    }
  }

  String _inferValidationErrorCode(String? message) {
    final String normalizedMessage = (message ?? '').toLowerCase();
    if (normalizedMessage.contains('self')) {
      return 'CANNOT_TRANSFER_TO_SELF';
    }
    if (normalizedMessage.contains('inactive')) {
      return 'USER_INACTIVE';
    }
    if (normalizedMessage.contains('not found')) {
      return 'USER_NOT_FOUND';
    }
    return 'USER_NOT_FOUND';
  }

  /// Clears validated recipient
  void clearValidatedRecipient() {
    _validatedRecipient = null;
    _lastError = null;
    update();
  }

  /// Resets controller state
  void resetState() {
    _isLoading = false;
    _isValidating = false;
    _isTransferring = false;
    _validatedRecipient = null;
    _lastError = null;
    update();
  }
}
