# MediaPipe (dipakai flutter_gemma untuk load model .task)
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Protocol Buffers (dependency MediaPipe)
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# RAG functionality (flutter_gemma)
-keep class com.google.ai.edge.localagents.** { *; }
-dontwarn com.google.ai.edge.localagents.**

# ML Kit Text Recognition (OCR) - google_mlkit_text_recognition mereferensikan
# semua varian script (Chinese/Japanese/Korean/Devanagari) secara reflektif
# walau kita hanya pakai Latin, jadi semua harus di-keep biar R8 tidak strip.
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

