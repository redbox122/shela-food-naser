import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/saved_recipient_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/transfer_request_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/transfer_response_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/validate_recipient_response_model.dart';

/// Service interface for wallet transfer business logic
/// Defines contract for transfer operations
abstract class WalletTransferServiceInterface {
  /// Validates recipient phone number
  Future<ValidateRecipientResponseModel?> validateRecipient(String phone);
  
  /// Executes money transfer
  Future<TransferResponseModel?> executeTransfer(TransferRequestModel request);
  
  /// Gets list of saved recipients
  Future<List<SavedRecipientModel>?> getSavedRecipients();
  
  /// Adds a new saved recipient
  Future<SavedRecipientModel?> addSavedRecipient(String phone, String? nickname);
  
  /// Deletes a saved recipient
  Future<Response> deleteSavedRecipient(int recipientId);
}






