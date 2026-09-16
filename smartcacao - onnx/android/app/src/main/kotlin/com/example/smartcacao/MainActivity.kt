package com.example.smartcacao

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.smartcacao/model"
    private var modelInference: CacaoModelInference? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Lazy initialization - create the inference wrapper
        try {
            modelInference = CacaoModelInference(this)
            android.util.Log.i("SmartCacao", "Inference wrapper created")
        } catch (e: Exception) {
            android.util.Log.e("SmartCacao", "Failed to create inference wrapper: ${e.message}")
        }
        
        // Set up platform channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadModel" -> {
                        try {
                            android.util.Log.i("SmartCacao", "loadModel called from Flutter")
                            val model = modelInference ?: CacaoModelInference(this)
                            val success = model.initializeModel()
                            if (success) {
                                modelInference = model
                                result.success(mapOf("success" to true))
                            } else {
                                result.success(mapOf("success" to false, "error" to "Model initialization failed"))
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("SmartCacao", "Error in loadModel: ${e.message}")
                            result.success(mapOf("success" to false, "error" to e.message))
                        }
                    }
                    "runInference" -> {
                        val imagePath = call.argument<String>("imagePath") ?: ""
                        val model = modelInference
                        if (model != null) {
                            try {
                                val detections = model.runInference(imagePath)
                                result.success(detections)
                            } catch (e: Exception) {
                                android.util.Log.e("SmartCacao", "Inference error: ${e.message}")
                                result.success(mapOf("error" to e.message))
                            }
                        } else {
                            result.error("MODEL_ERROR", "Model not initialized", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    override fun onDestroy() {
        modelInference?.release()
        super.onDestroy()
    }
}

