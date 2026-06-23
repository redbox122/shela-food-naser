import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/models/auth_response_model.dart';
import 'package:sixam_mart/features/verification/domein/reposotories/verification_repository_interface.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class VerificationRepository implements VerificationRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  VerificationRepository(
      {required this.sharedPreferences, required this.apiClient});

  bool _shouldAttachGuestId(String guestId) {
    if (guestId.isEmpty) {
      return false;
    }
    final List<String>? cachedCart =
        sharedPreferences.getStringList(AppConstants.cartList);
    if (cachedCart == null || cachedCart.isEmpty) {
      return false;
    }
    for (final String item in cachedCart) {
      if (item.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<ResponseModel> forgetPassword(String? phone) async {
    final String? deviceToken = await Get.find<AuthController>().saveDeviceToken();
    final Response response = await apiClient.postData(AppConstants.forgetPasswordUri,
        {'phone': phone, 'cm_firebase_token': deviceToken!},
        handleError: false);
    if (response.statusCode == 200) {
      debugPrint('\x1B[32m -- /${response.body}  \x1B[0m');
      return ResponseModel(true, (response.body as Map<String, dynamic>)['message'] as String? ?? '');
    } else {
      debugPrint('\x1B[32m  /${response.body}  \x1B[0m');
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> resetPassword(String? resetToken, String number,
      String password, String confirmPassword) async {
    final Response response = await apiClient.postData(
      AppConstants.resetPasswordUri,
      {
        '_method': 'put',
        'reset_token': resetToken,
        'phone': number,
        'password': password,
        'confirm_password': confirmPassword
      },
      handleError: false,
    );
    if (response.statusCode == 200) {
      return ResponseModel(true, (response.body as Map<String, dynamic>)['message'] as String? ?? '');
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> verifyPhone(String? phone, String? otp) async {
    final Map<String, dynamic> data = {
      'phone': phone,
      'otp': otp,
    };

    final Response response =
        await apiClient.postData(AppConstants.verifyPhoneUri, data);

    debugPrint('\x1B[32m  /${response.statusCode}  \x1B[0m');

    if (response.statusCode == 200) {
      return ResponseModel(true, (response.body as Map<String, dynamic>)['message'] as String? ?? '');
    } else {
      return ResponseModel(false, (response.body as Map<String, dynamic>)['message'] as String? ?? '');
    }
  }

  // @override
  // Future<Response> verifyPhone(VerificationDataModel data) async {
  //   return await apiClient.postData(AppConstants.verifyPhoneUri, data.toJson(), handleError: false);
  // }

/*  @override
  Future<ResponseModel> verifyFirebaseOtp({required String phoneNumber, required String session, required String otp, required bool isSignUpPage}) async {
    Response response = await apiClient.postData(AppConstants.firebaseAuthVerify,
        {'sessionInfo' : session,
          'phoneNumber' : phoneNumber,
          'code' : otp,
          'is_reset_token' : isSignUpPage ? 0 : 1,
        },
    );
    if (response.statusCode == 200) {
      return ResponseModel(true, response.body["message"]);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }*/

  @override
  Future<ResponseModel> verifyFirebaseOtp(
      {required String phoneNumber,
      required String session,
      required String otp,
      required String loginType}) async {
    final String guestId = AuthHelper.getGuestId();
    final Map<String, dynamic> data = {
      'session_info': session,
      'phone': phoneNumber,
      'otp': otp,
      'login_type': loginType,
    };
    if (_shouldAttachGuestId(guestId)) {
      data.addAll({'guest_id': guestId});
    }
    final Response response =
        await apiClient.postData(AppConstants.firebaseAuthVerify, data);
    if (response.statusCode == 200) {
      final AuthResponseModel authResponse =
          AuthResponseModel.fromJson(response.body as Map<String, dynamic>);
      return ResponseModel(true, (response.body as Map<String, dynamic>)['message'] as String?,
          authResponseModel: authResponse);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> verifyForgetPassFirebaseOtp(
      {required String phoneNumber,
      required String session,
      required String otp}) async {
    final Response response = await apiClient.postData(
      AppConstants.firebaseResetPassword,
      {
        'sessionInfo': session,
        'phoneNumber': phoneNumber,
        'code': otp,
        'is_reset_token': 1,
        '_method': 'PUT'
      },
    );
    if (response.statusCode == 200) {
      return ResponseModel(true, (response.body as Map<String, dynamic>)['message'] as String? ?? '');
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future<ResponseModel> verifyToken(String? phone, String token) async {
    final Response response = await apiClient.postData(
        AppConstants.verifyTokenUri, {'phone': phone, 'reset_token': token});
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ResponseModel(true, (response.body as Map<String, dynamic>)['message'] as String? ?? '');
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
