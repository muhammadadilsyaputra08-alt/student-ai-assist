import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Menyimpan path file model .task yang dipilih user, persisten antar sesi
/// (ditulis ke file kecil di app documents dir, bukan pakai shared_preferences
/// supaya tidak nambah dependency baru).
class ModelPathStore {
  static const _pointerFileName = 'model_path.txt';

  static Future<File> _pointerFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_pointerFileName');
  }

  /// Path model aktif saat ini, atau null kalau belum pernah dipilih.
  static Future<String?> get() async {
    try {
      final file = await _pointerFile();
      if (!await file.exists()) return null;
      final path = (await file.readAsString()).trim();
      if (path.isEmpty) return null;
      // Pastikan file model-nya masih ada (bisa saja terhapus manual)
      if (!await File(path).exists()) return null;
      return path;
    } catch (_) {
      return null;
    }
  }

  static Future<void> set(String modelPath) async {
    final file = await _pointerFile();
    await file.writeAsString(modelPath);
  }

  static Future<void> clear() async {
    final file = await _pointerFile();
    if (await file.exists()) await file.delete();
  }
}
