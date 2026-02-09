import 'package:get/get_connect/connect.dart';
import 'package:sixam_mart/features/payment/domain/repositories/myfatoorah_repository.dart';

class MyFatoorahService {
  final MyFatoorahRepository repository;

  MyFatoorahService({required this.repository});

  /// Get payment methods from backend
  /// Returns Response with payment methods data
  Future<Response> getPaymentMethods({
    required double amount,
    String currency = 'KWD',
  }) async {
    return await repository.getPaymentMethods(
      amount: amount,
      currency: currency,
    );
  }
}
