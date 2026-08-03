import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../../data/ai/task_llm_service.dart';
import '../../data/db/app_database.dart';

/// Model path lokal - hasil download on-demand ke app documents directory.
/// Format .task (bundle MediaPipe), contoh: gemma-2b-it-cpu-int4.task.
const _kDefaultModelPath = '/data/user/0/com.studenttools.student_ai_assist/app_flutter/models/gemma3-1b-it-int4.task';

class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({super.key});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  final _controller = TextEditingController();
  bool _preview = false;
  bool _busy = false;

  Future<void> _runAi(Future<String> Function(String, String) action) async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await action(_kDefaultModelPath, _controller.text);
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
            icon: Icon(_preview ? Icons.edit : Icons.preview),
            onPressed: () => setState(() => _preview = !_preview),
          ),
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: _save),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
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
