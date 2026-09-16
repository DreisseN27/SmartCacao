package com.example.smartcacao

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder

class CacaoModelInference(private val context: Context) {
    private var interpreter: Interpreter? = null
    private val INPUT_SIZE = 320
    private val INPUT_CHANNELS = 3
    private val MIN_OBJECTNESS = 0.010f
    private val MIN_CLASS_CONFIDENCE = 0.008f
    
    // Store last image dimensions for coordinate transform
    var lastImageWidth: Int = 0
    var lastImageHeight: Int = 0
    
    fun initializeModel(): Boolean {
        return try {
            if (interpreter != null) {
                android.util.Log.i("SmartCacao", "Model already initialized")
                return true
            }
            
            android.util.Log.d("SmartCacao", "=== MODEL LOADING START (TFLite) ===")
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
            
            val hasModel = modelsList.contains("best.tflite")
            if (!hasModel) {
                android.util.Log.e("SmartCacao", "ERROR: best.tflite NOT FOUND in models folder! Found: ${modelsList.toList().joinToString(", ")}")
                return false
            }
            
            // Step 3: Load the TFLite model from Flutter's bundled assets.
            android.util.Log.d("SmartCacao", "Step 3: Loading best.tflite from assets...")
            val modelBytes = context.assets.open("flutter_assets/assets/models/best.tflite").readBytes()
            android.util.Log.d("SmartCacao", "✓ Model file loaded successfully, size: ${modelBytes.size} bytes (${String.format("%.2f", modelBytes.size / 1024.0 / 1024.0)} MB)")
            
            // Step 4: Create the interpreter and use four CPU threads.
            android.util.Log.d("SmartCacao", "Step 4: Creating TFLite interpreter...")
            val options = Interpreter.Options().apply { setNumThreads(4) }
            val modelBuffer = ByteBuffer.allocateDirect(modelBytes.size)
                .order(ByteOrder.nativeOrder())
                .put(modelBytes)
            modelBuffer.rewind()
            interpreter = Interpreter(modelBuffer, options)
            android.util.Log.i("SmartCacao", "TFLite input shape: ${interpreter!!.getInputTensor(0).shape().contentToString()}")
            android.util.Log.i("SmartCacao", "TFLite output shape: ${interpreter!!.getOutputTensor(0).shape().contentToString()}")
            
            android.util.Log.i("SmartCacao", "✓✓✓ TFLITE MODEL LOADED SUCCESSFULLY ✓✓✓")
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
        val interpreter = interpreter ?: return mutableMapOf<String, Any>("error" to "Model not loaded")
        
        try {
            android.util.Log.d("SmartCacao", "Starting inference with image: $imagePath")
            
            // Load and preprocess image
            val bitmap = BitmapFactory.decodeFile(imagePath)
                ?: return mutableMapOf<String, Any>("error" to "Failed to load image")
            
            // IMPORTANT: Capture actual image dimensions for Flutter coordinate transform
            val actualImageWidth = bitmap.width
            val actualImageHeight = bitmap.height
            
            // Store for later use
            lastImageWidth = actualImageWidth
            lastImageHeight = actualImageHeight
            
            android.util.Log.d("SmartCacao", "Image loaded: ${actualImageWidth}x${actualImageHeight}")
            android.util.Log.d("SmartCacao", "CRITICAL: Passing actual dimensions to Flutter for coordinate transform")
            
            // Prepare input
            val inputArray = preprocessImage(bitmap)
            // This exported model declares NCHW input: batch, channels, height, width.
            val inputBuffer = ByteBuffer.allocateDirect(1 * INPUT_SIZE * INPUT_SIZE * 3 * 4)
                .order(ByteOrder.nativeOrder())
            for (c in 0..2) {
                for (y in 0 until INPUT_SIZE) {
                    for (x in 0 until INPUT_SIZE) {
                        inputBuffer.putFloat(inputArray[0][c][y][x])
                    }
                }
            }
            inputBuffer.rewind()

            val detectionsOutput = Array(1) { Array(39) { FloatArray(2100) } }
            val prototypesOutput = Array(1) { Array(32) { Array(80) { FloatArray(80) } } }
            val outputs = hashMapOf<Int, Any>(0 to detectionsOutput, 1 to prototypesOutput)
            interpreter!!.runForMultipleInputsOutputs(arrayOf(inputBuffer), outputs)
            android.util.Log.d("SmartCacao", "TFLite outputs: [1,39,2100] and [1,32,80,80]")
            
            // Parse detections
            val detections = parseSegmentation(detectionsOutput[0], prototypesOutput[0])
            android.util.Log.i("SmartCacao", "✓ Inference successful: ${detections.size} detections")
            
            val result: MutableMap<String, Any> = mutableMapOf()
            result["success"] = true
            result["detections"] = detections
            result["imageWidth"] = lastImageWidth
            result["imageHeight"] = lastImageHeight
            android.util.Log.d("SmartCacao", "Result includes: imageWidth=$lastImageWidth, imageHeight=$lastImageHeight")
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
        // CRITICAL: Match Colab training preprocessing exactly
        // Training used imgsz=320, and YOLOv8 letterboxes images to 320x320 automatically
        
        // Step 1: Scale image to fit into 320x320 while preserving aspect ratio
        // This matches YOLOv8's letterbox behavior in training
        val imgWidth = bitmap.width.toFloat()
        val imgHeight = bitmap.height.toFloat()
        val scale = minOf(INPUT_SIZE / imgWidth, INPUT_SIZE / imgHeight)
        
        val scaledWidth = (imgWidth * scale).toInt()
        val scaledHeight = (imgHeight * scale).toInt()
        
        android.util.Log.d("SmartCacao", "PREPROCESS: Scaling ${bitmap.width}x${bitmap.height} by factor $scale -> ${scaledWidth}x${scaledHeight}")
        
        // Step 2: Resize with aspect ratio preserved
        val resized = Bitmap.createScaledBitmap(bitmap, scaledWidth, scaledHeight, true)
        
        // Step 3: Create letterboxed 320x320 image with padding
        val paddingLeft = (INPUT_SIZE - scaledWidth) / 2
        val paddingTop = (INPUT_SIZE - scaledHeight) / 2
        
        android.util.Log.d("SmartCacao", "PREPROCESS: Padding left=$paddingLeft, top=$paddingTop")
        
        val input = Array(1) {
            Array(3) {
                Array(INPUT_SIZE) {
                    FloatArray(INPUT_SIZE)
                }
            }
        }
        
        // Initialize with YOLOv8 standard padding color (114/255 normalized)
        // This MUST match the padding used during training
        val yolov8PaddingColor = 114f / 255f  // Approximately 0.447f
        for (c in 0..2) {
            for (y in 0 until INPUT_SIZE) {
                for (x in 0 until INPUT_SIZE) {
                    input[0][c][y][x] = yolov8PaddingColor
                }
            }
        }
        
        // Copy resized image into center of letterboxed area
        for (y in 0 until scaledHeight) {
            for (x in 0 until scaledWidth) {
                val pixel = resized.getPixel(x, y)
                val r = ((pixel shr 16) and 0xFF).toFloat() / 255.0f
                val g = ((pixel shr 8) and 0xFF).toFloat() / 255.0f
                val b = (pixel and 0xFF).toFloat() / 255.0f
                
                val outX = paddingLeft + x
                val outY = paddingTop + y
                input[0][0][outY][outX] = r
                input[0][1][outY][outX] = g
                input[0][2][outY][outX] = b
            }
        }
        
        return input
    }
    
    private fun parseSegmentation(
        output: Array<FloatArray>,
        prototypes: Array<Array<FloatArray>>
    ): List<Map<String, Any>> {
        val detections = mutableListOf<Pair<Float, Map<String, Any>>>()
        val classNames = listOf("under_fermented", "properly_fermented", "over_fermented")
        // Reject weak detections by default; raise or lower this after testing
        // against a validation set containing non-cacao objects.
        val confidenceThreshold = 0.50f

        for (index in 0 until 2100) {
            var centerX = output[0][index]
            var centerY = output[1][index]
            var width = output[2][index]
            var height = output[3][index]
            if (maxOf(kotlin.math.abs(centerX), kotlin.math.abs(centerY), kotlin.math.abs(width), kotlin.math.abs(height)) <= 2f) {
                centerX *= INPUT_SIZE
                centerY *= INPUT_SIZE
                width *= INPUT_SIZE
                height *= INPUT_SIZE
            }
            val classScores = floatArrayOf(output[4][index], output[5][index], output[6][index])
            val classIndex = classScores.indices.maxByOrNull { classScores[it] } ?: 0
            val confidence = classScores[classIndex]
            if (confidence < confidenceThreshold || width <= 0f || height <= 0f) continue

            val maskPoints = mutableListOf<Pair<Float, Float>>()
            for (py in 0 until 80) {
                for (px in 0 until 80) {
                    val modelX = px * INPUT_SIZE / 80f
                    val modelY = py * INPUT_SIZE / 80f
                    if (modelX < centerX - width / 2 || modelX > centerX + width / 2 ||
                        modelY < centerY - height / 2 || modelY > centerY + height / 2) continue

                    var maskLogit = 0f
                    for (coefficient in 0 until 32) {
                        maskLogit += output[7 + coefficient][index] * prototypes[coefficient][py][px]
                    }
                    val maskValue = (1.0 / (1.0 + kotlin.math.exp((-maskLogit).toDouble()))).toFloat()
                    if (maskValue >= 0.5f && isMaskBoundary(prototypes, output, index, px, py)) {
                        maskPoints.add(modelX to modelY)
                    }
                }
            }

            val polygon = convexHull(maskPoints)
            detections.add(confidence to mapOf(
                "label" to classNames[classIndex],
                "confidence" to confidence,
                "x" to centerX,
                "y" to centerY,
                "width" to width,
                "height" to height,
                "polygon" to polygon.map { mapOf("x" to it.first, "y" to it.second) }
            ))
        }

        return applyNMS(detections, 0.5f)
    }

    private fun isMaskBoundary(
        prototypes: Array<Array<FloatArray>>,
        output: Array<FloatArray>,
        index: Int,
        px: Int,
        py: Int
    ): Boolean {
        val neighbors = arrayOf(px - 1 to py, px + 1 to py, px to py - 1, px to py + 1)
        return neighbors.any { (nx, ny) ->
            if (nx !in 0 until 80 || ny !in 0 until 80) return@any true
            var value = 0f
            for (coefficient in 0 until 32) {
                value += output[7 + coefficient][index] * prototypes[coefficient][ny][nx]
            }
            (1.0 / (1.0 + kotlin.math.exp((-value).toDouble()))).toFloat() < 0.5f
        }
    }

    private fun convexHull(points: List<Pair<Float, Float>>): List<Pair<Float, Float>> {
        if (points.size < 3) return points
        val sorted = points.distinct().sortedWith(compareBy<Pair<Float, Float>> { it.first }.thenBy { it.second })
        fun cross(a: Pair<Float, Float>, b: Pair<Float, Float>, c: Pair<Float, Float>): Float =
            (b.first - a.first) * (c.second - a.second) - (b.second - a.second) * (c.first - a.first)
        val lower = mutableListOf<Pair<Float, Float>>()
        for (point in sorted) {
            while (lower.size >= 2 && cross(lower[lower.size - 2], lower.last(), point) <= 0f) lower.removeAt(lower.lastIndex)
            lower.add(point)
        }
        val upper = mutableListOf<Pair<Float, Float>>()
        for (point in sorted.asReversed()) {
            while (upper.size >= 2 && cross(upper[upper.size - 2], upper.last(), point) <= 0f) upper.removeAt(upper.lastIndex)
            upper.add(point)
        }
        lower.removeAt(lower.lastIndex)
        upper.removeAt(upper.lastIndex)
        return lower + upper
    }

    private fun parseDetections(outputArray: FloatArray, outputShape: IntArray): List<Map<String, Any>> {
        val detections = mutableListOf<Map<String, Any>>()
        // Match smartcacao_dataset.yaml: {0: under, 1: fermented, 2: over}.
        // The app uses properly_fermented for the dataset's fermented class.
        val classNames = listOf("under_fermented", "properly_fermented", "over_fermented")
        
        // Log expected letterbox padding (should match Android preprocessing)
        android.util.Log.d("SmartCacao", "PARSE: Expected letterbox padding: left=0, top=70 (scaled_w=320, scaled_h=180)")
        
        try {
            android.util.Log.d("SmartCacao", "PARSE: Output array size: ${outputArray.size} floats")
            
            val totalElements = outputArray.size
            val numHeads = when {
                outputShape.size == 3 && outputShape[1] <= 16 -> outputShape[1]
                outputShape.size == 3 && outputShape[2] <= 16 -> outputShape[2]
                else -> if (totalElements == 14700) 7 else if (totalElements == 16800) 8 else -1
            }
            val predictionsAreRowMajor = outputShape.size == 3 && outputShape[2] == numHeads
            val numPredictions = if (numHeads > 0) totalElements / numHeads else 2100
            
            if (numHeads == -1) {
                android.util.Log.w("SmartCacao", "PARSE: Unexpected output size! Expected 14700 (7*2100) or 16800 (8*2100), got $totalElements")
            }
            
            android.util.Log.d("SmartCacao", "PARSE: Output shape=${outputShape.contentToString()}, heads=$numHeads, predictions=$numPredictions, rowMajor=$predictionsAreRowMajor")

            fun value(head: Int, prediction: Int): Float {
                return if (predictionsAreRowMajor) {
                    outputArray[prediction * numHeads + head]
                } else {
                    outputArray[head * numPredictions + prediction]
                }
            }
            
            // DEBUG: Log first few values to understand the data layout
            android.util.Log.d("SmartCacao", "DEBUG: First 20 array values: ${outputArray.take(20).map { String.format("%.4f", it) }.joinToString(", ")}")
            android.util.Log.d("SmartCacao", "DEBUG: Checking prediction 600:")
            android.util.Log.d("SmartCacao", "  If [1,7,2100]: [0*2100+600]=${String.format("%.4f", outputArray[0 * 2100 + 600])}, [1*2100+600]=${String.format("%.4f", outputArray[1 * 2100 + 600])}")
            
            val detectionsList = mutableListOf<Pair<Float, Map<String, Any>>>()
            var highConfidenceCount = 0
            var mediumConfidenceCount = 0
            var lowConfidenceCount = 0
            var zeroCount = 0
            
            for (i in 0 until numPredictions) {
                try {
                    // For grouped-by-channel [1, numHeads, 2100] format:
                    // All x coords (2100), then all y coords (2100), etc.
                    
                    var xNorm = value(0, i)                        // x coordinate
                    var yNorm = value(1, i)                        // y coordinate
                    var wNorm = value(2, i)                        // width
                    var hNorm = value(3, i)                        // height
                    val objectness = value(4, i)                   // objectness score
                    val classLogit0 = value(5, i)                  // class 0 logit (over_fermented)
                    val classLogit1 = value(6, i)                  // class 1 logit (properly_fermented)

                    // Some TFLite exports retain normalized box coordinates instead of pixels.
                    if (maxOf(kotlin.math.abs(xNorm), kotlin.math.abs(yNorm), kotlin.math.abs(wNorm), kotlin.math.abs(hNorm)) <= 2f) {
                        xNorm *= INPUT_SIZE
                        yNorm *= INPUT_SIZE
                        wNorm *= INPUT_SIZE
                        hNorm *= INPUT_SIZE
                    }
                    
                    // DEBUG: Check raw logit values for first few predictions
                    if (i < 5) {
                        android.util.Log.d("SmartCacao", "RAW_LOGITS [i=$i]: ch0=${String.format("%.4f", outputArray[0 * 2100 + i])}, ch5=${String.format("%.4f", classLogit0)}, ch6=${String.format("%.4f", classLogit1)}")
                    }
                    
                    // ONNX export already applies sigmoid to class channels 5-6
                    // They're already in [0, 1] range as probabilities, NOT raw logits
                    // So use them directly without sigmoid!
                    val classProb0 = classLogit0  // Already a probability [0, 1]
                    val classProb1 = classLogit1  // Already a probability [0, 1]
                    
                    // Class 2 inference based on ambiguity
                    val classLogit2: Float
                    val classDiff = kotlin.math.abs(classLogit0 - classLogit1)
                    
                    // Now we have 8 channels in the new model, so channel 7 is class 2
                    if (numHeads >= 8) {
                        // Use direct class 2 from channel 7
                        classLogit2 = value(7, i)
                        android.util.Log.d("SmartCacao", "CLASS2_FROM_CHANNEL [i=$i]: Using channel 7 value: ${String.format("%.4f", classLogit2)}")
                    } else {
                        // Fallback for 7-channel models (shouldn't happen with new model)
                        classLogit2 = when {
                            (classLogit0 < 0.3f && classLogit1 < 0.3f && classDiff > 0.05f) -> {
                                0.1f  // Boost for class 2
                            }
                            else -> 0f
                        }
                    }
                    val classProb2 = classLogit2  // Direct use, no sigmoid
                    
                    // Check for all zeros
                    if (xNorm == 0f && yNorm == 0f && wNorm == 0f && hNorm == 0f && objectness == 0f && classProb0 == 0f && classProb1 == 0f && classProb2 == 0f) {
                        zeroCount++
                        continue
                    }
                    
                    // Don't pre-filter by objectness - let final confidence threshold handle it
                    // This allows low-objectness but high-classProb detections through
                    
                    // Coordinates are in model space (0-320), which includes letterbox padding
                    // Padding: 0-70 top, 70-250 image, 250-320 bottom
                    val xPixel = xNorm
                    val yPixel = yNorm
                    val wPixel = wNorm
                    val hPixel = hNorm
                    
                    // DEBUG: Log coordinates with area info
                    if (objectness >= 0.1f) {
                        val inPaddingTop = yPixel < 70f
                        val inImage =yPixel >= 70f && yPixel < 250f
                        val inPaddingBottom = yPixel >= 250f
                        val areaDesc = when {
                            inPaddingTop -> "TOP_PADDING"
                            inImage -> "IMAGE_AREA"
                            inPaddingBottom -> "BOTTOM_PADDING"
                            else -> "UNKNOWN"
                        }
                        android.util.Log.d("SmartCacao", "PIXEL COORDS [i=$i]: x=${String.format("%.2f", xPixel)} y=${String.format("%.2f", yPixel)} (${areaDesc}) w=${String.format("%.2f", wPixel)} h=${String.format("%.2f", hPixel)}")
                    }
                    
                    // Find best class (classProb2 already calculated above)
                    // Using raw class logits like reference app (NOT multiplied by objectness)
                    val classProbs = floatArrayOf(classProb0, classProb1, classProb2)
                    val bestClassIdx = classProbs.indices.maxByOrNull { classProbs[it] } ?: 0
                    val bestClassProb = classProbs[bestClassIdx]
                    
                    // This export exposes class probabilities directly; use the best class
                    // probability as the displayed confidence, matching the prior working path.
                    val finalConfidence = bestClassProb
                    
                    // DEBUG: Log predictions with any confidence
                    if (finalConfidence >= 0.05f) {
                        android.util.Log.d("SmartCacao", "DEBUG [i=$i] obj=${String.format("%.3f", objectness)} | probs=[${String.format("%.3f", classProb0)},${String.format("%.3f", classProb1)},${String.format("%.3f", classProb2)}] | best_idx=$bestClassIdx best_prob=${String.format("%.3f", bestClassProb)} final=${String.format("%.3f", finalConfidence)} | class=${classNames.getOrNull(bestClassIdx) ?: "unknown"}")
                    }
                    
                    if (finalConfidence >= 0.020f) {
                        highConfidenceCount++
                    } else if (finalConfidence >= 0.010f) {
                        mediumConfidenceCount++
                    } else {
                        lowConfidenceCount++
                    }
                    
                    // Threshold: Require BOTH objectness AND class confidence to reduce false positives
                    // Balance: Low enough to catch real beans, high enough to filter noise
                    if (finalConfidence >= MIN_CLASS_CONFIDENCE &&
                        objectness >= MIN_OBJECTNESS) {
                        // DEBUG: Log coordinates with verification info
                        android.util.Log.d("SmartCacao", "COORD_DEBUG [i=$i] model=(${String.format("%.2f",xPixel)},${String.format("%.2f",yPixel)}) class=$bestClassIdx conf=${String.format("%.3f",finalConfidence)} obj=${String.format("%.3f",objectness)}")
                        
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
            val finalDetections = applyNMS(detectionsList, 0.5f)  // RAISED: was 0.3f, now 0.5f
            
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
        interpreter?.close()
        interpreter = null
    }
}
