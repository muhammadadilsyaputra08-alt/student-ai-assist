import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Viewer PDF native (pinch-zoom bawaan pdfx). Tanpa annotasi kompleks
/// (highlight/draw/comment) - itu sengaja dieliminasi (lihat blueprint §2).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfControllerPinch? _controller;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() {
      _controller = PdfControllerPinch(document: PdfDocument.openFile(path));
      _fileName = result!.files.single.name;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName ?? 'Baca PDF / Jurnal'),
        actions: [IconButton(icon: const Icon(Icons.folder_open), onPressed: _pickFile)],
      ),
      body: _controller == null
          ? Center(
              child: FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Pilih PDF'),
              ),
            )
          : PdfViewPinch(controller: _controller!),
    );
  }
}
