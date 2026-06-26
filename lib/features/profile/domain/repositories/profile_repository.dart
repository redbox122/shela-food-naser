import 'dart:convert';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/profile/domain/models/update_profile_response_model.dart';
import 'package:sixam_mart/features/profile/domain/models/update_user_model.dart';
import 'package:sixam_mart/features/profile/domain/models/userinfo_model.dart';
import 'package:sixam_mart/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:flutter/foundation.dart';

class ProfileRepository implements ProfileRepositoryInterface {
  final ApiClient apiClient;
  ProfileRepository({required this.apiClient});

  @override
  Future<UserInfoModel?> get(String? id) async {
    UserInfoModel? userInfoModel;

    final Response response = await apiClient.getData(AppConstants.customerInfoUri);
    
    // ⚡ FIX: Handle 304 Not Modified - return existing userInfoModel from ProfileController
    if (response.statusCode == 304) {
      if (kDebugMode) {
        debugPrint('✅ Profile Repository: 304 Not Modified - checking existing userInfoModel from controller');
      }
      // Return existing userInfoModel from ProfileController if available (304 means data hasn't changed)
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        final existingUserInfo = profileController.userInfoModel;
        if (existingUserInfo != null) {
          if (kDebugMode) {
            debugPrint('   - Existing userInfoModel: EXISTS (${existingUserInfo.fName} ${existingUserInfo.lName}) - returning cached data');
          }
          return existingUserInfo;
        } else {
          // ⚠️ 304 received but userInfoModel is NULL - force refresh without ETag
          if (kDebugMode) {
            debugPrint('   - Existing userInfoModel: NULL - 304 received with no cache');
            debugPrint('   - 🔄 Forcing refresh (no ETag)...');
          }
          return await _forceRefreshUserInfo();
        }
      }
      if (kDebugMode) {
        debugPrint('   - ProfileController not registered, returning null');
      }
      return null;
    }
    
    if (response.statusCode == 200) {
      userInfoModel = UserInfoModel.fromJson(response.body as Map<String, dynamic>);
    }
    return userInfoModel;
  }

  @override
  Future<UserInfoModel?> getUserInfoForceRefresh() => _forceRefreshUserInfo();

  Future<UserInfoModel?> _forceRefreshUserInfo() async {
    final freshResponse = await apiClient.getData(
      AppConstants.customerInfoUri,
      useEtag: false,
    );
    if (freshResponse.statusCode == 200) {
      final model = UserInfoModel.fromJson(
          freshResponse.body as Map<String, dynamic>);
      if (kDebugMode) {
        debugPrint('✅ Profile Repository: Forced refresh succeeded (200)');
      }
      return model;
    }
    if (kDebugMode) {
      debugPrint(
          '❌ Profile Repository: Forced refresh failed - status: ${freshResponse.statusCode}');
    }
    return null;
  }

/*  @override
  Future<ResponseModel> updateProfile(UserInfoModel userInfoModel, XFile? data, String token) async {
    ResponseModel responseModel;
    Map<String, String> body = {
      'f_name': userInfoModel.fName!,
      'l_name': userInfoModel.lName!,
      'email': userInfoModel.email!,
    };

    Response response = await apiClient.postMultipartData(AppConstants.updateProfileUri, body, [MultipartBody('image', data)], handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.bodyString);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }*/

  @override
  Future<ResponseModel> updateProfile(UpdateUserModel userInfoModel, XFile? data, String token) async {
    ResponseModel responseModel;
    if (kDebugMode) {
      debugPrint('------- Update Profile Payload -------');
      debugPrint(jsonEncode(userInfoModel.toJson()));
      debugPrint('--------------------------------------');
    }
    final Response response = await apiClient
        .postMultipartData(AppConstants.updateProfileUri, userInfoModel.toJson(), [MultipartBody('image', data)], handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(
        true,
        (response.body as Map<String, dynamic>)['message'] as String?,
        updateProfileResponseModel:
            response.body['verification_on'] != null ? UpdateProfileResponseModel.fromJson(response.body as Map<String, dynamic>) : null,
      );
    } else {
      responseModel = ResponseModel(
        false,
        response.statusText,
        updateProfileResponseModel:
            response.body['verification_on'] != null ? UpdateProfileResponseModel.fromJson(response.body as Map<String, dynamic>) : null,
      );
    }
    return responseModel;
  }

/*  @override
  Future<ResponseModel> changePassword(UserInfoModel userInfoModel) async {
    ResponseModel responseModel;
    Map<String, dynamic> body = {
      'f_name': userInfoModel.fName,
      'l_name': userInfoModel.lName,
      'email': userInfoModel.email,
      'password': userInfoModel.password,
    };
    Response response = await apiClient.postData(AppConstants.updateProfileUri, body, handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }*/

  @override
  Future<ResponseModel> changePassword(UserInfoModel userInfoModel) async {
    ResponseModel responseModel;
    final Map<String, dynamic> data = {
      'name': '${userInfoModel.fName} ${userInfoModel.lName}',
      'email': userInfoModel.email,
      'password': userInfoModel.password,
      'phone': userInfoModel.phone,
      'button_type': 'change_password'
    };
    final Response response = await apiClient.postData(AppConstants.updateProfileUri, data, handleError: false);
    if (response.statusCode == 200) {
      final String? message = (response.body as Map<String, dynamic>)['message'] as String?;
      responseModel = ResponseModel(true, message);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

/*  @override
  Future<ResponseModel> delete(int? id) async {
    ResponseModel responseModel;
    Response response = await apiClient.deleteData(AppConstants.customerRemoveUri, handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, 'your_account_remove_successfully'.tr);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }*/

  @override
  Future<Response> delete(int? id) async {
    return await apiClient.postData(AppConstants.customerRemoveUri, {'_method': 'delete'});
  }

  @override
  Future add(value) {
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
