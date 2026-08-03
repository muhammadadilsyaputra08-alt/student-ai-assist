import 'package:flutter_gemma/flutter_gemma.dart';

/// Wrapper MediaPipe LLM Inference API (via plugin flutter_gemma 0.15.x).
/// Model dalam format `.task` (bundle MediaPipe, BUKAN .gguf) - contoh:
/// gemma3-1b-it-int4.task (dari huggingface.co/litert-community).
///
/// Pakai Legacy API (FlutterGemmaPlugin.instance.createModel) karena lebih
/// simpel untuk kasus single-model-aktif seperti aplikasi ini. Modern API
/// (FlutterGemma.installModel/getActiveModel) tersedia kalau nanti butuh
/// multi-model management yang lebih rapi.
class TaskLlmService {
  TaskLlmService._internal();
  static final TaskLlmService instance = TaskLlmService._internal();

  InferenceModel? _model;
  String? _activeModelPath;

  static const int maxTokens = 512; // batas context, hemat RAM di HP low-end

  Future<InferenceModel> _ensureModelLoaded(String modelPath) async {
    if (_activeModelPath == modelPath && _model != null) return _model!;

    // model swapping: pastikan model lama dilepas dulu sebelum load baru
    await _model?.close();

    await FlutterGemmaPlugin.instance.modelManager.setModelPath(modelPath);

    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: PreferredBackend.cpu, // portabel di semua device
      maxTokens: maxTokens,
    );
    _activeModelPath = modelPath;
    return _model!;
  }

  /// Satu pertanyaan -> satu jawaban (bukan multi-turn chat history), cocok
  /// untuk ringkas/parafrase/grammar-fix satu paragraf.
  Future<String> runPrompt({
    required String modelPath,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final model = await _ensureModelLoaded(modelPath);
    final chat = await model.createChat();
    await chat.addQueryChunk(Message.text(text: '$systemPrompt\n\n$userPrompt', isUser: true));
    final response = await chat.generateChatResponse();
    if (response is TextResponse) {
      return response.token;
    }
    // FunctionCallResponse/ThinkingResponse tidak relevan untuk kasus
    // ringkas/parafrase/grammar-fix teks biasa - fallback aman.
    return response.toString();
  }

  Future<String> summarize(String modelPath, String text) => runPrompt(
        modelPath: modelPath,
        systemPrompt:
            'Kamu asisten akademik. Ringkas teks berikut dalam bahasa Indonesia, 3-5 kalimat, padat.',
        userPrompt: text,
      );

  Future<String> paraphrase(String modelPath, String text) => runPrompt(
        modelPath: modelPath,
        systemPrompt: 'Parafrase teks berikut dengan gaya akademik formal bahasa Indonesia.',
        userPrompt: text,
      );

  Future<String> fixGrammar(String modelPath, String text) => runPrompt(
        modelPath: modelPath,
        systemPrompt: 'Perbaiki tata bahasa dan ejaan teks berikut tanpa mengubah makna.',
        userPrompt: text,
      );

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    _activeModelPath = null;
  }
}
