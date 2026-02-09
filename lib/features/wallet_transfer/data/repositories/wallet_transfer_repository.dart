import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/wallet_transfer/domain/repositories/wallet_transfer_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Repository implementation for wallet transfer operations
/// Handles all API calls related to peer-to-peer transfers
class WalletTransferRepository implements WalletTransferRepositoryInterface {
  final ApiClient apiClient;

  WalletTransferRepository({required this.apiClient});

  @override
  Future<Response> validateRecipient(String phone) async {
    return await apiClient.postData(
      AppConstants.validateRecipientUri,
      {'phone': phone},
    );
  }

  @override
  Future<Response> executeTransfer(Map<String, dynamic> transferData) async {
    return await apiClient.postData(
      AppConstants.walletTransferUri,
      transferData,
    );
  }

  @override
  Future<Response> getSavedRecipients() async {
    return await apiClient.getData(AppConstants.savedRecipientsUri);
  }

  @override
  Future<Response> addSavedRecipient(String phone, String? nickname) async {
    final Map<String, dynamic> data = {'recipient_phone': phone};
    if (nickname != null && nickname.isNotEmpty) {
      data['recipient_name'] = nickname;
    }
    return await apiClient.postData(AppConstants.addRecipientUri, data);
  }

  @override
  Future<Response> deleteSavedRecipient(int recipientId) async {
    return await apiClient.deleteData(
      '${AppConstants.savedRecipientsUri}/$recipientId',
    );
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}






