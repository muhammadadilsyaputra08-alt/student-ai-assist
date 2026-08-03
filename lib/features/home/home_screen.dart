import 'package:flutter/material.dart';
import '../editor/markdown_editor_screen.dart';
import '../pdf/pdf_viewer_screen.dart';
import '../scanner/scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('Catatan Markdown', Icons.edit_note, const MarkdownEditorScreen()),
      _MenuItem('Baca PDF / Jurnal', Icons.picture_as_pdf, const PdfViewerScreen()),
      _MenuItem('Scan Halaman (OCR)', Icons.document_scanner, const ScannerScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Student AI Assist')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return Card(
            child: ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => item.screen),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  _MenuItem(this.label, this.icon, this.screen);
  final String label;
  final IconData icon;
  final Widget screen;
}
