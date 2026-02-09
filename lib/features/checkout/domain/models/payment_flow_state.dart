/// 🥇 Payment Flow State Management
/// 
/// Anti-loop Guard: يمنع أي navigation تلقائي عند الفشل
/// ويضمن أن المستخدم لا يُعاد قسرًا لصفحة الدفع
enum PaymentFlowState {
  /// الحالة الأولية - لم يبدأ شيء
  idle,
  
  /// جاري إنشاء الطلب (unpaid)
  creatingOrder,
  
  /// جاري تحضير عملية الدفع
  preparingPayment,
  
  /// جاري معالجة الدفع
  processingPayment,
  
  /// فشل العملية - لا navigation تلقائي
  failed,
  
  /// نجحت العملية
  success,
}

extension PaymentFlowStateExtension on PaymentFlowState {
  /// هل العملية قيد التنفيذ؟
  bool get isInProgress {
    return this == PaymentFlowState.creatingOrder ||
           this == PaymentFlowState.preparingPayment ||
           this == PaymentFlowState.processingPayment;
  }
  
  /// هل يمكن بدء عملية جديدة؟
  bool get canStartNewFlow {
    return this == PaymentFlowState.idle ||
           this == PaymentFlowState.failed ||
           this == PaymentFlowState.success ||
           this == PaymentFlowState.preparingPayment;
  }
  
  /// هل العملية فشلت؟
  bool get hasFailed {
    return this == PaymentFlowState.failed;
  }
  
  /// هل العملية نجحت؟
  bool get hasSucceeded {
    return this == PaymentFlowState.success;
  }
}

