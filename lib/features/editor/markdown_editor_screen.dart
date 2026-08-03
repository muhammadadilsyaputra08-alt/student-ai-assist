import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../../data/ai/model_path_store.dart';
import '../../data/ai/task_llm_service.dart';
import '../../data/db/app_database.dart';

class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({super.key});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  final _controller = TextEditingController();
  bool _preview = false;
  bool _busy = false;
  String? _modelPath;
  bool _loadingModelPath = true;

  @override
  void initState() {
    super.initState();
    _loadModelPath();
  }

  Future<void> _loadModelPath() async {
    final path = await ModelPathStore.get();
    if (!mounted) return;
    setState(() {
      _modelPath = path;
      _loadingModelPath = false;
    });
  }

  /// User pilih file .task langsung dari penyimpanan HP - tidak perlu adb
  /// atau folder privat app sama sekali. File tidak di-copy, dipakai
  /// langsung dari path aslinya (butuh READ_EXTERNAL_STORAGE, sudah ada di
  /// AndroidManifest).
  Future<void> _pickModel() async {
    try {
      // Filter ekstensi custom '.task' tidak dikenali SAF di banyak device
      // Android (PlatformException: Unsupported filter) - jadi langsung
      // pakai "semua file", validasi ekstensi manual setelah dipilih.
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      final path = result?.files.single.path;
      if (path == null) return;

      if (!path.toLowerCase().endsWith('.task')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File harus berekstensi .task, kamu pilih: ${path.split('/').last}')),
          );
        }
        return;
      }

      await ModelPathStore.set(path);
      setState(() => _modelPath = path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model aktif: ${path.split('/').last}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal buka file picker: $e')),
        );
      }
    }
  }

  Future<void> _runAi(Future<String> Function(String, String) action) async {
    if (_controller.text.trim().isEmpty) return;
    if (_modelPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file model .task dulu (tombol di pojok kanan atas)')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await action(_modelPath!, _controller.text);
      setState(() {
        _controller.text = result;
        _busy = false;
      });
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menjalankan AI: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    await AppDatabase.instance.insertNote(
      title: _controller.text.split('\n').first.trim().isEmpty
          ? 'Catatan tanpa judul'
          : _controller.text.split('\n').first.trim(),
      bodyMd: _controller.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tersimpan lokal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Markdown'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: _modelPath == null ? 'Pilih model AI (.task)' : 'Ganti model AI',
            onPressed: _pickModel,
          ),
          IconButton(
            icon: Icon(_preview ? Icons.edit : Icons.preview),
            onPressed: () => setState(() => _preview = !_preview),
          ),
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: _save),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (!_loadingModelPath && _modelPath == null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                'Belum ada model AI dipilih. Tap ikon robot di kanan atas untuk pilih file .task.',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          Expanded(
            child: _preview
                ? MarkdownWidget(data: _controller.text)
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Tulis catatan / draft laporan di sini...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Wrap(
              spacing: 8,
              children: [
                _AiChip(
                  label: 'Ringkas',
                  onTap: _busy ? null : () => _runAi(TaskLlmService.instance.summarize),
                ),
                _AiChip(
                  label: 'Parafrase',
                  onTap: _busy ? null : () => _runAi(TaskLlmService.instance.paraphrase),
                ),
                _AiChip(
                  label: 'Perbaiki Grammar',
                  onTap: _busy ? null : () => _runAi(TaskLlmService.instance.fixGrammar),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: ActionChip(label: Text(label), onPressed: onTap),
    );
  }
}
