// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sixam_mart/features/add_delegate/domain/models/delegate_api_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';

abstract class Delegate_ServiceInterface {
  Future<DelegateModel?> getDelegate();

  Future<bool> send_Delegate(
    BuildContext context,
    int id,
    String f_name,
    String L_name,
    String mobile,
    List<NamedFile> list_img,
  );
}
