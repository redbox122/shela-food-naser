import 'package:get/get.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/features/wallet/domain/models/fund_bonus_model.dart';
import 'package:sixam_mart/features/wallet/domain/repositories/wallet_repository_interface.dart';
import 'package:sixam_mart/features/wallet/domain/services/wallet_service_interface.dart';

class WalletService implements WalletServiceInterface {
  final WalletRepositoryInterface walletRepositoryInterface;
  WalletService({required this.walletRepositoryInterface});

  @override
  Future<TransactionModel?> getWalletTransactionList(String offset, String sortingType) async {
    final result = await walletRepositoryInterface.getList(offset: int.parse(offset), sortingType: sortingType);
    return result is TransactionModel? ? result : null;
  }

  @override
  Future<Response> addFundToWallet(double amount, String paymentMethod) async {
    final result = await walletRepositoryInterface.addFundToWallet(amount, paymentMethod);
    return result is Response ? result : const Response();
  }

  @override
  Future<List<FundBonusModel>?> getWalletBonusList() async {
    final result = await walletRepositoryInterface.getList(isBonusList: true);
    return result is List<FundBonusModel>? ? result : null;
  }

  @override
  Future<void> setWalletAccessToken(String token) {
    return walletRepositoryInterface.setWalletAccessToken(token);
  }

  @override
  String getWalletAccessToken() {
    return walletRepositoryInterface.getWalletAccessToken();
  }

  @override
  Future<Response> requestExchange(String number) {
    return walletRepositoryInterface.requestExchange(number);
  }

  @override
  Future<Response> exchangeWallet(String number, String otp, String userOtp, String money) {
    return walletRepositoryInterface.exchangeWallet(number, otp, userOtp, money);
  }
}
