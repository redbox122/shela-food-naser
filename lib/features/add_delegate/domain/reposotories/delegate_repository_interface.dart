// ignore_for_file: file_names, non_constant_identifier_names

import 'package:sixam_mart/features/add_delegate/domain/models/delegate_api_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:flutter/material.dart';

abstract class DelegateRepositoryInterface {
  //

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
