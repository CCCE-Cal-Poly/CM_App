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

class Asc2026Maps extends StatefulWidget {
  const Asc2026Maps({super.key});

  @override
  State<Asc2026Maps> createState() => _Asc2026MapsState();
}

class _Asc2026MapsState extends State<Asc2026Maps> {
  List<PdfItem> pdfs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPdfs();
  }

  Future<void> fetchPdfs() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('ASC_2026_Maps');
      final result = await ref.listAll();
      List<PdfItem> fetchedPdfs = [];
      for (var item in result.items) {
        if (item.name.endsWith('.pdf')) {
          // String url = await item.getDownloadURL();
          Reference pdfRef = item;
          fetchedPdfs.add(PdfItem(name: item.name, reference: pdfRef));
        }
      }
      setState(() {
        pdfs = fetchedPdfs;
        isLoading = false;
      });
    } catch (e) {
      ErrorLogger.logError('PdfViewerPage', 'Error fetching PDFs', error: e);
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load PDFs')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASC 2026 Maps'),
        backgroundColor: AppColors.calPolyGreen,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pdfs.isEmpty
              ? const Center(child: Text('No PDFs available'))
              : ListView.builder(
                  itemCount: pdfs.length,
                  itemBuilder: (context, index) {
                    final pdf = pdfs[index];
                    return ListTile(
                      title: Text(pdf.name),
                      leading: const Icon(Icons.picture_as_pdf),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PdfViewPage(
                              pdf: pdf,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
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