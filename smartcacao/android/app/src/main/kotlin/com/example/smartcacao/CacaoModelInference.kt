package com.example.smartcacao

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import ai.onnxruntime.*
import java.nio.FloatBuffer
import java.nio.ByteBuffer
import java.nio.ByteOrder

class CacaoModelInference(private val context: Context) {
    private var session: OrtSession? = null
    private val INPUT_SIZE = 320
    private val INPUT_CHANNELS = 3
    
    fun initializeModel(): Boolean {
        return try {
            if (session != null) {
                android.util.Log.i("SmartCacao", "Model already initialized")
                return true
            }
            
            android.util.Log.d("SmartCacao", "=== MODEL LOADING START (ONNX Runtime) ===")
            android.util.Log.d("SmartCacao", "Context: ${context.javaClass.simpleName}")
            android.util.Log.d("SmartCacao", "Package name: ${context.packageName}")
            
            // Step 1: Check if assets folder exists
            android.util.Log.d("SmartCacao", "Step 1: Checking assets...")
            val assetsList = context.assets.list("") ?: arrayOf()
            android.util.Log.d("SmartCacao", "Assets root contains: ${assetsList.toList().joinToString(", ")}")
            
            // Step 2: Check if models folder exists
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
            
            // Step 3: Create ONNX Runtime environment and session
            android.util.Log.d("SmartCacao", "Step 3: Creating ONNX Runtime environment...")
            val env = OrtEnvironment.getEnvironment()
            
            // Step 4: Load ONNX model from assets
            android.util.Log.d("SmartCacao", "Step 4: Loading best.onnx from assets...")
            val modelBytes = context.assets.open("flutter_assets/assets/models/best.onnx").readBytes()
            android.util.Log.d("SmartCacao", "✓ Model file loaded successfully, size: ${modelBytes.size} bytes (${String.format("%.2f", modelBytes.size / 1024.0 / 1024.0)} MB)")
            
            // Step 5: Create session options and session
            android.util.Log.d("SmartCacao", "Step 5: Creating ONNX Runtime session...")
            val sessionOptions = OrtSession.SessionOptions()
            sessionOptions.setIntraOpNumThreads(4)
            session = env.createSession(modelBytes, sessionOptions)
            
            android.util.Log.i("SmartCacao", "✓✓✓ MODEL LOADED AND INITIALIZED SUCCESSFULLY ✓✓✓")
            android.util.Log.i("SmartCacao", "=== MODEL LOADING COMPLETE ===")
            true
        } catch (e: Exception) {
            android.util.Log.e("SmartCacao", "xxx MODEL LOADING FAILED xxx")
            android.util.Log.e("SmartCacao", "Exception type: ${e.javaClass.simpleName}")
            android.util.Log.e("SmartCacao", "Error message: ${e.message}")
            android.util.Log.e("SmartCacao", "Stack trace:")
            e.printStackTrace()
            
            if (e is java.io.FileNotFoundException) {
                android.util.Log.e("SmartCacao", "CAUSE: File not found - model file missing from APK")
            } else if (e is java.io.IOException) {
                android.util.Log.e("SmartCacao", "CAUSE: IO Error - cannot read file")
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
                ?: return mutableMapOf<String, Any>("error" to "Failed to load image")
            
            android.util.Log.d("SmartCacao", "Image loaded: ${bitmap.width}x${bitmap.height}")
            
            // Prepare input
            val inputArray = preprocessImage(bitmap)
            val env = OrtEnvironment.getEnvironment()
            val shape = longArrayOf(1, 3, INPUT_SIZE.toLong(), INPUT_SIZE.toLong())
            
            // Convert to FloatBuffer
            val buffer = ByteBuffer.allocateDirect(1 * 3 * INPUT_SIZE * INPUT_SIZE * 4).order(ByteOrder.nativeOrder()).asFloatBuffer()
            for (i in inputArray.indices) {
                for (c in inputArray[i].indices) {
                    for (y in inputArray[i][c].indices) {
                        for (x in inputArray[i][c][y].indices) {
                            buffer.put(inputArray[i][c][y][x])
                        }
                    }
                }
            }
            buffer.rewind()
            
            android.util.Log.d("SmartCacao", "Running inference...")
            
            // Create ONNX tensor from FloatBuffer
            val inputTensor = OnnxTensor.createTensor(env, buffer, shape)
            
            val inputs = mapOf("images" to inputTensor)
            val results = session.run(inputs)
            
            android.util.Log.d("SmartCacao", "Inference complete, results type: ${results.javaClass.simpleName}")
            
            // Get output and debug the shape - results might be OrtOutputs which is list-like
            val outputTensor = try {
                results[0] as OnnxTensor
            } catch (e: Exception) {
                android.util.Log.e("SmartCacao", "Failed to get result[0]: ${e.message}")
                throw e
            }
            android.util.Log.d("SmartCacao", "Output tensor type: ${outputTensor.javaClass.simpleName}")
            
            // Try to log shape info
            try {
                val shapeInfo = outputTensor.info?.shape?.joinToString(",") ?: "unknown"
                android.util.Log.d("SmartCacao", "Output tensor shape: [$shapeInfo]")
            } catch (e: Exception) {
                android.util.Log.d("SmartCacao", "Could not get shape info: ${e.message}")
            }
            
            val output = when (val value = outputTensor.value) {
                is FloatArray -> {
                    android.util.Log.d("SmartCacao", "Output is FloatArray, size: ${value.size}")
                    // Print first 50 values for debugging
                    if (value.size <= 100) {
                        val preview = value.take(minOf(50, value.size)).joinToString(",") { String.format("%.4f", it) }
                        android.util.Log.d("SmartCacao", "First values: $preview")
                    } else {
                        val preview = value.take(50).joinToString(",") { String.format("%.4f", it) }
                        android.util.Log.d("SmartCacao", "First 50 values: $preview")
                    }
                    value
                }
                is Array<*> -> {
                    android.util.Log.d("SmartCacao", "Output is Array, dimensions: ${(value as Array<*>).size}")
                    // If it's a nested array, flatten it
                    val flat = mutableListOf<Float>()
                    fun flatten(arr: Any) {
                        when (arr) {
                            is Array<*> -> {
                                android.util.Log.d("SmartCacao", "  Array size: ${arr.size}")
                                arr.forEach { flatten(it!!) }
                            }
                            is FloatArray -> {
                                android.util.Log.d("SmartCacao", "  FloatArray size: ${arr.size}")
                                flat.addAll(arr.toList())
                            }
                        }
                    }
                    flatten(value)
                    android.util.Log.d("SmartCacao", "Flattened to ${flat.size} floats")
                    flat.toFloatArray()
                }
                else -> {
                    android.util.Log.e("SmartCacao", "Unknown output type: ${value?.javaClass?.simpleName}")
                    throw RuntimeException("Unknown output type: ${value?.javaClass?.simpleName}")
                }
            }
            
            // Parse detections
            android.util.Log.d("SmartCacao", "OUTPUT CHECK: First 10 values: ${output.take(10).joinToString(",") { String.format("%.2f", it) }}")
            android.util.Log.d("SmartCacao", "OUTPUT CHECK: Values at 857: ${String.format("%.2f", output[857])}, 2957: ${String.format("%.2f", output[2957])}, 4557: ${String.format("%.2f", output[4557])}, 6157: ${String.format("%.2f", output[6157])}")
            
            val detections = parseDetections(output)
            android.util.Log.i("SmartCacao", "✓ Inference successful: ${detections.size} detections")
            
            inputTensor.close()
            
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
    
    private fun preprocessImage(bitmap: Bitmap): Array<Array<Array<FloatArray>>> {
        val resized = Bitmap.createScaledBitmap(bitmap, INPUT_SIZE, INPUT_SIZE, true)
        
        // Create float array for ONNX input [1][3][320][320]
        val input = Array(1) {
            Array(3) {
                Array(INPUT_SIZE) {
                    FloatArray(INPUT_SIZE)
                }
            }
        }
        
        // Convert bitmap to float array (normalize RGB values 0-1 or 0-255 depending on model)
        for (y in 0 until INPUT_SIZE) {
            for (x in 0 until INPUT_SIZE) {
                val pixel = resized.getPixel(x, y)
                val r = ((pixel shr 16) and 0xFF).toFloat()
                val g = ((pixel shr 8) and 0xFF).toFloat()
                val b = (pixel and 0xFF).toFloat()
                
                // Normalize to 0-1 range
                input[0][0][y][x] = r / 255.0f
                input[0][1][y][x] = g / 255.0f
                input[0][2][y][x] = b / 255.0f
            }
        }
        
        return input
    }
    
    private fun parseDetections(outputArray: FloatArray): List<Map<String, Any>> {
        val detections = mutableListOf<Map<String, Any>>()
        val classNames = listOf("under_fermented", "properly_fermented", "over_fermented")
        
        try {
            android.util.Log.d("SmartCacao", "PARSE: Output array size: ${outputArray.size} floats")
            
            val totalElements = outputArray.size
            
            // Determine the format: 7 heads (2 classes) or 8 heads (3 classes)
            val numHeads = if (totalElements == 14700) 7 else if (totalElements == 16800) 8 else -1
            
            if (numHeads == -1) {
                android.util.Log.w("SmartCacao", "PARSE: Unexpected output size! Expected 14700 (7*2100) or 16800 (8*2100), got $totalElements")
            }
            
            android.util.Log.d("SmartCacao", "PARSE: Output format has $numHeads heads (${numHeads}*2100 = ${2100*numHeads} floats)")
            
            val numPredictions = 2100
            val stride = 2100  // Transposed format: [1, numHeads, 2100]
            
            // DEBUG: Log first few values to understand the data layout
            android.util.Log.d("SmartCacao", "DEBUG: First 20 array values: ${outputArray.take(20).map { String.format("%.4f", it) }.joinToString(", ")}")
            android.util.Log.d("SmartCacao", "DEBUG: Checking prediction 600:")
            android.util.Log.d("SmartCacao", "  Method 1 (stride=2100): [0*2100+600]=${String.format("%.4f", outputArray[0 * stride + 600])}, [1*2100+600]=${String.format("%.4f", outputArray[1 * stride + 600])}")
            android.util.Log.d("SmartCacao", "  Method 2 (stride=7):   [600*7+0]=${String.format("%.4f", outputArray[600 * 7 + 0])}, [600*7+1]=${String.format("%.4f", outputArray[600 * 7 + 1])}")
            
            val detectionsList = mutableListOf<Pair<Float, Map<String, Any>>>()
            var highConfidenceCount = 0
            var mediumConfidenceCount = 0
            var lowConfidenceCount = 0
            var zeroCount = 0
            
            for (i in 0 until numPredictions) {
                try {
                    // For transposed [1, numHeads, 2100] format:
                    // Heads 0-3: x, y, w, h
                    // Head 4: objectness
                    // Head 5: class 0 probability (under_fermented)
                    // Head 6: class 1 probability (properly_fermented)
                    // Head 7 (if exists): class 2 probability (over_fermented)
                    
                    val xNorm = outputArray[0 * stride + i]          // x at index [0][i]
                    val yNorm = outputArray[1 * stride + i]          // y at index [1][i]
                    val wNorm = outputArray[2 * stride + i]          // w at index [2][i]
                    val hNorm = outputArray[3 * stride + i]          // h at index [3][i]
                    val objectness = outputArray[4 * stride + i]     // obj at index [4][i]
                    val classProb0 = outputArray[5 * stride + i]     // class0 at index [5][i] (under_fermented)
                    val classProb1 = outputArray[6 * stride + i]     // class1 at index [6][i] (properly_fermented)
                    
                    // Try to read class 2 if it exists (8-head format)
                    val classProb2 = if (numHeads >= 8 && outputArray.size > (7 * stride + i)) {
                        outputArray[7 * stride + i]  // class2 at index [7][i] (over_fermented)
                    } else {
                        maxOf(0f, 1.0f - classProb0 - classProb1)  // Implicit: calculated from other 2
                    }
                    
                    // Check for all zeros
                    if (xNorm == 0f && yNorm == 0f && wNorm == 0f && hNorm == 0f && objectness == 0f && classProb0 == 0f && classProb1 == 0f && classProb2 == 0f) {
                        zeroCount++
                        continue
                    }
                    
                    // Skip very low objectness first
                    if (objectness < 0.4f) {
                        lowConfidenceCount++
                        continue
                    }
                    
                    // Coordinates are already in pixel space (0-320), no need to scale
                    val xPixel = xNorm
                    val yPixel = yNorm
                    val wPixel = wNorm
                    val hPixel = hNorm
                    
                    // DEBUG: Log coordinates
                    if (objectness >= 0.1f) {
                        android.util.Log.d("SmartCacao", "PIXEL COORDS [i=$i]: x=${String.format("%.2f", xPixel)} y=${String.format("%.2f", yPixel)} w=${String.format("%.2f", wPixel)} h=${String.format("%.2f", hPixel)}")
                    }
                    
                    // Find best class (classProb2 already calculated above)
                    val classProbs = floatArrayOf(classProb0, classProb1, classProb2)
                    val bestClassIdx = classProbs.indices.maxByOrNull { classProbs[it] } ?: 0
                    val bestClassProb = classProbs[bestClassIdx]
                    
                    // Use class probability as confidence (matches Google Colab output)
                    val finalConfidence = bestClassProb
                    
                    // DEBUG: Log ALL detections above objectness threshold
                    if (objectness >= 0.1f) {
                        android.util.Log.d("SmartCacao", "DEBUG [i=$i] obj=${String.format("%.3f", objectness)} | probs=[${String.format("%.3f", classProb0)},${String.format("%.3f", classProb1)},${String.format("%.3f", classProb2)}] | best_idx=$bestClassIdx best_prob=${String.format("%.3f", bestClassProb)} final=${String.format("%.3f", finalConfidence)} | class=${classNames.getOrNull(bestClassIdx) ?: "unknown"}")
                    }
                    
                    if (finalConfidence >= 0.6f) {
                        highConfidenceCount++
                    } else if (finalConfidence >= 0.4f) {
                        mediumConfidenceCount++
                    } else {
                        lowConfidenceCount++
                    }
                    
                    // Threshold: only keep detections with sufficient confidence
                    if (finalConfidence > 0.35f) {
                        detectionsList.add(finalConfidence to mapOf<String, Any>(
                            "label" to (if (bestClassIdx < classNames.size) classNames[bestClassIdx] else "unknown"),
                            "confidence" to finalConfidence,
                            "x" to xPixel,
                            "y" to yPixel,
                            "width" to wPixel,
                            "height" to hPixel
                        ))
                    }
                } catch (e: Exception) {
                    if (i < 10) {
                        android.util.Log.e("SmartCacao", "PARSE: Error at prediction $i: ${e.message}")
                    }
                }
            }
            
            android.util.Log.d("SmartCacao", "PARSE: Zero predictions: $zeroCount, High(>0.6): $highConfidenceCount, Medium(0.4-0.6): $mediumConfidenceCount, Low(0.1-0.4): $lowConfidenceCount")
            android.util.Log.d("SmartCacao", "PARSE: Before NMS: ${detectionsList.size} detections")
            val finalDetections = applyNMS(detectionsList, 0.5f)
            
            android.util.Log.d("SmartCacao", "PARSE: After NMS: ${finalDetections.size} detections")
            return finalDetections
        } catch (e: Exception) {
            android.util.Log.e("SmartCacao", "PARSE: Fatal error: ${e.message}")
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
        session = null
    }
}
