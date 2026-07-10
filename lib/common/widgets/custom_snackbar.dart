import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/backend_message_translator.dart';
import 'package:sixam_mart/util/styles.dart';

/// Styled bottom success snackbar (light-green pill + check badge + green text).
/// Ported with the old checkout wallet sheets — a non-blocking confirmation for
/// actions like selecting a payment method.
void showSelectionSnackBar(String message) {
  if (message.isEmpty) return;
  if (Get.isSnackbarOpen) {
    Get.closeAllSnackbars();
  }
  Get.showSnackbar(GetSnackBar(
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: const Color(0xFFEAF8EE),
    borderRadius: 8,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    padding: const EdgeInsets.all(8),
    duration: const Duration(seconds: 2),
    messageText: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified, color: Color(0xFF2FA84F), size: 22),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: tajawalBold.copyWith(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF2FA84F),
            ),
          ),
        ),
      ],
    ),
  ));
}

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
  } catch (e) {
    if (kDebugMode) debugPrint('$e');
  }

  return input;
}
