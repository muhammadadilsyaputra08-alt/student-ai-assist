import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR 100% offline via Google ML Kit (Android) / Apple Vision (iOS,
/// dijembatani plugin yang sama). Dipakai untuk scan halaman jurnal/skripsi
/// dari kamera lalu diteks-kan ke SQLite + RagService.
class OcrService {
  OcrService._internal();
  static final OcrService instance = OcrService._internal();

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  Future<void> dispose() => _recognizer.close();
}
