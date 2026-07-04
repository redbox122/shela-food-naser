import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/util/app_colors.dart';

/// Bottom sheet shown when the user edits an already-set profile photo.
/// Lets them re-frame (pan/zoom) the current photo, capture a new one, or
/// remove it.
class ProfilePhotoEditSheet extends StatefulWidget {
  /// Local file path of the current picked photo, if any.
  final String? localPath;

  /// Remote URL of the current server avatar, if any.
  final String? imageUrl;

  const ProfilePhotoEditSheet({super.key, this.localPath, this.imageUrl});

  @override
  State<ProfilePhotoEditSheet> createState() => _ProfilePhotoEditSheetState();
}

class _ProfilePhotoEditSheetState extends State<ProfilePhotoEditSheet> {
  static const Color _titleColor = Color(0xFF2D3633);
  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;

  final GlobalKey _cropKey = GlobalKey();

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  bool get _hasLocal => (widget.localPath ?? '').isNotEmpty;

  void _onScaleStart(ScaleStartDetails d) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = d.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _scale = (_startScale * d.scale).clamp(_minScale, _maxScale);
      _offset = _startOffset + (d.focalPoint - _startFocal);
    });
  }

  /// Re-captures the framed circle and stores it as the new picked file.
  Future<void> _applyFraming() async {
    try {
      final RenderObject? boundary =
          _cropKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return;
      }
      final Uint8List bytes = byteData.buffer.asUint8List();
      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(path);
      await file.writeAsBytes(bytes);
      // Save only the framed preview — keep the original so zoom stays
      // reversible on subsequent edits.
      Get.find<ProfileController>().setFramedFile(XFile(file.path));
    } catch (_) {
      // Framing is best-effort; ignore capture failures.
    }
  }

  Future<void> _changePhoto() async {
    Get.back<void>();
    final XFile? file =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (file != null) {
      Get.find<ProfileController>().setPickedFile(file);
    }
  }

  void _removePhoto() {
    Get.find<ProfileController>().removePickedFile();
    Get.back<void>();
    showCustomSnackBar('pf_photo_removed'.tr, isError: false);
  }

  @override
  Widget build(BuildContext context) {
    final double circleSize = MediaQuery.of(context).size.width * 0.5;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                InkWell(
                  onTap: () => Get.back<void>(),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 22, color: _titleColor),
                  ),
                ),
                Expanded(
                  child: Text(
                    'pf_profile_photo'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _cropKey,
              child: ClipOval(
                child: SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: GestureDetector(
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    onScaleEnd: (_) => _applyFraming(),
                    child: Transform.translate(
                      offset: _offset,
                      child: Transform.scale(
                        scale: _scale,
                        child: _buildImage(circleSize),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _zoomSlider(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Material(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _changePhoto,
                  child: Center(
                    child: Text(
                      'pf_change_photo'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.wtColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _removePhoto,
              child: Text(
                'pf_remove_profile_photo'.tr,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double size) {
    if (_hasLocal) {
      return Image.file(
        File(widget.localPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    if ((widget.imageUrl ?? '').isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primaryColor.withValues(alpha: 0.10),
      child: const Icon(Icons.person, size: 48, color: AppColors.primaryColor),
    );
  }

  Widget _zoomSlider() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: <Widget>[
          _stepButton(Icons.remove, () {
            setState(
                () => _scale = (_scale - 0.3).clamp(_minScale, _maxScale));
            _applyFraming();
          }, filled: false),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: _titleColor,
                inactiveTrackColor: const Color(0xFFE5E7EB),
                thumbColor: _titleColor,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                min: _minScale,
                max: _maxScale,
                value: _scale,
                onChanged: (double v) => setState(() => _scale = v),
                onChangeEnd: (_) => _applyFraming(),
              ),
            ),
          ),
          _stepButton(Icons.add, () {
            setState(
                () => _scale = (_scale + 0.3).clamp(_minScale, _maxScale));
            _applyFraming();
          }, filled: true),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap, {required bool filled}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? _titleColor : const Color(0xFFE5E7EB),
        ),
        child: Icon(icon,
            size: 18, color: filled ? Colors.white : const Color(0xFF6C7278)),
      ),
    );
  }
}
