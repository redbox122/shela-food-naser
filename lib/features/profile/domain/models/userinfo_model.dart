import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class UserInfoModel {
  int? id;
  String? fName;
  String? lName;
  String? email;
  String? imageFullUrl;
  String? phone;
  String? createdAt;
  String? password;
  int? orderCount;
  int? memberSinceDays;
  double? walletBalance;
  int? loyaltyPoint;
  String? refCode;
  String? socialId;
  User? userInfo;
  bool? isValidForDiscount;
  double? discountAmount;
  String? discountAmountType;
  String? validity;
  List<int>? selectedModuleForInterest;
  bool? isPhoneVerified;
  bool? isEmailVerified;
  // Wallet flags (NEW - from /api/v1/customer/info)
  bool? hasQidhaWallet;
  bool? qidhaWalletSigned;
  bool? qidhaWalletActive;
  double? qidhaWalletBalance;

  UserInfoModel({
    this.id,
    this.fName,
    this.lName,
    this.email,
    this.imageFullUrl,
    this.phone,
    this.createdAt,
    this.password,
    this.orderCount,
    this.memberSinceDays,
    this.walletBalance,
    this.loyaltyPoint,
    this.refCode,
    this.socialId,
    this.userInfo,
    this.isValidForDiscount,
    this.discountAmount,
    this.discountAmountType,
    this.validity,
    this.selectedModuleForInterest,
    this.isPhoneVerified,
    this.isEmailVerified,
    this.hasQidhaWallet,
    this.qidhaWalletSigned,
    this.qidhaWalletActive,
    this.qidhaWalletBalance,
  });

  UserInfoModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? nestedUserMap =
        json['userinfo'] is Map<String, dynamic>
            ? json['userinfo'] as Map<String, dynamic>
            : (json['user_info'] is Map<String, dynamic>
                ? json['user_info'] as Map<String, dynamic>
                : (json['user'] is Map<String, dynamic>
                    ? json['user'] as Map<String, dynamic>
                    : null));

    id = json.parseInt('id');
    fName = json.parseString('f_name');
    lName = json.parseString('l_name');
    email = json.parseString('email');
    imageFullUrl = json.parseString('image'); // API returns "image" (not "image_full_url")
    final String? directPhone = _cleanString(
      json['phone'] ??
          json['mobile'] ??
          json['contact_number'] ??
          json['phone_number'] ??
          json['contact'],
    );
    final String? nestedPhone = nestedUserMap != null
        ? _cleanString(
            nestedUserMap['phone'] ??
                nestedUserMap['mobile'] ??
                nestedUserMap['contact_number'] ??
                nestedUserMap['phone_number'] ??
                nestedUserMap['contact'],
          )
        : null;
    phone = directPhone ?? nestedPhone;
    createdAt = json.parseString('created_at');
    password = json.parseString('password');
    orderCount = json.parseInt('order_count');
    memberSinceDays = json.parseInt('member_since_days');
    walletBalance = json.parseDouble('wallet_balance');
    loyaltyPoint = json.parseInt('loyalty_point');
    final String? directRefCode = _cleanString(
      json['ref_code'] ??
          json['refer_code'] ??
          json['referral_code'] ??
          json['referralCode'],
    );
    final String? nestedRefCode = nestedUserMap != null
        ? _cleanString(
            nestedUserMap['ref_code'] ??
                nestedUserMap['refer_code'] ??
                nestedUserMap['referral_code'] ??
                nestedUserMap['referralCode'],
          )
        : null;
    refCode = directRefCode ?? nestedRefCode;
    socialId = json['social_id']?.toString();
    userInfo =
        nestedUserMap != null ? User.fromJson(nestedUserMap) : null;
    isValidForDiscount = json.parseBool('is_valid_for_discount');
    discountAmount = json.parseDouble('discount_amount');
    discountAmountType = json.parseString('discount_amount_type');
    validity = json.parseString('validity');
    if(json['selected_modules_for_interest'] != null) {
      selectedModuleForInterest = [];
      for (var value in (json['selected_modules_for_interest'] as List)) {
        if(value != null && value != 'null') {
          selectedModuleForInterest!.add(int.parse(value.toString()));
        }
      }
    }
    isPhoneVerified = json.parseInt('is_phone_verified') == 1;
    isEmailVerified = json.parseInt('is_email_verified') == 1;
    // Wallet flags (NEW - from /api/v1/customer/info)
    hasQidhaWallet = json.parseBool('has_qidha_wallet');
    qidhaWalletSigned = json.parseBool('qidha_wallet_signed');
    qidhaWalletActive = json.parseBool('qidha_wallet_active');
    // ⚡ FIX: Safe parsing - handle both String and numeric values
    qidhaWalletBalance = json.parseDouble('qidha_wallet_balance');

    if (kDebugMode) {
      debugPrint(
          '[PROFILE][USER_INFO_RESPONSE] status=200 userId=$id hasQidha=$hasQidhaWallet walletBalancePresent=${walletBalance != null}');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['email'] = email;
    data['image_full_url'] = imageFullUrl;
    data['phone'] = phone;
    data['created_at'] = createdAt;
    data['password'] = password;
    data['order_count'] = orderCount;
    data['member_since_days'] = memberSinceDays;
    data['wallet_balance'] = walletBalance;
    data['loyalty_point'] = loyaltyPoint;
    data['ref_code'] = refCode;
    if (userInfo != null) {
      data.addAll(userInfo!.toJson());
    }
    data['is_valid_for_discount'] = isValidForDiscount;
    data['discount_amount'] = discountAmount;
    data['discount_amount_type'] = discountAmountType;
    data['validity'] = validity;
    data['selected_modules_for_interest'] = selectedModuleForInterest;
    data['is_phone_verified'] = isPhoneVerified;
    data['is_email_verified'] = isEmailVerified;
    // Wallet flags (NEW - from /api/v1/customer/info)
    data['has_qidha_wallet'] = hasQidhaWallet;
    data['qidha_wallet_signed'] = qidhaWalletSigned;
    data['qidha_wallet_active'] = qidhaWalletActive;
    data['qidha_wallet_balance'] = qidhaWalletBalance;
    return data;
  }
}

String? _cleanString(dynamic value) {
  if (value == null) return null;
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}
