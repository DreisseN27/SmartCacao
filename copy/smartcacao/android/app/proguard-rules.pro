# ONNX Runtime - preserve native methods and classes
-keep class ai.onnxruntime.** { *; }
-keepclasseswithmembernames class ai.onnxruntime.** {
    native <methods>;
}

# Kotlin - preserve kotlin runtime
-keep class kotlin.** { *; }
-keep class kotlin.jvm.** { *; }

# SmartCacao native code
-keep class com.example.smartcacao.CacaoModelInference { *; }
-keep class com.example.smartcacao.MainActivity { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }

# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Optimization
-optimizationpasses 5
-dontusemixedcaseclassnames
