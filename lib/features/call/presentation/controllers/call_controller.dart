import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/call/data/models/call_model.dart';
import 'package:sixam_mart/features/call/data/repositories/call_repository.dart';

enum CallState { idle, connecting, ringing, connected, ended, failed }

/// Self-contained voice-call controller (Agora RTC). Nothing else in the app is
/// modified — this is registered lazily only when a call starts.
///
/// Flow: request a token → initialize the engine → join the channel → wait for
/// the other party (onUserJoined) → track a call timer → mute / hang up.
class CallController extends GetxController {
  CallController({CallRepository? repository})
      : _repo = repository ?? CallRepository();

  final CallRepository _repo;
  RtcEngine? _engine;
  Timer? _timer;

  final Rx<CallState> state = CallState.idle.obs;
  final RxBool muted = false.obs;
  final RxBool speakerOn = false.obs;
  final RxInt seconds = 0.obs;
  final Rxn<CallPeer> peer = Rxn<CallPeer>();

  /// mm:ss timer text.
  String get durationText {
    final s = seconds.value;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  /// Starts (or answers) a call for [orderId] between the customer [callerId]
  /// and the driver [receiverId]. [incoming] just tweaks the initial state.
  Future<void> startCall({
    required int orderId,
    required int? callerId,
    required int? receiverId,
    CallPeer? withPeer,
    bool incoming = false,
  }) async {
    peer.value = withPeer;
    state.value = incoming ? CallState.connecting : CallState.connecting;

    final CallTokenModel? tk = await _repo.requestToken(
      orderId: orderId,
      callerType: 'customer',
      callerId: callerId,
      receiverId: receiverId,
    );
    if (tk == null || tk.channelName.isEmpty) {
      state.value = CallState.failed;
      return;
    }

    try {
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: tk.appId));
      await engine.enableAudio();
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection conn, int elapsed) {
          state.value = incoming ? CallState.connected : CallState.ringing;
          if (incoming) _startTimer();
        },
        onUserJoined: (RtcConnection conn, int remoteUid, int elapsed) {
          // The other party picked up → conversation begins.
          state.value = CallState.connected;
          _startTimer();
        },
        onUserOffline: (RtcConnection conn, int remoteUid,
            UserOfflineReasonType reason) {
          endCall();
        },
        onError: (ErrorCodeType err, String msg) {
          if (kDebugMode) debugPrint('Agora error: $err $msg');
        },
      ));

      _engine = engine;
      await engine.joinChannel(
        token: tk.token,
        channelId: tk.channelName,
        uid: tk.uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('startCall failed: $e');
      state.value = CallState.failed;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds.value += 1;
    });
  }

  Future<void> toggleMute() async {
    muted.value = !muted.value;
    await _engine?.muteLocalAudioStream(muted.value);
  }

  Future<void> toggleSpeaker() async {
    speakerOn.value = !speakerOn.value;
    await _engine?.setEnableSpeakerphone(speakerOn.value);
  }

  Future<void> endCall() async {
    _timer?.cancel();
    state.value = CallState.ended;
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
    _engine = null;
  }

  @override
  void onClose() {
    _timer?.cancel();
    _engine?.release();
    super.onClose();
  }
}
