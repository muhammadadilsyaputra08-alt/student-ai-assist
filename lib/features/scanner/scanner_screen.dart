import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../data/db/app_database.dart';
import '../../data/ocr/ocr_service.dart';

/// Scan halaman jurnal/skripsi → OCR offline → simpan teks ke SQLite
/// (journal_sources) supaya bisa diambil RagService saat query.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _camera;
  bool _busy = false;
  String? _lastText;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
    await controller.initialize();
    if (!mounted) return;
    setState(() => _camera = controller);
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await camera.takePicture();
      final text = await OcrService.instance.recognizeFromFile(File(file.path));
      await AppDatabase.instance.insertJournalSource(
        sourcePath: file.path,
        ocrText: text,
      );
      setState(() {
        _lastText = text;
        _busy = false;
      });
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal OCR: $e')));
      }
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Halaman (OCR)')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _camera == null || !_camera!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : CameraPreview(_camera!),
          ),
          if (_lastText != null)
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(_lastText!),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _capture,
        child: _busy ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.camera_alt),
      ),
    );
  }
}
