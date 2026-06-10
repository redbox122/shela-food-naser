import 'package:sixam_mart/common/utils/json_parser.dart';

class OtpSendResult {
  final bool success;
  final bool otpSent;
  final int cooldownSeconds;
  final int expiresInSeconds;
  final int? retryAfterSeconds;
  final String? phone;
  final String? message;
  final String? errorCode;

  OtpSendResult({
    required this.success,
    required this.otpSent,
    this.cooldownSeconds = 120,
    this.expiresInSeconds = 600,
    this.retryAfterSeconds,
    this.phone,
    this.message,
    this.errorCode,
  });

  factory OtpSendResult.fromJson(Map<String, dynamic> json) {
    return OtpSendResult(
      success: json['success'] == true,
      otpSent: json['otp_sent'] == true,
      cooldownSeconds: json.parseInt('cooldown_seconds') ?? 120,
      expiresInSeconds: json.parseInt('expires_in_seconds') ?? 600,
      retryAfterSeconds: json.containsKey('retry_after_seconds')
          ? json.parseInt('retry_after_seconds')
          : null,
      phone: json.parseString('phone'),
      message: json.parseString('message'),
      errorCode: json.parseString('code'),
    );
  }

  factory OtpSendResult.failure(String? message, {String? errorCode}) =>
      OtpSendResult(
          success: false,
          otpSent: false,
          message: message,
          errorCode: errorCode);
}

class OtpVerifyResult {
  final bool success;
  final bool isExisted;
  final String? token;
  final String? registrationToken;
  final int? expiresInSeconds;
  final String? phone;
  final String? message;
  final String? errorCode;

  OtpVerifyResult({
    required this.success,
    required this.isExisted,
    this.token,
    this.registrationToken,
    this.expiresInSeconds,
    this.phone,
    this.message,
    this.errorCode,
  });

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResult(
      success: json['success'] == true,
      isExisted: json['is_existed'] == true,
      token: json.parseString('token'),
      registrationToken: json.parseString('registration_token'),
      expiresInSeconds: json.containsKey('expires_in_seconds')
          ? json.parseInt('expires_in_seconds')
          : null,
      phone: json.parseString('phone'),
      message: json.parseString('message'),
      errorCode: json.parseString('code'),
    );
  }

  factory OtpVerifyResult.failure(String? message, {String? errorCode}) =>
      OtpVerifyResult(
          success: false,
          isExisted: false,
          message: message,
          errorCode: errorCode);
}
