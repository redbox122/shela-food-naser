import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/backend_message_translator.dart';

void showCustomSnackBar(String? message,
    {bool isError = true, bool getXSnackBar = false, int? showDuration}) {
  if (message != null && message.isNotEmpty) {
    final String normalizedMessage = _normalizePotentialMojibake(message);

    // Translate backend messages
    final String translatedMessage =
        BackendMessageTranslator.translate(normalizedMessage);

    Get.dialog(
      Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 220,
              maxWidth: Get.width * 0.85,
              maxHeight: Get.height * 0.7,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isError ? Icons.error : Icons.check_circle,
                      color: isError ? Colors.red : Colors.green, size: 50),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: Get.height * 0.35),
                    child: SingleChildScrollView(
                      child: Text(
                        translatedMessage,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    Future.delayed(Duration(seconds: showDuration ?? 2), () {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    });
  }
}

String _normalizePotentialMojibake(String input) {
  // Common markers when UTF-8 Arabic text is decoded using latin1/win1252.
  final bool looksMojibake = input.contains('�') ||
      input.contains('�') ||
      input.contains('�') ||
      input.contains('�') ||
      input.contains('�') ||
      input.contains('ï»¿');
  if (!looksMojibake) {
    return input;
  }

  try {
    String candidate = input;
    for (int i = 0; i < 2; i++) {
      final List<int> bytes = latin1.encode(candidate);
      final String decoded = utf8.decode(bytes, allowMalformed: false);

      final bool decodedStillBroken = decoded.contains('�') ||
          decoded.contains('�') ||
          decoded.contains('�') ||
          decoded.contains('�') ||
          decoded.contains('�') ||
          decoded.contains('ï»¿');

      if (decoded.isNotEmpty && !decodedStillBroken) {
        return decoded;
      }
      candidate = decoded;
    }
  } catch (_) {}

  return input;
}

