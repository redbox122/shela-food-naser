import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Mobile sticky cart position: **default** matches the original edge alignment
/// (start, 0.22). Moving only works after the user **holds touch for 4+ seconds**,
/// then drags; position persists in [SharedPreferences].
class MobileStickyCartPositionable extends StatefulWidget {
  const MobileStickyCartPositionable({
    super.key,
    required this.bottomPad,
    required this.startSafe,
    required this.textDirection,
    required this.child,
  });

  final double bottomPad;
  final double startSafe;
  final TextDirection textDirection;
  final Widget child;

  @override
  State<MobileStickyCartPositionable> createState() =>
      _MobileStickyCartPositionableState();
}

class _MobileStickyCartPositionableState
    extends State<MobileStickyCartPositionable> {
  static const double _kDefaultAlignY = 0.22;
  static const double _kFlipThresholdFraction = 0.15;
  static const double _kPostFlipNudge = 12;
  static const Duration _kHoldToDragDuration = Duration(seconds: 4);

  late double _nudgeDx;
  late double _nudgeDy;
  late bool _alignStart;
  Timer? _holdTimer;
  int? _activePointer;
  bool _dragArmed = false;
  bool _didDragWhileArmed = false;

  @override
  void initState() {
    super.initState();
    _nudgeDx = 0;
    _nudgeDy = 0;
    _alignStart = true;
    _readPrefsIntoFields();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _readPrefsIntoFields() {
    if (!Get.isRegistered<SharedPreferences>()) {
      return;
    }
    try {
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      _nudgeDx = prefs.getDouble(AppConstants.stickyCartBubbleNudgeDx) ?? 0;
      _nudgeDy = prefs.getDouble(AppConstants.stickyCartBubbleNudgeDy) ?? 0;
      _alignStart =
          prefs.getBool(AppConstants.stickyCartBubbleAlignStart) ?? true;
    } catch (e) {
      if (kDebugMode) debugPrint('$e');
    }
  }

  Future<void> _savePrefs() async {
    if (!Get.isRegistered<SharedPreferences>()) {
      return;
    }
    try {
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      await prefs.setDouble(AppConstants.stickyCartBubbleNudgeDx, _nudgeDx);
      await prefs.setDouble(AppConstants.stickyCartBubbleNudgeDy, _nudgeDy);
      await prefs.setBool(AppConstants.stickyCartBubbleAlignStart, _alignStart);
    } catch (e) {
      if (kDebugMode) debugPrint('$e');
    }
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _cancelHold();
    _dragArmed = false;
    _didDragWhileArmed = false;
    _activePointer = event.pointer;
    _holdTimer = Timer(_kHoldToDragDuration, () {
      if (!mounted || _activePointer != event.pointer) {
        return;
      }
      setState(() {
        _dragArmed = true;
      });
      HapticFeedback.heavyImpact();
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || !_dragArmed) {
      return;
    }
    _didDragWhileArmed = true;
    final Size screenSize = MediaQuery.sizeOf(context);
    setState(() {
      _nudgeDx += event.delta.dx;
      _nudgeDy += event.delta.dy;
      _clampNudge(screenSize);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _cancelHold();
    _activePointer = null;
    if (!_dragArmed) {
      return;
    }
    final Size screenSize = MediaQuery.sizeOf(context);
    if (_didDragWhileArmed) {
      setState(() {
        _maybeFlipEdge(screenSize.width);
        _clampNudge(screenSize);
      });
      HapticFeedback.selectionClick();
      unawaited(_savePrefs());
    }
    setState(() {
      _dragArmed = false;
      _didDragWhileArmed = false;
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _cancelHold();
    _activePointer = null;
    setState(() {
      _dragArmed = false;
      _didDragWhileArmed = false;
    });
  }

  Offset _edgePeekOffset() {
    if (widget.startSafe > 0) {
      return Offset.zero;
    }
    final bool rtl = widget.textDirection == TextDirection.rtl;
    if (_alignStart) {
      return Offset(rtl ? 8 : -8, 0);
    }
    return Offset(rtl ? -8 : 8, 0);
  }

  void _clampNudge(Size screenSize) {
    final double maxX = screenSize.width * 0.42;
    final double maxYUp = screenSize.height * 0.38;
    final double maxYDown = screenSize.height * 0.42 - widget.bottomPad - 24;
    _nudgeDx = _nudgeDx.clamp(-maxX, maxX);
    _nudgeDy = _nudgeDy.clamp(-maxYUp, maxYDown);
  }

  void _maybeFlipEdge(double screenWidth) {
    final double t = screenWidth * _kFlipThresholdFraction;
    final bool rtl = widget.textDirection == TextDirection.rtl;
    if (_alignStart) {
      final bool towardEnd = rtl ? (_nudgeDx < -t) : (_nudgeDx > t);
      if (towardEnd) {
        _alignStart = false;
        _nudgeDx = rtl ? _kPostFlipNudge : -_kPostFlipNudge;
      }
    } else {
      final bool towardStart = rtl ? (_nudgeDx > t) : (_nudgeDx < -t);
      if (towardStart) {
        _alignStart = true;
        _nudgeDx = rtl ? -_kPostFlipNudge : _kPostFlipNudge;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPad),
      child: Align(
        alignment: AlignmentDirectional(
          _alignStart ? -1.0 : 1.0,
          _kDefaultAlignY,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: _alignStart ? widget.startSafe : 0,
            end: _alignStart ? 0 : widget.startSafe,
          ),
          child: Transform.translate(
            offset: _edgePeekOffset() + Offset(_nudgeDx, _nudgeDy),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
