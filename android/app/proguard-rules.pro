# Flutter Play Store Split Application
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ML Kit - ignorar modelos de idiomas opcionales no incluidos
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Mantener clases de ML Kit necesarias
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_** { *; }