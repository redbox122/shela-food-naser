// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/contract_pdf_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/kaidhaSub_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/nafath_checkStatus_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/nafath_random_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/wallet_kaidha_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository_interface.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/services/kaidhaSub_service_interface.dart';

class KaidhaSubService implements kaidhaSub_ServiceInterface {
  final KaidhaSubRepositoryInterface kaidhaSubRepositoryinterface;
  KaidhaSubService({required this.kaidhaSubRepositoryinterface});

  @override
  Future<bool> Stor_info(context, KaidhaSubModel kaidhaSub, List<NamedFile> list_img) async {
    return await kaidhaSubRepositoryinterface.Stor_info(context, kaidhaSub, list_img);
  }

  @override
  Future<WalletKaidhaModel?> getWalletKaidh({bool forceRefresh = false}) async {
    return await kaidhaSubRepositoryinterface.getWalletKaidh(forceRefresh: forceRefresh);
  }

  @override
  Future<ContractPdfModel> get_Pdf() async {
    return await kaidhaSubRepositoryinterface.get_Pdf();
  }

  @override
  Future<Response> send_Pay_credit(context, double total) async {
    return await kaidhaSubRepositoryinterface.send_Pay_credit(context, total);
  }

  @override
  Future<bool> send_Pay_debit(context, double total, {String? orderId}) async {
    return await kaidhaSubRepositoryinterface.send_Pay_debit(context, total, orderId: orderId);
  }

  @override
  Future<NafathRandomModel?> Nafath_send_National_Id(BuildContext context, String nationalId) async {
    return await kaidhaSubRepositoryinterface.Nafath_send_National_Id(context, nationalId);
  }

  @override
  Future<NafathCheckStatusModel?> Nafath_send_checkStatus(BuildContext context, String nationalId) async {
    return await kaidhaSubRepositoryinterface.Nafath_send_checkStatus(context, nationalId);
  }

  @override
  Future<Response> Nafath_send_cancel(BuildContext context, String nationalId) async {
    return await kaidhaSubRepositoryinterface.Nafath_send_cancel(context, nationalId);
  }

  @override
  Future<NafathRandomModel?> Nafath_send_retry(
      BuildContext context, String nationalId) async {
    return await kaidhaSubRepositoryinterface.Nafath_send_retry(
      context,
      nationalId,
    );
  }

  @override
  Future<Response> Nafath_send_All_Data(BuildContext context, String national_id, String city, String neighborhood, String house_type, KaidhaSubModel kaidhaSub, List<NamedFile> list_img) async {
    return await kaidhaSubRepositoryinterface.Nafath_send_All_Data(context, national_id, city, neighborhood, house_type, kaidhaSub, list_img);
  }

  @override
  Future<Response> SendState_kaidha(int user_id, String status, Map<String, dynamic> data) async {
    return await kaidhaSubRepositoryinterface.SendState_kaidha(user_id, status, data);
  }

  @override
  void clearWalletCache() {
    kaidhaSubRepositoryinterface.clearWalletCache();
  }
}
