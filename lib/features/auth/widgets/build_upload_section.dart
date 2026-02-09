import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Widget buildUploadSection(
  BuildContext context, {
  required String title,
  required List<XFile> images,
  required VoidCallback onAdd,
  required Function(int) onRemove,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      ...images.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(file.path), height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: InkWell(
                  onTap: () {
                    onRemove(index);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.delete_forever, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      if (images.length < 2)
        InkWell(
          onTap: onAdd,
          child: DottedBorder(
            color: Theme.of(context).primaryColor,
            dashPattern: const [5, 5],
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Theme.of(context).disabledColor, size: 38),
                    Text('رفع صورة', style: TextStyle(color: Theme.of(context).disabledColor)),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
