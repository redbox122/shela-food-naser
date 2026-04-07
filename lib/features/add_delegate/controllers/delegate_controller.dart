// ignore_for_file: camel_case_types, file_names, non_constant_identifier_names, override_on_non_overriding_member, prefer_final_fields, unnecessary_null_comparison

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/add_delegate/domain/models/delegate_api_model.dart';
import 'package:sixam_mart/features/add_delegate/domain/services/delegate_service_interface.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';

class Delegate_Controller extends GetxController implements GetxService {
  final Delegate_ServiceInterface delegateServiceInterface;

  Delegate_Controller({required this.delegateServiceInterface});

  DelegateModel? delegate_model;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final TextEditingController f_name_Controller = TextEditingController();
  final TextEditingController l_name_Controller = TextEditingController();
  final TextEditingController mobile_Controller = TextEditingController();
  final TextEditingController imgName_Controller = TextEditingController();

  final List<NamedFile> All_files = [];

  void pickFileWithName(BuildContext context) async {
    if (imgName_Controller.text.trim().isEmpty) {
      showCustomSnackBar('يرجى إدخال الاسم');
      return;
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: true,
    );

    if (result != null) {
      All_files.add(
        NamedFile(
          name: imgName_Controller.text.trim(),
          file: result.files.first,
        ),
      );
      update();
    }

    imgName_Controller.clear();
  }

  void removeFile(int index) {
    if (index >= 0 && index < All_files.length) {
      All_files.removeAt(index);
      update();
    }
  }

  Future<void> sent_Delegate(
    BuildContext context,
    int id,
    String mobile,
  ) async {
    if (f_name_Controller.text.isEmpty ||
        l_name_Controller.text.isEmpty ||
        mobile.isEmpty) {
      showCustomSnackBar('يرجى تعبئة جميع الحقول');
      return;
    }

    if (All_files.isEmpty) {
      showCustomSnackBar('لم يتم حفظ أي مستند');
      return;
    }

    _isLoading = true;
    update();

    try {
      await delegateServiceInterface.send_Delegate(
        context,
        id,
        f_name_Controller.text,
        l_name_Controller.text,
        mobile,
        All_files,
      );

      await get_Delegate();
    } catch (e) {
      debugPrint('خطأ أثناء إرسال المندوب: $e');
    }

    _isLoading = false;
    update();
  }

  Future<void> get_Delegate() async {
    _isLoading = true;
    update();

    try {
      delegate_model = await delegateServiceInterface.getDelegate();
    } catch (e) {
      debugPrint('خطأ أثناء جلب المندوب: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  @override
  void onClose() {
    f_name_Controller.dispose();
    l_name_Controller.dispose();
    mobile_Controller.dispose();
    imgName_Controller.dispose();
    super.onClose();
  }
}
