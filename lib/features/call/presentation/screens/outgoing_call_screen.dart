import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/call/data/models/call_model.dart';
import 'package:sixam_mart/features/call/presentation/controllers/call_controller.dart';

/// 📞 Outgoing call screen (customer calling the captain). Shows the captain's
/// photo, name and vehicle number, a live status/timer, and mute + hang-up
/// controls. Reads state reactively from the [CallController] registered under
/// [tag].
class OutgoingCallScreen extends StatelessWidget {
  final String tag;
  final CallPeer peer;
  const OutgoingCallScreen({super.key, required this.tag, required this.peer});

  @override
  Widget build(BuildContext context) {
    final CallController c = Get.find<CallController>(tag: tag);
    final bool isArabic = Get.locale?.languageCode == 'ar';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1F16),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Captain avatar.
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
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
              if ((peer.vehicleNumber ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(peer.vehicleNumber!,
                      style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.white70)),
                ),
              ],
              const SizedBox(height: 18),
              // Status / timer.
              Obx(() {
                final st = c.state.value;
                String label;
                if (st == CallState.connected) {
                  label = c.durationText;
                } else if (st == CallState.failed) {
                  label = isArabic ? 'تعذّر الاتصال' : 'Call failed';
                } else if (st == CallState.ended) {
                  label = isArabic ? 'انتهت المكالمة' : 'Call ended';
                } else {
                  label =
                      isArabic ? 'جارٍ الاتصال بالمندوب...' : 'Calling courier...';
                }
                return Text(label,
                    style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        color: Colors.white70));
              }),
              const Spacer(flex: 3),
              // Controls.
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleControl(
                        icon: c.muted.value ? Icons.mic_off : Icons.mic,
                        bg: Colors.white24,
                        onTap: c.toggleMute,
                      ),
                      const SizedBox(width: 28),
                      _CircleControl(
                        icon: Icons.call_end,
                        bg: const Color(0xFFD64545),
                        big: true,
                        onTap: () async {
                          await c.endCall();
                          Get.back<void>();
                          Get.delete<CallController>(tag: tag);
                        },
                      ),
                      const SizedBox(width: 28),
                      _CircleControl(
                        icon: c.speakerOn.value
                            ? Icons.volume_up
                            : Icons.volume_down,
                        bg: Colors.white24,
                        onTap: c.toggleSpeaker,
                      ),
                    ],
                  )),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleControl extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final bool big;
  final VoidCallback onTap;
  const _CircleControl(
      {required this.icon,
      required this.bg,
      required this.onTap,
      this.big = false});

  @override
  Widget build(BuildContext context) {
    final double d = big ? 70 : 58;
    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: d,
          height: d,
          child: Icon(icon, color: Colors.white, size: big ? 32 : 26),
        ),
      ),
    );
  }
}
