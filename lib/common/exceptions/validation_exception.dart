class ValidationException implements Exception {
  final Map<String, String> errors;
  ValidationException(this.errors);

  @override
  String toString() => 'ValidationException(${errors.length} errors)';
}
