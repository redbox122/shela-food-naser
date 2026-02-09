// ignore_for_file: use_key_in_widget_constructors, camel_case_types, library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:sixam_mart/common/widgets/appBar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/dialog.dart/success_celebration_dialog.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class Qr_Screen extends StatefulWidget {
  @override
  _Qr_ScreenState createState() => _Qr_ScreenState();
}

class _Qr_ScreenState extends State<Qr_Screen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? otpCode;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(fn);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom_AppBar(
        context,
        title: 'أسكان QR',
        icon: Icons.arrow_back_sharp,
        img_icon: Images.qr,
        onPressed: () {
          Get.back();
        },
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            child: Container(
              width: 400,
              padding: EdgeInsets.all(Dimensions.fontSizeDefault),
              child: CustomButton(
                buttonText: otpCode != null ? 'QR:  $otpCode' : 'فحص QR code',
                onPressed: () async {
                  //
                  if (otpCode != null) {
                    Get.offNamed(RouteHelper.getKiadaWalletSubscription());

                    showDialog(
                      context: context,
                      barrierDismissible:
                          false, // لا يمكن إغلاقه بالضغط بالخارج
                      barrierColor: Colors.white, // خلفية شفافة جداً
                      builder: (_) => const Dialog(
                        backgroundColor: Colors
                            .transparent, // يجعل خلفية الـ Dialog نفسه شفافة
                        insetPadding: EdgeInsets.all(0), // لا يوجد هامش
                        child: SuccessCelebrationWidget(),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code;

      if (code != null) {
        controller.pauseCamera();

        _safeSetState(() {
          otpCode = code;
          // QR code scanned: $code
        });
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
