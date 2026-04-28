class CartOperationException implements Exception {
  final int? statusCode;
  final String? errorCode;
  final String? message;

  const CartOperationException({
    this.statusCode,
    this.errorCode,
    this.message,
  });

  @override
  String toString() {
    return 'CartOperationException(statusCode: $statusCode, errorCode: $errorCode, message: $message)';
  }
}
