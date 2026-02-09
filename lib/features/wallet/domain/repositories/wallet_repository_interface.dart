import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class WalletRepositoryInterface extends RepositoryInterface{
  Future<dynamic> addFundToWallet(double amount, String paymentMethod);
  Future<void> setWalletAccessToken(String token);
  String getWalletAccessToken();
  Future<Response> requestExchange(String number);
  Future<Response> exchangeWallet(String number,String otp,String userOtp,String money);

  @override
  Future getList({int? offset, String? sortingType, bool isBonusList = false});
}