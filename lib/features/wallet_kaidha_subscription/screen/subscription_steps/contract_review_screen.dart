// ignore_for_file: prefer_const_literals_to_create_immutables, non_constant_identifier_names, camel_case_types

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/contract_pdf_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class Contract_ReviewScreen extends StatefulWidget {
  const Contract_ReviewScreen({super.key});

  @override
  State<Contract_ReviewScreen> createState() => _Contract_ReviewScreenState();
}

class _Contract_ReviewScreenState extends State<Contract_ReviewScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  ContractPdfModel? _pdfModel;
  bool _isLoading = false;
  String? _errorMessage;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(fn);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadContractPdf();
  }

  Future<void> _loadContractPdf() async {
    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = Get.find<KaidhaSubscriptionController>();
      ContractPdfModel? pdfModel = controller.contract_Pdf_Model;

      // If screen is opened directly, fetch PDF before rendering.
      if (pdfModel == null) {
        await controller.get_Pdf();
        pdfModel = controller.contract_Pdf_Model;
      }

      if (pdfModel == null ||
          pdfModel.filePath.isEmpty ||
          !File(pdfModel.filePath).existsSync()) {
        _safeSetState(() {
          _errorMessage = 'فشل تحميل العقد';
          _pdfModel = null;
        });
        return;
      }

      final int resolvedFileSize = pdfModel.fileSize > 0
          ? pdfModel.fileSize
          : File(pdfModel.filePath).lengthSync();
      debugPrint('حجم الملف: $resolvedFileSize');

      _safeSetState(() {
        _pdfModel = pdfModel;
      });
    } catch (e) {
      _safeSetState(() {
        _errorMessage = 'فشل تحميل العقد';
      });
      debugPrint('Error loading PDF: $e');
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Center(child: Text('عرض العقد'))),
      body: _buildBody(),
      floatingActionButton: _buildPageControls(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return GetBuilder<KaidhaSubscriptionController>(
        builder: (KaidhaSubController) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (KaidhaSubController.isLoading == true)
                  const CircularProgressIndicator()
                else
                  const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadContractPdf,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        },
      );
    }

    if (_pdfModel == null) {
      return const Center(child: Text('لا يوجد عقد متاح'));
    }

    return SfPdfViewer.file(
      File(_pdfModel!.filePath),
      controller: _pdfViewerController,
      pageLayoutMode: PdfPageLayoutMode.single,
      canShowPaginationDialog: false,
    );
  }

  Widget _buildPageControls() {
    if (_pdfModel == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          heroTag: 'next',
          mini: true,
          onPressed: () => _pdfViewerController.nextPage(),
          child: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: 20),
        FloatingActionButton(
          heroTag: 'prev',
          mini: true,
          onPressed: () => _pdfViewerController.previousPage(),
          child: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
