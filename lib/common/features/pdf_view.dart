import 'dart:io';

import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdfx/pdfx.dart';


class PdfItem {
  final String name;
  final Reference reference;

  PdfItem({required this.name, required this.reference});
}




class PdfViewPage extends StatefulWidget {
  final PdfItem pdf;

  const PdfViewPage({super.key, required this.pdf});

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  PdfControllerPinch? pdfController;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final fileName = widget.pdf.name.replaceAll(RegExp(r'[^\w\s\-.]'), '_');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      if (!await file.exists()) {
        await widget.pdf.reference.writeToFile(file);
      }

      setState(() {
        localPath = file.path;
        pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(file.path),
        );
        isLoading = false;
      });
    } catch (e) {
      ErrorLogger.logError('PdfViewPage', 'Error downloading PDF', error: e);
      setState(() {
        errorMessage = 'Failed to load PDF. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdf.name),
        backgroundColor: AppColors.calPolyGreen,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading PDF...'),
                ],
              ),
            )
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : PdfViewPinch(
                  controller: pdfController!,
                ),
    );
  }
}
