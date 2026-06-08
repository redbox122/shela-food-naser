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

  /// Process payment via backend and return payment_url in response
  Future<Response> processPayment({
    required int orderId,
    required double amount,
    String currency = 'SAR',
    required int paymentMethodId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
  }) async {
    return await repository.processPayment(
      orderId: orderId,
      amount: amount,
      currency: currency,
      paymentMethodId: paymentMethodId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );
  }

  /// Verify a MyFatoorah payment status via the backend (single call, no polling)
  Future<Response> checkStatus({
    required String key,
    String keyType = 'InvoiceId',
  }) async {
    return await repository.checkStatus(key: key, keyType: keyType);
  }

  /// Process payment without order via backend and return payment_url in response
  Future<Response> processPaymentWithoutOrder({
    required double amount,
    String currency = 'SAR',
    int? paymentMethodId,
    String? paymentMethodCode,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    String? countryCode,
    String? callbackUrl,
    String? errorUrl,
  }) async {
    return await repository.processPaymentWithoutOrder(
      amount: amount,
      currency: currency,
      paymentMethodId: paymentMethodId,
      paymentMethodCode: paymentMethodCode,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      countryCode: countryCode,
      callbackUrl: callbackUrl,
      errorUrl: errorUrl,
    );
  }
}
