import 'package:myfatoorah_flutter/MFModels.dart';

class MyFatoorahMapper {
  static List<MFPaymentMethod> mapBackendResponseToPaymentMethods(
    List<dynamic> backendData,
  ) {
    final List<MFPaymentMethod> mapped = backendData.map((item) {
      return _mapSinglePaymentMethod(item as Map<String, dynamic>);
    }).toList();

    return _normalizeAndDedupe(mapped);
  }

  static MFPaymentMethod _mapSinglePaymentMethod(Map<String, dynamic> data) {
    final int? paymentMethodId = (data['id'] ?? data['PaymentMethodId']) as int?;
    final String? paymentMethodEn =
        (data['name_en'] ?? data['PaymentMethodEn']) as String?;
    final String? paymentMethodAr =
        (data['name_ar'] ?? data['PaymentMethodAr']) as String?;
    final String? imageUrl = _extractImageUrl(data);
    final bool? isDirectPayment =
        (data['is_direct_payment'] ?? data['IsDirectPayment']) as bool?;
    final num? serviceCharge =
        (data['service_charge'] ?? data['ServiceCharge']) as num?;
    final num? totalAmount = (data['total_amount'] ?? data['TotalAmount']) as num?;
    final String? backendCode =
        (data['payment_method_code'] ?? data['PaymentMethodCode']) as String?;

    final String? normalizedCode = normalizeBackendPaymentMethodCode(
          backendCode,
          methodEn: paymentMethodEn,
          methodAr: paymentMethodAr,
        ) ??
        _extractFallbackPaymentMethodCode(paymentMethodEn, paymentMethodAr);

    return MFPaymentMethod(
      paymentMethodId: paymentMethodId,
      paymentMethodEn: paymentMethodEn,
      paymentMethodAr: paymentMethodAr,
      imageUrl: imageUrl ?? _defaultLogoForCode(normalizedCode),
      isDirectPayment: isDirectPayment,
      serviceCharge: serviceCharge,
      totalAmount: totalAmount,
      paymentMethodCode: normalizedCode,
    );
  }

  // Canonical backend values:
  // VISA_MASTER | MADA | STC_PAY | APPLE_PAY
  static String? normalizeBackendPaymentMethodCode(
    String? code, {
    String? methodEn,
    String? methodAr,
  }) {
    final String rawCode = (code ?? '').trim().toUpperCase();
    final String en = (methodEn ?? '').toUpperCase();
    final String ar = (methodAr ?? '').toUpperCase();
    final String all = '$rawCode $en $ar';

    if (all.contains('APPLE_PAY') || all.contains('APPLE') || rawCode == 'AP') {
      return 'APPLE_PAY';
    }
    if (all.contains('MADA') || rawCode == 'MD') {
      return 'MADA';
    }
    if (all.contains('STC_PAY') || all.contains('STC')) {
      return 'STC_PAY';
    }
    if (all.contains('VISA_MASTER') ||
        all.contains('VISA') ||
        all.contains('MASTER') ||
        rawCode == 'VM') {
      return 'VISA_MASTER';
    }

    return null;
  }

  static String? _extractFallbackPaymentMethodCode(
    String? methodEn,
    String? methodAr,
  ) {
    final String all = '${methodEn ?? ''} ${methodAr ?? ''}'.toUpperCase();
    if (all.contains('APPLE')) return 'APPLE_PAY';
    if (all.contains('MADA')) return 'MADA';
    if (all.contains('STC')) return 'STC_PAY';
    if (all.contains('VISA') || all.contains('MASTER')) return 'VISA_MASTER';
    return null;
  }

  static String? _extractImageUrl(Map<String, dynamic> data) {
    final List<String> possibleKeys = <String>[
      'logo_url',
      'image_url',
      'image',
      'ImageUrl',
      'PaymentMethodLogoUrl',
      'payment_method_logo_url',
    ];

    for (final key in possibleKeys) {
      final dynamic value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final dynamic logo = data['logo'];
    if (logo is Map<String, dynamic>) {
      final dynamic nestedUrl = logo['url'] ?? logo['image_url'] ?? logo['image'];
      if (nestedUrl is String && nestedUrl.trim().isNotEmpty) {
        return nestedUrl.trim();
      }
    }

    return null;
  }

  static String? _defaultLogoForCode(String? normalizedCode) {
    switch ((normalizedCode ?? '').toUpperCase()) {
      case 'VISA_MASTER':
        return 'https://sa.myfatoorah.com/imgs/payment-methods/vm.png';
      case 'MADA':
        return 'https://sa.myfatoorah.com/imgs/payment-methods/md.png';
      case 'STC_PAY':
        // STC icon on MyFatoorah is usually `stc.png` (not `stcpay.png`).
        return 'https://sa.myfatoorah.com/imgs/payment-methods/stc.png';
      case 'APPLE_PAY':
        return 'https://sa.myfatoorah.com/imgs/payment-methods/ap.png';
      default:
        return null;
    }
  }

  static List<MFPaymentMethod> _normalizeAndDedupe(
    List<MFPaymentMethod> methods,
  ) {
    final bool hasRegularMada = methods.any(
      (method) => !_isAppleMethod(method) && _isMadaMethod(method),
    );

    final List<MFPaymentMethod> filtered = <MFPaymentMethod>[];
    bool applePayAdded = false;

    for (final method in methods) {
      if (_isAppleMethod(method)) {
        // Keep one Apple Pay only. If "Apple Pay (MADA)" exists with regular MADA,
        // regular MADA remains and duplicate Apple entries are removed.
        if (hasRegularMada && _isMadaMethod(method)) {
          continue;
        }
        if (applePayAdded) {
          continue;
        }
        applePayAdded = true;
      }
      filtered.add(method);
    }

    return filtered;
  }

  static bool _isAppleMethod(MFPaymentMethod method) {
    final String code = (method.paymentMethodCode ?? '').toUpperCase();
    final String en = (method.paymentMethodEn ?? '').toUpperCase();
    final String ar = (method.paymentMethodAr ?? '').toUpperCase();
    return code == 'APPLE_PAY' || code == 'AP' || en.contains('APPLE') || ar.contains('APPLE');
  }

  static bool _isMadaMethod(MFPaymentMethod method) {
    final String code = (method.paymentMethodCode ?? '').toUpperCase();
    final String en = (method.paymentMethodEn ?? '').toUpperCase();
    final String ar = (method.paymentMethodAr ?? '').toUpperCase();
    return code == 'MADA' || code == 'MD' || en.contains('MADA') || ar.contains('MADA');
  }
}
