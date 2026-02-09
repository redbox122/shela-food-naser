import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/domain/models/store_body_model.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/store_registration_repository_interface.dart';
import 'package:sixam_mart/features/business/domain/models/package_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:http/http.dart' as http;

class StoreRegistrationRepository
    implements StoreRegistrationRepositoryInterface {
  final ApiClient apiClient;
  StoreRegistrationRepository({required this.apiClient});

  @override
  Future<Response> registerStore(
      StoreBodyModel store, XFile? logo, XFile? cover) async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      print('⚠️ لا يوجد توكن.');
      showCustomSnackBar('الرجاء تسجيل الدخول أولاً');
      return const Response(
          statusCode: 401, statusText: 'Unauthorized: Missing token');
    }

    final uri = Uri.parse(AppConstants.baseUrl + AppConstants.storeRegisterUri);
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      'X-localization': 'en',
      'Authorization': 'Bearer ${apiClient.token}',
    });

    request.fields.addAll({
      'f_name': store.fName!,
      'l_name': store.lName!,
      'latitude': store.lat!,
      'longitude': store.lng!,
      'email': store.email!,
      'phone': store.phone!,
      'minimum_delivery_time': store.minDeliveryTime!,
      'maximum_delivery_time': store.maxDeliveryTime!,
      'delivery_time_type': store.deliveryTimeType!,
      'password': store.password!,
      'zone_id': store.zoneId!,
      'module_id': store.moduleId!,
      'tax': store.tax!,
      'tax_cal': 'percent', // لا تتركه فارغ
      'translations': store.translation!,
    });

    if (logo != null) {
      request.files.add(await http.MultipartFile.fromPath('logo', logo.path));
    }
    if (cover != null) {
      request.files
          .add(await http.MultipartFile.fromPath('cover_photo', cover.path));
    }

    try {
      final http.StreamedResponse response = await request.send();
      final body = await response.stream.bytesToString();
      // ignore: avoid_print
      print('📩 Response: $body');

      final Map<String, dynamic> jsonResponse =
          jsonDecode(body) as Map<String, dynamic>;
      final bool hasErrors = jsonResponse['errors'] is List &&
          (jsonResponse['errors'] as List).isNotEmpty;

      debugPrint('\x1B[32m  /${response.statusCode}   \x1B[0m');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          !hasErrors) {
        Get.back();
        showCustomSnackBar('✅ تم إرسال الطلب بنجاح', isError: false);
      } else if (response.statusCode == 500) {
        showCustomSnackBar('قم بمراجعه البيانات ');
      } else if (jsonResponse.containsKey('message') &&
          jsonResponse['message'].toString().contains('Duplicate entry')) {
        showCustomSnackBar('  رقم الهاتف او البريد الاكتروني تم الحفظ مسبقا ');
      } else if (jsonResponse.containsKey('errors')) {
        // عرض كل الأخطاء بالعربية
        String errorMessages = '';
        for (var error in (jsonResponse['errors'] as List)) {
          switch (error['code']) {
            case 'phone':
              errorMessages += '📞 رقم الجوال مستخدم مسبقاً.\n';
              break;
            case 'password':
              errorMessages +=
                  '🔐 كلمة المرور ضعيفة أو مخترقة. الرجاء استخدام كلمة أقوى.\n';
              break;
            case 'tax_cal':
              errorMessages +=
                  '💰 يرجى تحديد نوع الضريبة (نسبة أو قيمة ثابتة).\n';
              break;
            case 'latitude':
              errorMessages += '📍 الموقع خارج النطاق المسموح به.\n';
              break;
            default:
              errorMessages += '⚠️ ${error['message']}\n';
          }
        }
        // showCustomSnackBar(errorMessages.trim());

        debugPrint(
            '\x1B[32m  / ${response.statusCode}    ${errorMessages.trim()}  \x1B[0m');
      } else if (jsonResponse.containsKey('message')) {
        // في حال كان الرد يحتوي فقط على رسالة عامة
        // showCustomSnackBar("⚠️ ${jsonResponse['message']}");
        debugPrint('\x1B[32m  ////////////  \x1B[0m');
      }

      return Response(
        body: jsonResponse,
        statusCode: response.statusCode,
        statusText: response.reasonPhrase,
      );
    } catch (e) {
      showCustomSnackBar('❌ حدث خطأ أثناء الاتصال بالخادم');
      print('❌ Exception occurred: $e');
      return const Response(statusCode: 500, statusText: 'Server Error');
    }
  }

  @override
  Future<bool> checkInZone(String? lat, String? lng, int zoneId) async {
    final Response response = await apiClient.getData(
        '${AppConstants.checkZoneUri}?lat=$lat&lng=$lng&zone_id=$zoneId');

    if (response.statusCode == 200) {
      try {
        final data = response.body;
        // The API returns a boolean directly, not a JSON object
        if (data is bool) {
          return data;
        }
        // Fallback for JSON object format
        if (data is Map<String, dynamic>) {
          return data['in_zone'] as bool? ?? false;
        }
        return false;
      } catch (e) {
        debugPrint('❌ checkInZone error: $e');
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  Future<PackageModel?> getPackageList({int? moduleId}) async {
    PackageModel? packageModel;
    final Response response = await apiClient
        .getData('${AppConstants.storePackagesUri}?module_id=$moduleId');
    if (response.statusCode == 200) {
      packageModel = PackageModel.fromJson(response.body as Map<String, dynamic>);
    }
    return packageModel;
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
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }
}
