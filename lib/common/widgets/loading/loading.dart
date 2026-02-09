import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  final String? messageKey;
  final bool showMessage;
  const LoadingWidget({super.key, this.messageKey, this.showMessage = true});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final String resolvedKey = messageKey ?? 'loading';
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Lottie.asset(
              'assets/json/waiting.json',
              fit: BoxFit.contain,
              height: size.height * 0.26,
            ),
          ),
          if (showMessage) ...[
            const SizedBox(height: 16),
            Text(
              resolvedKey.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
