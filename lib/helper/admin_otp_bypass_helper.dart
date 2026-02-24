/// Helper that allows a fixed OTP code for designated admin / QA phone
/// numbers so testers can log in without receiving a real SMS.
///
/// ⚠️  Never expose real bypass numbers in production builds.
///     Keep this list empty or guard it with a compile-time flag.
class AdminOtpBypassHelper {
  AdminOtpBypassHelper._();

  /// The fixed OTP that bypass phones can use instead of the real code.
  static const String fixedOtp = '1234';

  /// Phone numbers that are allowed to use [fixedOtp].
  /// Add test numbers here during development; clear for production.
  static const List<String> _bypassPhones = [
    // e.g. '+8801700000000',
  ];

  /// Returns `true` when [phone] is in the bypass list.
  static bool isBypassPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    return _bypassPhones.contains(phone.trim());
  }
}
