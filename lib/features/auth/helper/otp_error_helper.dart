import 'package:get/get.dart';

String mapOtpAuthError(String? code, String? fallbackMessage) {
  switch (code) {
    case 'invalid_otp':
      return 'invalid_otp_code'.tr;
    case 'otp_expired':
    case 'otp_not_found':
      return 'otp_expired_code'.tr;
    case 'otp_temp_blocked':
      return 'otp_temp_blocked_code'.tr;
    case 'invalid_registration_token':
      return 'invalid_registration_token_code'.tr;
    case 'invalid_referral_token':
      return 'invalid_referral_token'.tr;
    default:
      // Always show a localized (Arabic) message — never the raw English
      // message returned by the backend.
      return 'something_went_wrong'.tr;
  }
}
