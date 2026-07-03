import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/call/data/models/call_model.dart';
import 'package:sixam_mart/features/call/presentation/controllers/call_controller.dart';
import 'package:sixam_mart/features/call/presentation/screens/outgoing_call_screen.dart';

/// 📞 In-app voice-call button (customer → captain, no phone numbers shown).
/// Drop this anywhere (e.g. next to the driver card on the tracking screen).
/// Self-contained: it registers a [CallController], opens the outgoing-call
/// screen and starts the call.
class CallButton extends StatelessWidget {
  final int orderId;
  final int? customerId;
  final int? driverId;
  final CallPeer peer;
  final double size;

  const CallButton({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.driverId,
    required this.peer,
    this.size = 44,
  });

  void _start() {
    final controller = Get.put(CallController(), tag: 'call_$orderId');
    Get.to<void>(() => OutgoingCallScreen(tag: 'call_$orderId', peer: peer));
    controller.startCall(
      orderId: orderId,
      callerId: customerId,
      receiverId: driverId,
      withPeer: peer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1F7A35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _start,
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.call, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
