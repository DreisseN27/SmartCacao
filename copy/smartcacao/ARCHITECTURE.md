# Model Integration Architecture

## System Overview

Your ML model is integrated using a **Platform Channel** architecture that bridges Dart/Flutter with native Android code.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter (Dart)                             │
│                                                                   │
│  ┌────────────────────┐       ┌──────────────────────────────┐  │
│  │   Camera Screen    │─────▶│   TFLiteService              │  │
│  │  (UI & Logic)      │       │  (Model API Wrapper)         │  │
│  └────────────────────┘       └──────────────────────────────┘  │
│                                      │                            │
│                                      │ invokeMethod               │
│                                      │ (loadModel, runInference)  │
│                                      ▼                            │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │        Platform Channel: com.example.smartcacao/model      │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
            ┌──────────────────────┐      ┌──────────────────────┐
            │    Android SDK       │      │  Android Native Code │
            │                      │      │   (Kotlin)           │
            │  MethodChannel       │      │                      │
            │  Handler             │◀────▶│ MainActivity.kt      │
            │                      │      │                      │
            └──────────────────────┘      └──────────────────────┘
                                               │
                  ┌────────────────────────────┼────────────────────────┐
                  │                            │                        │
                  ▼                            ▼                        ▼
        ┌──────────────────┐      ┌─────────────────────┐     ┌─────────────────┐
        │  ONNX Runtime    │      │ CacaoModelInference │     │  File I/O       │
        │  (AI Inference)  │◀────▶│  (Model Loading &   │     │ (Image Handling)│
        │                  │      │   Inference)        │     │                 │
        └──────────────────┘      └─────────────────────┘     └─────────────────┘
                  │                            │
                  │                            ▼
                  │                  ┌──────────────────────┐
                  │                  │  best.onnx           │
                  │                  │  (Model Weights)     │
                  │                  │  From: assets/models/│
                  │                  └──────────────────────┘
                  │
                  ▼
        ┌──────────────────────┐
        │  Detection Results   │
        │  - Bounding boxes    │
        │  - Class labels      │
        │  - Confidence scores │
        └──────────────────────┘
```

## Data Flow

### 1. Model Loading
```
App Startup
    ↓
CameraScreen.initState()
    ↓
TFLiteService.loadModel()
    ↓
Platform Channel: "loadModel"
    ↓
MainActivity.onMethodCall()
    ↓
CacaoModelInference.initializeModel()
    ↓
Read best.onnx from assets/flutter_assets/assets/models/
    ↓
Create OrtSession (ONNX Runtime)
    ↓
Return success to Dart
    ↓
Model Ready for Inference ✓
```

### 2. Image Capture & Processing
```
User captures image / Camera frame streaming
    ↓
CameraScreen.captureImage() or processFrame()
    ↓
Convert CameraImage to File
    ↓
Save to temporary location: /data/local/tmp/
    ↓
Pass file path to inference service
```

### 3. Inference Process
```
TFLiteService.runInference(imagePath)
    ↓
Platform Channel: "runInference"
    ↓
CacaoModelInference.runInference()
    ↓
BitmapFactory.decodeFile(imagePath)
    ↓
Preprocess Image:
  - Resize to 640×640
  - Normalize pixels to [0, 1]
  - Convert to CHW format
    ↓
Run ONNX Runtime:
  Input:  [1, 3, 640, 640] float tensor
  Output: [1, 8400, 8] detection tensor
    ↓
Parse Detections:
  For each of 8400 possible detections:
    - Extract bounds (x, y, w, h)
    - Extract objectness score
    - Extract class probabilities
    - Create Detection object if confidence > threshold
    ↓
Apply Non-Maximum Suppression (NMS):
  - Remove overlapping boxes
  - Keep only highest confidence detections
    ↓
Return List<Detection> to Dart
    ↓
TFLiteService receives detections
    ↓
Display in UI / Generate report
```

## File Locations

```
smartcacao/
├── assets/models/
│   └── best.onnx                    ← Your trained model (input)
│
├── android/
│   └── app/
│       ├── build.gradle.kts         ← ONNX Runtime dependency
│       └── src/main/
│           ├── AndroidManifest.xml  ← Permissions
│           └── kotlin/com/example/smartcacao/
│               ├── MainActivity.kt   ← Platform channel setup
│               └── CacaoModelInference.kt ← Inference logic
│
└── lib/
    ├── services/
    │   └── tflite_service.dart      ← Dart API for model
    ├── models/
    │   └── detection.dart            ← Detection data class
    ├── screens/
    │   └── camera_screen.dart        ← UI & camera handling
    └── utils/
        └── permission_utils.dart     ← Runtime permissions
```

## Key Components

### 1. **best.onnx**
- Your trained YOLOv8s + CBAM + MobileNet model
- Location: `assets/models/best.onnx`
- Loaded into memory at app startup
- ONNX format (Open Neural Network Exchange)

### 2. **ONNX Runtime**
- Inference engine that runs the model
- Supports CPU inference on Android
- Dependency: `com.microsoft.onnxruntime:onnxruntime-android`
- Handles model optimization and execution

### 3. **CacaoModelInference.kt**
- Loads model from assets
- Preprocesses images (resize, normalize)
- Runs inference using ONNX Runtime
- Parses output tensor into detections
- Implements Non-Maximum Suppression

### 4. **TFLiteService (Dart)**
- High-level API for model operations
- Calls native code via platform channel
- Handles error management
- Parses detection results

### 5. **Detection Model Output**
```
For each detection (8 values):
- x: center x coordinate (0-640)
- y: center y coordinate (0-640)
- w: bounding box width
- h: bounding box height
- objectness: probability that region contains object (0-1)
- class_prob_0: probability of under_fermented (0-1)
- class_prob_1: probability of properly_fermented (0-1)
- class_prob_2: probability of over_fermented (0-1)

Final confidence = objectness × best_class_probability
```

## Performance Characteristics

| Aspect | Value |
|--------|-------|
| **Model Input Size** | 640×640 pixels |
| **Inference Time** | ~100-200ms (varies by device) |
| **Model Size** | ~25-50 MB (ONNX file) |
| **Memory Usage** | ~150-300 MB during inference |
| **Live Detection FPS** | ~5-10 FPS (depending on device processor) |
| **Output Classes** | 3 (under_fermented, properly_fermented, over_fermented) |

## Thresholds and Tuning

Located in `CacaoModelInference.kt`:

```kotlin
// Line ~115: Confidence filtering
val confidenceThreshold = 0.5f  // Minimum confidence to report detection

// Line ~135: NMS (Non-Maximum Suppression)
val iouThreshold = 0.4f  // Overlap threshold for box suppression
```

**Tuning Guide:**
- **Lower confidence threshold** → More detections (more false positives)
- **Higher confidence threshold** → Fewer detections (fewer false positives)
- **Lower IOU threshold** → Remove more overlaps (fewer boxes per bean)
- **Higher IOU threshold** → Keep more overlaps (more boxes per bean)

## Error Handling

```
Model Loading Failures:
├── File not found → Check assets/models/best.onnx exists
├── ONNX format error → Verify model is valid ONNX file
├── Memory error → Device may be too low power
└── Permission error → Check AndroidManifest.xml

Inference Failures:
├── Image file not found → Check temp file creation
├── Tensor shape mismatch → Model input/output format issue
├── ONNX library error → Build issue (missing dependency)
└── Out of memory → Image too large or device limited
```

## Testing the Integration

### Test 1: Model Loading
```
Open app → Wait for "Model loaded" message
→ SUCCESS if no red error banner
```

### Test 2: Live Detection
```
Switch to "LIVE" mode
→ Point camera at cacao beans
→ SUCCESS if bounding boxes appear in real-time
```

### Test 3: Single Capture
```
Switch to "CAPTURE" mode
→ Take photo
→ Wait for processing
→ SUCCESS if result screen shows detections
```

### Test 4: Detect All Classes
```
Capture images containing:
  - Under-fermented beans (should show RED boxes)
  - Properly-fermented beans (should show GREEN boxes)
  - Over-fermented beans (should show YELLOW boxes)
→ SUCCESS if all three classes detected correctly
```

## Deployment Considerations

### For Production:
1. **Model size** - ~30-50 MB (ensure sufficient APK size)
2. **Device compatibility** - Tested on Android 8.0+ (API 26+)
3. **Performance** - Consider:
   - Reduced resolution for slower devices
   - Frame skipping for live mode
   - Batch processing capabilities
4. **Security** - Model file is not encrypted (consider if IP protection needed)

### Future Optimizations:
1. **Quantization** - Reduce model size and speed up inference
2. **Mobile-specific** - Convert to TensorFlow Lite (`.tflite`)
3. **GPU acceleration** - Use ONNX GPU delegate (requires device support)
4. **Multi-threading** - Parallel inference on multiple cores

---

**Architecture Summary**: Your model runs entirely on the device (no cloud calls), providing fast, private inference suitable for field use.
