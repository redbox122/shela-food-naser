import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

/// Interface for wallet transfer repository
/// Defines contract for peer-to-peer wallet transfer operations
abstract class WalletTransferRepositoryInterface implements RepositoryInterface {
  /// Validates if a phone number belongs to a registered user
  /// Returns user details if found
  Future<Response> validateRecipient(String phone);
  
  /// Executes a money transfer from sender to recipient
  /// Returns transaction details on success
  Future<Response> executeTransfer(Map<String, dynamic> transferData);
  
  /// Retrieves list of user's saved recipients
  /// Returns array of saved recipient objects
  Future<Response> getSavedRecipients();
  
  /// Adds a new recipient to saved contacts
  /// Returns the created recipient object
  Future<Response> addSavedRecipient(String phone, String? nickname);
  
  /// Deletes a saved recipient by ID
  /// Returns success status
  Future<Response> deleteSavedRecipient(int recipientId);
}






