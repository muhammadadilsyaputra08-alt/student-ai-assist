import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Lapisan data lokal (SQLite). Menyimpan catatan markdown, metadata jurnal
/// hasil scan/OCR, dan histori draft. Diakses dari isolate utama; query berat
/// (search full-text) didorong ke RAGdb, bukan LIKE query di sini.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'student_ai_assist.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body_md TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE journal_sources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            author TEXT,
            year INTEGER,
            source_path TEXT,
            ocr_text TEXT,
            created_at INTEGER NOT NULL
          );
        ''');
      },
    );
  }

  Future<int> insertNote({required String title, required String bodyMd}) async {
    final database = await db;
    return database.insert('notes', {
      'title': title,
      'body_md': bodyMd,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, Object?>>> listNotes() async {
    final database = await db;
    return database.query('notes', orderBy: 'updated_at DESC');
  }

  Future<int> insertJournalSource({
    String? title,
    String? author,
    int? year,
    String? sourcePath,
    String? ocrText,
  }) async {
    final database = await db;
    return database.insert('journal_sources', {
      'title': title,
      'author': author,
      'year': year,
      'source_path': sourcePath,
      'ocr_text': ocrText,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
