import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/saved_recipient_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/transfer_request_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/transfer_response_model.dart';
import 'package:sixam_mart/features/wallet_transfer/data/models/validate_recipient_response_model.dart';
import 'package:sixam_mart/features/wallet_transfer/domain/repositories/wallet_transfer_repository_interface.dart';
import 'package:sixam_mart/features/wallet_transfer/domain/services/wallet_transfer_service_interface.dart';

/// Service implementation for wallet transfer operations
/// Handles business logic and data transformation
class WalletTransferService implements WalletTransferServiceInterface {
  final WalletTransferRepositoryInterface walletTransferRepositoryInterface;

  WalletTransferService({required this.walletTransferRepositoryInterface});

  @override
  Future<ValidateRecipientResponseModel?> validateRecipient(String phone) async {
    final Response response = await walletTransferRepositoryInterface.validateRecipient(phone);
    if ((response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 404) &&
        response.body is Map<String, dynamic>) {
      return ValidateRecipientResponseModel.fromJson(response.body as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<TransferResponseModel?> executeTransfer(TransferRequestModel request) async {
    final Response response = await walletTransferRepositoryInterface.executeTransfer(request.toJson());
    if (response.statusCode == 200 || response.statusCode == 400) {
      return TransferResponseModel.fromJson(response.body as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<List<SavedRecipientModel>?> getSavedRecipients() async {
    final Response response = await walletTransferRepositoryInterface.getSavedRecipients();
    if (response.statusCode == 200) {
      final List<SavedRecipientModel> recipients = [];
      if (response.body['data'] != null) {
        response.body['data'].forEach((recipient) {
          recipients.add(SavedRecipientModel.fromJson(recipient as Map<String, dynamic>));
        });
      }
      return recipients;
    }
    return null;
  }

  @override
  Future<SavedRecipientModel?> addSavedRecipient(String phone, String? nickname) async {
    final Response response = await walletTransferRepositoryInterface.addSavedRecipient(phone, nickname);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body['data'] != null) {
        return SavedRecipientModel.fromJson((response.body as Map<String, dynamic>)['data'] as Map<String, dynamic>);
      }
    }
    return null;
  }

  @override
  Future<Response> deleteSavedRecipient(int recipientId) async {
    return await walletTransferRepositoryInterface.deleteSavedRecipient(recipientId);
  }
}






