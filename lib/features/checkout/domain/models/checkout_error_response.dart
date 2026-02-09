/// 🥇 Checkout Error Response Model
/// 
/// Response واضح (UX + Debug)
/// بدل: "حقل الاسم مطلوب"
/// اعمل: { "code": "CONTACT_NAME_REQUIRED", "message": "..." }
/// 
/// هذا يسمح للـ Flutter:
/// - يوقف الفلو
/// - يعرض رسالة مفهومة
/// - بدون أي تنقل
library;

class CheckoutErrorResponse {
  final bool success;
  final String? code;
  final String message;
  final Map<String, dynamic>? data;
  final List<String>? errors;

  CheckoutErrorResponse({
    required this.success,
    this.code,
    required this.message,
    this.data,
    this.errors,
  });

  factory CheckoutErrorResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutErrorResponse(
      success: json['success'] as bool? ?? false,
      code: json['code']?.toString(),
      message: json['message']?.toString() ?? 'حدث خطأ غير متوقع',
      data: json['data'] as Map<String, dynamic>?,
      errors: json['errors'] != null
          ? (json['errors'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (code != null) 'code': code,
      'message': message,
      if (data != null) 'data': data,
      if (errors != null) 'errors': errors,
    };
  }

  /// هل الخطأ متعلق بالاسم؟
  bool get isContactNameError {
    return code == 'CONTACT_NAME_REQUIRED' ||
           code == 'CONTACT_NAME_INVALID' ||
           message.contains('اسم') ||
           message.contains('contact_person_name');
  }

  /// هل الخطأ متعلق برقم الهاتف؟
  bool get isContactNumberError {
    return code == 'CONTACT_NUMBER_REQUIRED' ||
           code == 'CONTACT_NUMBER_INVALID' ||
           message.contains('هاتف') ||
           message.contains('contact_person_number');
  }

  /// هل الخطأ متعلق بالدفع؟
  bool get isPaymentError {
    return code == 'PAYMENT_FAILED' ||
           code == 'PAYMENT_METHOD_REQUIRED' ||
           code == 'INSUFFICIENT_BALANCE' ||
           message.contains('دفع') ||
           message.contains('payment');
  }

  /// هل الخطأ متعلق بالطلب؟
  bool get isOrderError {
    return code == 'ORDER_CREATION_FAILED' ||
           code == 'ORDER_VALIDATION_FAILED' ||
           message.contains('طلب') ||
           message.contains('order');
  }

  /// هل يمكن إعادة المحاولة؟
  bool get canRetry {
    // بعض الأخطاء لا يمكن إعادة المحاولة فيها
    return code != 'INSUFFICIENT_BALANCE' &&
           code != 'PAYMENT_METHOD_REQUIRED' &&
           code != 'CONTACT_NAME_REQUIRED';
  }

  /// رسالة خطأ صديقة للمستخدم
  String get userFriendlyMessage {
    // إذا كان هناك code محدد، استخدم رسالة مخصصة
    switch (code) {
      case 'CONTACT_NAME_REQUIRED':
        return 'يرجى إدخال اسم المستلم لإكمال الطلب';
      case 'CONTACT_NUMBER_REQUIRED':
        return 'يرجى إدخال رقم الهاتف لإكمال الطلب';
      case 'PAYMENT_METHOD_REQUIRED':
        return 'يرجى اختيار طريقة الدفع';
      case 'INSUFFICIENT_BALANCE':
        return 'الرصيد غير كافي لإكمال عملية الدفع';
      case 'ORDER_CREATION_FAILED':
        return 'فشل في إنشاء الطلب. يرجى المحاولة مرة أخرى';
      case 'PAYMENT_FAILED':
        return 'فشلت عملية الدفع. يرجى التحقق من طريقة الدفع والمحاولة مرة أخرى';
      default:
        return message;
    }
  }
}

/// Helper function لاستخراج CheckoutErrorResponse من API Response
CheckoutErrorResponse? extractCheckoutError(dynamic responseBody) {
  if (responseBody == null) {
    return null;
  }

  if (responseBody is Map<String, dynamic>) {
    try {
      return CheckoutErrorResponse.fromJson(responseBody);
    } catch (e) {
      // إذا فشل parsing، أنشئ response بسيط
      return CheckoutErrorResponse(
        success: false,
        message: responseBody['message']?.toString() ?? 
                 responseBody['error']?.toString() ?? 
                 'حدث خطأ غير متوقع',
        code: responseBody['code']?.toString(),
      );
    }
  }

  if (responseBody is String) {
    return CheckoutErrorResponse(
      success: false,
      message: responseBody,
    );
  }

  return null;
}

