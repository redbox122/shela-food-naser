/// Client-side validation helpers for the Qidha wallet registration flow.
class QidhaValidation {
  QidhaValidation._();

  static final RegExp tenDigitNumeric = RegExp(r'^\d{10}$');

  static bool isTenDigitNumericString(String value) {
    return tenDigitNumeric.hasMatch(value.trim());
  }

  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}
