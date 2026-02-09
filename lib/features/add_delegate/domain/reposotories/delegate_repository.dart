// ignore_for_file: file_names, non_constant_identifier_names, avoid_print, use_build_context_synchronously, depend_on_referenced_packages, annotate_overrides, unused_local_variable, empty_catches

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/add_delegate/domain/models/delegate_api_model.dart';
import 'package:sixam_mart/features/add_delegate/domain/reposotories/delegate_repository_interface.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:sixam_mart/util/app_constants.dart';

class DelegateRepository implements DelegateRepositoryInterface {
  final ApiClient apiClient;

  DelegateRepository({required this.apiClient});

  @override
  Future<DelegateModel?> getDelegate() async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      print('⚠️ لا يوجد توكن. لن يتم تنفيذ طلب المندوب.');
      return null;
    }

    DelegateModel? delegateModel;

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${apiClient.token}',
    };

    final uri = Uri.parse(AppConstants.baseUrl + AppConstants.get_delegateUri);
    final request = http.Request('GET', uri);
    request.headers.addAll(headers);

    try {
      final http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> decoded = json.decode(responseBody) as Map<String, dynamic>;

        delegateModel = DelegateModel.fromJson(decoded);
        print('✅ مندوب: $responseBody');

        return delegateModel;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        print('❌ فشل في استرجاع بيانات المندوب. كود: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ أثناء استرجاع بيانات المندوب: $e');
    }

    return delegateModel;
  }

  @override
  Future<bool> send_Delegate(
    BuildContext context,
    int id,
    String f_name,
    String L_name,
    String mobile,
    List<NamedFile> list_img,
  ) async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      print('⚠️ لا يوجد توكن.');
      return false;
    }

    final uri = Uri.parse(AppConstants.baseUrl + AppConstants.send_delegateUri);
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      'X-localization': 'ar',
      'Authorization': 'Bearer ${apiClient.token}',
    });

    request.fields.addAll({
      'user_id': id.toString(),
      'f_name': f_name,
      'l_name': L_name,
      'mobile': mobile,
    });

    if (list_img.isNotEmpty) {
      final file = list_img.first.file;
      final String? path = file.path;

      if (path != null && path.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('id_photo', path),
        );
      } else if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'id_photo',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else {
        showCustomSnackBar('تعذر قراءة الملف المرفق. اختر ملفًا آخر.');
        return false;
      }

      request.fields['id_photo_name'] = p.basename(file.name);
    } else {
      showCustomSnackBar('الرجاء إرفاق صورة الهوية');
      return false;
    }

    final http.StreamedResponse response = await request.send();
    final String responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ تم الإرسال بنجاح');
      showCustomSnackBar('تم الإرسال بنجاح', isError: false);
      return true;
    }

    print('❌ فشل في الإرسال: ${response.statusCode}');
    print(responseBody);

    if (response.statusCode == 404) {
      showCustomSnackBar('الخدمة غير متاحة حالياً: مسار إرسال المندوب غير موجود على الخادم (404).');
      return false;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map && decoded.containsKey('message')) {
        showCustomSnackBar(decoded['message'].toString());
      } else if (decoded is Map && decoded.containsKey('errors')) {
        showCustomSnackBar(decoded['errors'].toString());
      } else {
        showCustomSnackBar('فشل في الإرسال، حاول مرة أخرى في وقت لاحق');
      }
    } catch (e) {
      print('❌ خطأ في فك الرد: $e');
      showCustomSnackBar('فشل في الإرسال، حاول مرة أخرى في وقت لاحق');
    }

    return false;
  }
}
