import 'dart:convert';

import 'package:get/get_connect/connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/features/payment/domain/repositories/payment_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class PaymentRepository implements PaymentRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  PaymentRepository({required this.apiClient, required this.sharedPreferences});

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
  Future<List<OfflineMethodModel>?> getList({int? offset}) async {
    return await _getOfflineMethodList();
  }

  Future<List<OfflineMethodModel>?> _getOfflineMethodList() async {
    List<OfflineMethodModel>? offlineMethodList;
    final Response response = await apiClient.getData(AppConstants.offlineMethodListUri);
    if (response.statusCode == 200) {
      offlineMethodList = [];
      for (var method in (response.body as List)) {
        offlineMethodList.add(OfflineMethodModel.fromJson(method as Map<String, dynamic>));
      }
    }
    return offlineMethodList;
  }

  @override
  Future<bool> saveOfflineInfo(String data) async {
    final Response response = await apiClient.postData(AppConstants.offlinePaymentSaveInfoUri, jsonDecode(data));
    return (response.statusCode == 200);
  }

  @override
  Future<bool> updateOfflineInfo(String data) async {
    final Response response = await apiClient.postData(AppConstants.offlinePaymentUpdateInfoUri, jsonDecode(data));
    return (response.statusCode == 200);
  }


  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}