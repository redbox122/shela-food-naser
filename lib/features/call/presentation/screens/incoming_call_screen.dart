import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/call/data/models/call_model.dart';
import 'package:sixam_mart/features/call/presentation/controllers/call_controller.dart';
import 'package:sixam_mart/features/call/presentation/screens/outgoing_call_screen.dart';

/// 📲 Incoming call screen (the captain is calling the customer). Shows the
/// captain's photo + name and answer / reject buttons. Answering joins the
/// Agora channel and swaps to the active-call UI; rejecting just closes.
class IncomingCallScreen extends StatelessWidget {
  final IncomingCallPayload payload;
  const IncomingCallScreen({super.key, required this.payload});

  String get _tag => 'call_${payload.orderId ?? 0}';

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Get.locale?.languageCode == 'ar';
    final peer = payload.peer;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1F16),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white24),
                clipBehavior: Clip.antiAlias,
                child: (peer.imageUrl ?? '').isNotEmpty
                    ? CustomImage(image: peer.imageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.person, size: 70, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Text(
                peer.name?.isNotEmpty == true
                    ? peer.name!
                    : (isArabic ? 'المندوب' : 'Courier'),
                style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(isArabic ? 'المندوب يتصل بك' : 'Courier is calling you',
                  style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: Colors.white70)),
              const Spacer(flex: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AnswerButton(
                    icon: Icons.call_end,
                    label: isArabic ? 'رفض' : 'Reject',
                    color: const Color(0xFFD64545),
                    onTap: () => Get.back<void>(),
                  ),
                  _AnswerButton(
                    icon: Icons.call,
                    label: isArabic ? 'رد' : 'Answer',
                    color: const Color(0xFF1F7A35),
                    onTap: () => _answer(),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _answer() {
    final controller = Get.put(CallController(), tag: _tag);
    Get.off<void>(() => OutgoingCallScreen(tag: _tag, peer: payload.peer));
    controller.startCall(
      orderId: payload.orderId ?? 0,
      callerId: null,
      receiverId: payload.callerId,
      withPeer: payload.peer,
      incoming: true,
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AnswerButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Tajawal', fontSize: 14, color: Colors.white70)),
      ],
    );
  }
}
