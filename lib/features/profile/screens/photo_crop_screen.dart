import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/util/app_colors.dart';

/// Circular crop + zoom screen. The user pans/pinches (or drags the slider) to
/// frame the photo inside a circle; "حفظ" captures the circle to a PNG file and
/// returns it via `Get.back`.
class PhotoCropScreen extends StatefulWidget {
  final String imagePath;

  const PhotoCropScreen({super.key, required this.imagePath});

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  static const Color _titleColor = Color(0xFF2D3633);
  static const Color _bodyColor = Color(0xFF6C7278);
  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;

  final GlobalKey _cropKey = GlobalKey();

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;
  bool _saving = false;

  void _onScaleStart(ScaleStartDetails details) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_startScale * details.scale).clamp(_minScale, _maxScale);
      _offset = _startOffset + (details.focalPoint - _startFocal);
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final RenderObject? boundary =
          _cropKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('crop boundary missing');
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('encode failed');
      }
      final Uint8List bytes = byteData.buffer.asUint8List();
      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(path);
      await file.writeAsBytes(bytes);
      Get.back<XFile>(result: XFile(file.path));
    } catch (e) {
      showCustomSnackBar('تعذّر حفظ الصورة، حاول مرة أخرى.');
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double circleSize = MediaQuery.of(context).size.width * 0.68;
    return Scaffold(
      backgroundColor: AppColors.wtColor,
      appBar: AppBar(
        backgroundColor: AppColors.wtColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'صورة الملف الشخصي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18, color: _titleColor),
            onPressed: () => Get.back<XFile>(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 24),
            Center(
              child: RepaintBoundary(
                key: _cropKey,
                child: ClipOval(
                  child: SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: GestureDetector(
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      child: Transform.translate(
                        offset: _offset,
                        child: Transform.scale(
                          scale: _scale,
                          child: Image.file(
                            File(widget.imagePath),
                            width: circleSize,
                            height: circleSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _zoomSlider(circleSize),
            const SizedBox(height: 24),
            _guidance(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _saving ? null : _save,
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.wtColor),
                            )
                          : const Text(
                              'حفظ',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomSlider(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: <Widget>[
            _stepButton(Icons.remove, () {
              setState(() =>
                  _scale = (_scale - 0.3).clamp(_minScale, _maxScale));
            }, filled: false),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: _titleColor,
                  inactiveTrackColor: const Color(0xFFE5E7EB),
                  thumbColor: _titleColor,
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  min: _minScale,
                  max: _maxScale,
                  value: _scale,
                  onChanged: (double v) => setState(() => _scale = v),
                ),
              ),
            ),
            _stepButton(Icons.add, () {
              setState(() =>
                  _scale = (_scale + 0.3).clamp(_minScale, _maxScale));
            }, filled: true),
          ],
        ),
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
            size: 18, color: filled ? Colors.white : _bodyColor),
      ),
    );
  }

  Widget _guidance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'يرجى التأكد من أن الصورة:',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 8),
          _bullet('لا توجد بالصورة أي ضبابية والإضاءة بها جيدة'),
          _bullet('دون نظارات أو قبعات أو أي اكسسوارات أخرى'),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 5, color: _bodyColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: _bodyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
