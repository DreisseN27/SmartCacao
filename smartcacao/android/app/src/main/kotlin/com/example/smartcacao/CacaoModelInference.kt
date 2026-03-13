package com.example.smartcacao

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import java.nio.FloatBuffer

class CacaoModelInference(private val context: Context) {
    private val env = OrtEnvironment.getEnvironment()
    private var session: OrtSession? = null
    private val inputName = "images"
    private val outputName = "output0"
    
    fun initializeModel(): Boolean {
        return try {
            if (session != null) {
                android.util.Log.i("SmartCacao", "Model already initialized")
                return true
            }
            
            android.util.Log.d("SmartCacao", "=== MODEL LOADING START ===")
            android.util.Log.d("SmartCacao", "Context: ${context.javaClass.simpleName}")
            android.util.Log.d("SmartCacao", "Package name: ${context.packageName}")
            
            // Step 1: Check if assets folder exists
            android.util.Log.d("SmartCacao", "Step 1: Checking assets...")
            val assetsList = context.assets.list("") ?: arrayOf()
            android.util.Log.d("SmartCacao", "Assets root contains: ${assetsList.toList().joinToString(", ")}")
            
            // Step 2: Check if models folder exists (Flutter puts assets in flutter_assets/)
            android.util.Log.d("SmartCacao", "Step 2: Checking models folder...")
            val modelsList = context.assets.list("flutter_assets/assets/models") ?: arrayOf()
            android.util.Log.d("SmartCacao", "Models folder contains: ${modelsList.toList().joinToString(", ")}")
            
            if (modelsList.isEmpty()) {
                android.util.Log.e("SmartCacao", "ERROR: models/ folder is EMPTY!")
                return false
            }
            
            val hasModel = modelsList.contains("best.onnx")
            if (!hasModel) {
                android.util.Log.e("SmartCacao", "ERROR: best.onnx NOT FOUND in models folder! Found: ${modelsList.toList().joinToString(", ")}")
                return false
            }
            
            // Step 3: Load model file
            android.util.Log.d("SmartCacao", "Step 3: Loading best.onnx from assets...")
            val modelBytes = context.assets.open("flutter_assets/assets/models/best.onnx").readBytes()
            android.util.Log.d("SmartCacao", "✓ Model file loaded successfully, size: ${modelBytes.size} bytes (${String.format("%.2f", modelBytes.size / 1024.0 / 1024.0)} MB)")
            
            // Step 4: Initialize ONNX Runtime
            android.util.Log.d("SmartCacao", "Step 4: Initializing ONNX Runtime environment...")
            android.util.Log.d("SmartCacao", "OrtEnvironment: ${env.javaClass.simpleName}")
            
            // Step 5: Create session
            android.util.Log.d("SmartCacao", "Step 5: Creating ONNX Runtime session...")
            session = env.createSession(modelBytes, OrtSession.SessionOptions())
            android.util.Log.i("SmartCacao", "✓✓✓ MODEL LOADED AND INITIALIZED SUCCESSFULLY ✓✓✓")
            android.util.Log.i("SmartCacao", "=== MODEL LOADING COMPLETE ===")
            true
        } catch (e: Exception) {
            android.util.Log.e("SmartCacao", "xxx MODEL LOADING FAILED xxx")
            android.util.Log.e("SmartCacao", "Exception type: ${e.javaClass.simpleName}")
            android.util.Log.e("SmartCacao", "Error message: ${e.message}")
            android.util.Log.e("SmartCacao", "Stack trace:")
            e.printStackTrace()
            
            // Log specific error causes
            if (e is java.io.FileNotFoundException) {
                android.util.Log.e("SmartCacao", "CAUSE: File not found - model file missing from APK")
            } else if (e is java.io.IOException) {
                android.util.Log.e("SmartCacao", "CAUSE: IO Error - cannot read file (permissions? corrupted?)")
            } else if (e.message?.contains("ONNX") == true) {
                android.util.Log.e("SmartCacao", "CAUSE: ONNX Runtime error - model format issue or missing library")
            }
            
            android.util.Log.e("SmartCacao", "=== MODEL LOADING FAILED ===")
            false
        }
    }
    
    fun runInference(imagePath: String): Map<String, Any> {
        val session = session ?: return mutableMapOf<String, Any>("error" to "Model not loaded")
        
        try {
            android.util.Log.d("SmartCacao", "Starting inference with image: $imagePath")
            
            // Load and preprocess image
            val bitmap = BitmapFactory.decodeFile(imagePath)
            android.util.Log.d("SmartCacao", "Image loaded: ${bitmap?.width}x${bitmap?.height}")
            
            val inputTensor = preprocessImage(bitmap)
            android.util.Log.d("SmartCacao", "Image preprocessed, running inference...")
            
            // Run inference
            val output = session.run(mapOf(inputName to inputTensor))
            android.util.Log.d("SmartCacao", "Inference complete")
            
            // Get output tensor - properly unwrap
            val outputValue = output[outputName]
            android.util.Log.d("SmartCacao", "Output value type: ${outputValue?.javaClass?.simpleName}")
            
            // Handle Optional wrapper from newer ONNX Runtime versions
            val outputTensor = if (outputValue is java.util.Optional<*>) {
                outputValue.get() as OnnxTensor
            } else {
                outputValue as OnnxTensor
            }
            
            android.util.Log.d("SmartCacao", "Output tensor acquired, parsing detections...")
            
            // Parse detections
            val detections = parseDetections(outputTensor)
            android.util.Log.i("SmartCacao", "✓ Inference successful: ${detections.size} detections")
            
            val result: MutableMap<String, Any> = mutableMapOf()
            result["success"] = true
            result["detections"] = detections
            return result
        } catch (e: Exception) {
            android.util.Log.e("SmartCacao", "Inference error: ${e.javaClass.simpleName}: ${e.message}")
            e.printStackTrace()
            
            val result: MutableMap<String, Any> = mutableMapOf()
            result["success"] = false
            result["error"] = e.message ?: "Unknown error"
            return result
        }
    }
    
    private fun preprocessImage(bitmap: Bitmap): OnnxTensor {
        val resized = Bitmap.createScaledBitmap(bitmap, 640, 640, true)
        
        // Convert to float array normalized to [0, 1]
        val data = FloatArray(1 * 3 * 640 * 640)
        
        for (y in 0 until 640) {
            for (x in 0 until 640) {
                val pixel = resized.getPixel(x, y)
                val r = (pixel shr 16 and 0xFF) / 255.0f
                val g = (pixel shr 8 and 0xFF) / 255.0f
                val b = (pixel and 0xFF) / 255.0f
                
                // CHW format (channels first)
                data[y * 640 + x] = r // R channel
                data[640 * 640 + y * 640 + x] = g // G channel
                data[2 * 640 * 640 + y * 640 + x] = b // B channel
            }
        }
        
        // Create FloatBuffer and tensor with shape
        val buffer = FloatBuffer.wrap(data)
        return OnnxTensor.createTensor(env, buffer, longArrayOf(1, 3, 640, 640))
    }
    
    private fun parseDetections(outputTensor: OnnxTensor): List<Map<String, Any>> {
        val detections = mutableListOf<Map<String, Any>>()
        val classNames = listOf("under_fermented", "properly_fermented", "over_fermented")
        
        try {
            val output = outputTensor.floatBuffer.array()
            android.util.Log.d("SmartCacao", "PARSE: Output array size: ${output.size}")
            
            // YOLOv8 exports as [1, 8400, 8] where:
            // 8 elements = 4(bbox x,y,w,h) + 1(objectness) + 3(class probs)
            val detectionsList = mutableListOf<Pair<Float, Map<String, Any>>>()
            
            // Assuming format: [1, 8400, 8] = 67200 total values
            val elementsPerDetection = 8
            val numDetections = 8400
            
            for (i in 0 until numDetections) {
                val baseIdx = i * elementsPerDetection
                
                if (baseIdx + 7 >= output.size) {
                    break
                }
                
                val x = output[baseIdx]
                val y = output[baseIdx + 1]
                val w = output[baseIdx + 2]
                val h = output[baseIdx + 3]
                val objectness = output[baseIdx + 4]
                
                // Skip low confidence early
                if (objectness < 0.45f) continue
                
                // Get class probabilities and find best
                val classProb0 = output[baseIdx + 5]
                val classProb1 = output[baseIdx + 6]
                val classProb2 = output[baseIdx + 7]
                
                val bestClassIdx = when {
                    classProb0 >= classProb1 && classProb0 >= classProb2 -> 0
                    classProb1 >= classProb0 && classProb1 >= classProb2 -> 1
                    else -> 2
                }
                
                val bestClassProb = when (bestClassIdx) {
                    0 -> classProb0
                    1 -> classProb1
                    else -> classProb2
                }
                
                val finalConfidence = objectness * bestClassProb
                
                if (finalConfidence > 0.4f) {
                    detectionsList.add(finalConfidence to mapOf<String, Any>(
                        "label" to classNames[bestClassIdx],
                        "confidence" to finalConfidence,
                        "x" to x,
                        "y" to y,
                        "width" to w,
                        "height" to h
                    ))
                }
            }
            
            // Apply NMS to remove overlapping boxes
            android.util.Log.d("SmartCacao", "PARSE: Before NMS: ${detectionsList.size} detections")
            val finalDetections = applyNMS(detectionsList, 0.4f) // IOU threshold
            
            android.util.Log.d("SmartCacao", "PARSE: After NMS: ${finalDetections.size} detections")
            val counts = mutableMapOf<String, Int>()
            for (det in finalDetections) {
                val label = det["label"] as? String ?: "unknown"
                counts[label] = (counts[label] ?: 0) + 1
            }
            android.util.Log.d("SmartCacao", "PARSE: Detection breakdown: $counts")
            
            return finalDetections
        } catch (e: Exception) {
            android.util.Log.e("SmartCacao", "PARSE: Error parsing detections: ${e.message}")
            e.printStackTrace()
            return detections
        }
    }
    
    private fun applyNMS(
        detections: List<Pair<Float, Map<String, Any>>>,
        iouThreshold: Float
    ): List<Map<String, Any>> {
        if (detections.isEmpty()) return emptyList()
        
        // Sort by confidence descending
        val sorted = detections.sortedByDescending { (conf, _) -> conf }
        val kept = mutableListOf<Map<String, Any>>()
        val used = mutableSetOf<Int>()
        
        for (i in sorted.indices) {
            if (i in used) continue
            
            val (_, det1) = sorted[i]
            kept.add(det1)
            
            // Compare with remaining detections
            for (j in (i + 1) until sorted.size) {
                if (j in used) continue
                
                val (_, det2) = sorted[j]
                
                // Calculate IOU
                val iou = calculateIOU(det1, det2)
                if (iou > iouThreshold) {
                    used.add(j)
                }
            }
        }
        
        return kept
    }
    
    private fun calculateIOU(box1: Map<String, Any>, box2: Map<String, Any>): Float {
        val x1 = (box1["x"] as Number).toFloat()
        val y1 = (box1["y"] as Number).toFloat()
        val w1 = (box1["width"] as Number).toFloat()
        val h1 = (box1["height"] as Number).toFloat()
        
        val x2 = (box2["x"] as Number).toFloat()
        val y2 = (box2["y"] as Number).toFloat()
        val w2 = (box2["width"] as Number).toFloat()
        val h2 = (box2["height"] as Number).toFloat()
        
        val left1 = x1 - w1 / 2
        val right1 = x1 + w1 / 2
        val top1 = y1 - h1 / 2
        val bottom1 = y1 + h1 / 2
        
        val left2 = x2 - w2 / 2
        val right2 = x2 + w2 / 2
        val top2 = y2 - h2 / 2
        val bottom2 = y2 + h2 / 2
        
        val intersectLeft = maxOf(left1, left2)
        val intersectRight = minOf(right1, right2)
        val intersectTop = maxOf(top1, top2)
        val intersectBottom = minOf(bottom1, bottom2)
        
        val intersectArea = if (intersectRight > intersectLeft && intersectBottom > intersectTop) {
            (intersectRight - intersectLeft) * (intersectBottom - intersectTop)
        } else {
            0f
        }
        
        val area1 = w1 * h1
        val area2 = w2 * h2
        val unionArea = area1 + area2 - intersectArea
        
        return if (unionArea > 0) intersectArea / unionArea else 0f
    }
    
    fun release() {
        session?.close()
    }
}
