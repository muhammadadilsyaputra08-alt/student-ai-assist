import 'dart:math';
import '../db/app_database.dart';

/// Retrieval sederhana ala RAGdb: TF-IDF + substring boosting di atas SQLite,
/// tanpa dependensi vector-DB eksternal. Cukup untuk korpus jurnal lokal
/// mahasiswa (puluhan-ratusan dokumen), hemat RAM di HP low-end.
class RagService {
  RagService(this._db);
  final AppDatabase _db;

  Future<List<_ScoredChunk>> query(String question, {int topK = 3}) async {
    final database = await _db.db;
    final rows = await database.query('journal_sources');

    final terms = _tokenize(question);
    final scored = <_ScoredChunk>[];

    for (final row in rows) {
      final text = (row['ocr_text'] as String?) ?? '';
      if (text.isEmpty) continue;
      final score = _score(terms, text);
      if (score > 0) {
        scored.add(_ScoredChunk(
          sourceId: row['id'] as int,
          title: row['title'] as String? ?? 'Tanpa judul',
          snippet: _bestSnippet(text, terms),
          score: score,
        ));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }

  List<String> _tokenize(String s) =>
      s.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((t) => t.length > 2).toList();

  double _score(List<String> terms, String text) {
    final lower = text.toLowerCase();
    var score = 0.0;
    for (final t in terms) {
      final count = RegExp(RegExp.escape(t)).allMatches(lower).length;
      score += count * (1 + log(1 + t.length));
    }
    return score;
  }

  String _bestSnippet(String text, List<String> terms) {
    if (terms.isEmpty) return text.substring(0, min(200, text.length));
    final lower = text.toLowerCase();
    final idx = lower.indexOf(terms.first);
    if (idx < 0) return text.substring(0, min(200, text.length));
    final start = max(0, idx - 80);
    final end = min(text.length, idx + 120);
    return text.substring(start, end);
  }
}

class _ScoredChunk {
  _ScoredChunk({
    required this.sourceId,
    required this.title,
    required this.snippet,
    required this.score,
  });
  final int sourceId;
  final String title;
  final String snippet;
  final double score;
}
