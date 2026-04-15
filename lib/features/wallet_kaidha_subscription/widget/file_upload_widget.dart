// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class FileUploadWithNameWidget extends StatefulWidget {
  const FileUploadWithNameWidget({super.key});

  @override
  State<FileUploadWithNameWidget> createState() => _FileUploadWithNameWidgetState();
}

class _FileUploadWithNameWidgetState extends State<FileUploadWithNameWidget> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscriptionController>(builder: (KaidhaSubController) {
      return Column(
        children: [
          // TextField لإدخال الاسم

          TextFormField(
            cursorColor: AppColors.bgColor,
            controller: KaidhaSubController.imgName_Controller,
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

          // زر اختيار الصورة
          ElevatedButton.icon(
            onPressed: () {
              KaidhaSubController.pickFileWithName(context);
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('اختر صورة وأضفها'),
          ),

          const SizedBox(height: 20),

          // عرض الملفات المضافة
          if (KaidhaSubController.All_files.isNotEmpty)
            Column(
              children: KaidhaSubController.All_files.asMap().entries.map((entry) {
                final int index = entry.key;
                final NamedFile item = entry.value;

                return Card(
                  child: ListTile(
                    leading: Image.file(File(item.file.path!), width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(item.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => KaidhaSubController.removeFile(index),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      );
    });
  }
}
