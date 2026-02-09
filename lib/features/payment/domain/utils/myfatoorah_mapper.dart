import 'package:myfatoorah_flutter/MFModels.dart';

/// Maps backend payment methods response to MFPaymentMethod objects
/// This allows us to use backend endpoint instead of direct SDK calls
class MyFatoorahMapper {
  /// Convert backend response data to List<MFPaymentMethod>
  /// 
  /// Backend response format:
  /// {
  ///   "success": true,
  ///   "data": [
  ///     {
  ///       "PaymentMethodId": 1,
  ///       "PaymentMethodEn": "VISA/MASTER",
  ///       "PaymentMethodAr": "فيزا/ماستر",
  ///       "ImageUrl": "https://sa.myfatoorah.com/imgs/payment-methods/vm.png",
  ///       "PaymentMethodCode": "vm",
  ///       "IsDirectPayment": true,
  ///       "ServiceCharge": 0.0,
  ///       "TotalAmount": 4724.88
  ///     }
  ///   ]
  /// }
  static List<MFPaymentMethod> mapBackendResponseToPaymentMethods(
    List<dynamic> backendData,
  ) {
    return backendData.map((item) {
      return _mapSinglePaymentMethod(item as Map<String, dynamic>);
    }).toList();
  }

  /// Map a single payment method from backend format to MFPaymentMethod
  static MFPaymentMethod _mapSinglePaymentMethod(Map<String, dynamic> data) {
    // Create MFPaymentMethod using the SDK's structure
    // Backend response uses PascalCase, SDK uses camelCase properties
    // ✅ FIX: Backend sends 'ImageUrl' (not 'PaymentMethodLogoUrl')
    return MFPaymentMethod(
      paymentMethodId: data['PaymentMethodId'] as int?,
      paymentMethodEn: data['PaymentMethodEn'] as String?,
      paymentMethodAr: data['PaymentMethodAr'] as String?,
      imageUrl: data['ImageUrl'] as String?, // ✅ FIX: Backend field is 'ImageUrl'
      isDirectPayment: data['IsDirectPayment'] as bool?,
      serviceCharge: data['ServiceCharge'] as num?,
      totalAmount: data['TotalAmount'] as num?,
      // Map payment method code - prefer backend field, fallback to extraction
      paymentMethodCode: data['PaymentMethodCode'] as String? ?? 
        _extractPaymentMethodCode(
          data['PaymentMethodEn'] as String?,
          data['PaymentMethodAr'] as String?,
        ),
    );
  }

  /// Extract payment method code from name for filtering purposes
  /// This helps identify Apple Pay, Google Pay, etc.
  static String? _extractPaymentMethodCode(
    String? methodEn,
    String? methodAr,
  ) {
    if (methodEn == null && methodAr == null) return null;

    final String combined = '${methodEn ?? ''} ${methodAr ?? ''}'.toLowerCase();

    // Common payment method codes
    if (combined.contains('apple') || combined.contains('أبل')) {
      return 'AP';
    }
    if (combined.contains('google') || combined.contains('جوجل')) {
      return 'GP';
    }
    if (combined.contains('visa') || combined.contains('فيزا')) {
      return 'VISA';
    }
    if (combined.contains('master') || combined.contains('ماستر')) {
      return 'MASTER';
    }
    if (combined.contains('mada') || combined.contains('مدى')) {
      return 'MADA';
    }
    if (combined.contains('stc') || combined.contains('stc pay')) {
      return 'STC';
    }

    return null;
  }
}
