// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, camel_case_types

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:sixam_mart/features/add_delegate/controllers/delegate_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class Delegate_FileUploadWidget extends StatefulWidget {
  const Delegate_FileUploadWidget({super.key});

  @override
  State<Delegate_FileUploadWidget> createState() => _Delegate_FileUploadWidgetState();
}

class _Delegate_FileUploadWidgetState extends State<Delegate_FileUploadWidget> {
  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<Delegate_Controller>(
      builder: (delegate_Controller) {
        return Column(
          children: [
            TextFormField(
              cursorColor: AppColors.bgColor,
              controller: delegate_Controller.imgName_Controller,
              decoration: InputDecoration(
                hintText: 'اسم الملف',
                hintStyle: font10Grey500W(context, size: size_14(context)),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.gryColor_3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.greenColor),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                delegate_Controller.pickFileWithName(context);
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('اختر ملفًا وأضفه'),
            ),
            const SizedBox(height: 20),
            if (delegate_Controller.All_files.isNotEmpty)
              Column(
                children: delegate_Controller.All_files.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final NamedFile item = entry.value;
                  final String? filePath = item.file.path;
                  final bool isImage = _isImageFile(item.file.name);

                  Widget leadingWidget;
                  if (isImage && filePath != null && filePath.isNotEmpty) {
                    leadingWidget = ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(filePath),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(Icons.insert_drive_file, size: 32, color: Colors.blueGrey);
                        },
                      ),
                    );
                  } else {
                    leadingWidget = Icon(
                      item.file.name.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.insert_drive_file,
                      size: 32,
                      color: item.file.name.toLowerCase().endsWith('.pdf') ? Colors.red : Colors.blueGrey,
                    );
                  }

                  return Card(
                    child: ListTile(
                      leading: leadingWidget,
                      title: Text(item.name),
                      subtitle: Text(item.file.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => delegate_Controller.removeFile(index),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}
