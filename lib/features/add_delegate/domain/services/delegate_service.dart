// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sixam_mart/features/add_delegate/domain/models/delegate_api_model.dart';
import 'package:sixam_mart/features/add_delegate/domain/reposotories/delegate_repository_interface.dart';
import 'package:sixam_mart/features/add_delegate/domain/services/delegate_service_interface.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';

class DelegateService implements Delegate_ServiceInterface {
  final DelegateRepositoryInterface delegateRepositoryinterface;

  DelegateService({required this.delegateRepositoryinterface});

  @override
  Future<DelegateModel?> getDelegate() async {
    return await delegateRepositoryinterface.getDelegate();
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
    return await delegateRepositoryinterface.send_Delegate(
      context,
      id,
      f_name,
      L_name,
      mobile,
      list_img,
    );
  }
}
