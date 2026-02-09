// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/contract_pdf_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/kaidhaSub_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/nafath_checkStatus_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/nafath_random_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/wallet_kaidha_model.dart';

abstract class kaidhaSub_ServiceInterface {
  Future<bool> Stor_info(
      context, KaidhaSubModel kaidhaSub, List<NamedFile> list_img);

  Future<WalletKaidhaModel?> getWalletKaidh({bool forceRefresh = false});

  Future<ContractPdfModel> get_Pdf();

  Future<Response> send_Pay_credit(context, double total);

  Future<bool> send_Pay_debit(context, double total, {String? orderId});

  Future<NafathCheckStatusModel?> Nafath_send_checkStatus(
      BuildContext context, String nationalId);
  Future<Response<dynamic>> Nafath_send_cancel(
      BuildContext context, String nationalId);
  Future<NafathRandomModel?> Nafath_send_retry(
      BuildContext context, String nationalId);

  Future<NafathRandomModel?> Nafath_send_National_Id(
      BuildContext context, String nationalId);

  Future<Response> Nafath_send_All_Data(
      BuildContext context,
      String national_id,
      String city,
      String neighborhood,
      String house_type,
      KaidhaSubModel kaidhaSub,
      List<NamedFile> list_img);

  Future<Response> SendState_kaidha(
      int user_id, String status, Map<String, dynamic> data);

  void clearWalletCache();
}
