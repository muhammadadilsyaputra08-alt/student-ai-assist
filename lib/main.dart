import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wajib dipanggil sebelum flutter_gemma dipakai di manapun (TaskLlmService),
  // kalau tidak akan throw 'FlutterGemma not initialized!' saat runtime.
  await FlutterGemma.initialize();
  runApp(const ProviderScope(child: StudentAiAssistApp()));
}

class StudentAiAssistApp extends StatelessWidget {
  const StudentAiAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student AI Assist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
