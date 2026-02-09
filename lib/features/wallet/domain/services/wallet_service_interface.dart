import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/features/wallet/domain/models/fund_bonus_model.dart';

abstract class WalletServiceInterface {
  Future<TransactionModel?> getWalletTransactionList(String offset, String sortingType);
  Future<dynamic> addFundToWallet(double amount, String paymentMethod);
  Future<List<FundBonusModel>?> getWalletBonusList();
  Future<void> setWalletAccessToken(String token);
  String getWalletAccessToken();
  Future<Response> requestExchange(String number);
  Future<Response> exchangeWallet(String number, String otp, String userOtp, String money);
}
