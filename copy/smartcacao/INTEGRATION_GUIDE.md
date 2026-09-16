# SmartCacao ML Model Integration Guide

## Overview
Your YOLOv8s + CBAM + MobileNet model has been integrated into your Flutter mobile app. The model is now ready for testing on Android devices.

## Setup Completed

### ✅ What's Been Done:
1. **Model Preparation**
   - ONNX model (`best.onnx`) placed in `assets/models/`
   - Asset configuration in `pubspec.yaml` updated

2. **Android Permissions**
   - Camera permission added to `AndroidManifest.xml`
   - Storage read/write permissions added for result storage
   - Runtime permission handling implemented with `permission_handler` package

3. **Native Integration**
   - ONNX Runtime dependency configured in `build.gradle.kts`
   - Kotlin native code (`CacaoModelInference.kt`) handles model loading and inference
   - Platform channel set up for Dart-to-Android communication

4. **Flutter Setup**
   - `permission_utils.dart` created for runtime permission management
   - Camera screen updated to request permissions before camera access
   - TFLiteService configured to work with the native model loader

## Building and Running on Android

### Prerequisites
- Android SDK (API level 21+)
- Android Studio / Flutter SDK
- An Android device or emulator

### Step 1: Clean Previous Builds
```bash
cd smartcacao
flutter clean
```

### Step 2: Get Dependencies
```bash
flutter pub get
```

### Step 3: Build APK (Debug)
```bash
flutter build apk --debug
```

Or for release (optimized):
```bash
flutter build apk --release
```

### Step 4: Connect Your Android Device
- Enable Developer Mode on your device (tap Build Number 7 times in Settings)
- Enable USB Debugging in Developer Options
- Connect via USB
- Allow USB debugging permission when prompted

### Step 5: Run the App
```bash
flutter run
```

This will automatically build and install the app on your connected device.

**Or** in Android Studio:
1. Click **Run** > **Run 'app'** (or press Shift+F10)
2. Select your device from the list
3. Click **OK**

## Model Inference Flow

### How It Works:
1. **Image Capture**: Camera captures frame or user takes photo
2. **Preprocessing**: Image resized to 640×640 and normalized
3. **Inference**: ONNX Runtime runs the model on the image
4. **Detection**: Bounding boxes parsed with confidence scores
5. **NMS**: Non-Maximum Suppression removes overlapping detections
6. **Display**: Results shown in real-time or in result screen

### Expected Output Classes:
- `under_fermented` (Red) - Needs more fermentation time
- `properly_fermented` (Green) - Good fermentation
- `over_fermented` (Yellow) - Over-fermented

## Troubleshooting

### "Model not found" Error
**Problem**: App shows model loading error
**Solution**:
1. Ensure `best.onnx` exists in `smartcacao/assets/models/`
2. Run `flutter clean` and rebuild
3. Check that `pubspec.yaml` includes `- assets/models/`

### "Permission Denied" Error
**Problem**: Camera access denied
**Solution**:
1. Grant camera permissions when prompted
2. Or go to Settings > Apps > SmartCacao > Permissions > Camera > Allow
3. Restart the app

### "ONNX Runtime Error"
**Problem**: Native inference fails
**Solution**:
1. Verify ONNX Runtime is added to `build.gradle.kts`
2. Check the Logcat output in Android Studio for specific errors
3. Ensure the model format matches ONNX specifications

### App Crashes on Launch
**Problem**: App crashes immediately
**Solution**:
1. Check Android Logcat (Android Studio > Logcat)
2. Look for Java/Kotlin exceptions
3. Ensure all dependencies are installed: `flutter pub get`
4. Try rebuilding: `flutter clean && flutter build apk --debug`

## File Structure

```
smartcacao/
├── assets/
│   └── models/
│       └── best.onnx          ← Your trained model
├── android/
│   └── app/
│       ├── build.gradle.kts   ← ONNX Runtime dependency
│       └── src/main/
│           ├── AndroidManifest.xml    ← Permissions
│           └── kotlin/com/example/smartcacao/
│               ├── MainActivity.kt     ← Platform channel setup
│               └── CacaoModelInference.kt ← Native model inference
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── detection.dart
│   ├── screens/
│   │   ├── camera_screen.dart  ← Permission handling added
│   │   ├── home_screen.dart
│   │   ├── history_screen.dart
│   │   └── result_screen.dart
│   ├── services/
│   │   ├── tflite_service.dart
│   │   └── storage_service.dart
│   └── utils/
│       ├── image_utils.dart
│       └── permission_utils.dart ← New: Runtime permissions
└── pubspec.yaml
```

## Testing the Integration

### Live Detection Mode
1. Launch the app
2. Tap "LIVE" button in camera screen
3. Point camera at cacao samples
4. Watch real-time detections appear with bounding boxes

### Single Capture Mode
1. Launch the app
2. Tap "CAPTURE" button to switch modes
3. Take a photo of a cacao sample
4. See detailed results on the Result Screen

## Next Steps

### To Improve Model Performance:
1. Collect more training data
2. Fine-tune thresholds in:
   - `confidenceThreshold` (line ~115 in CacaoModelInference.kt)
   - `iouThreshold` (line ~135 in CacaoModelInference.kt)
3. Retrain the model with updated dataset

### To Deploy to Production:
1. Generate signed APK:
   ```bash
   flutter build apk --release
   ```
2. Get signing key from Android Studio:
   - Build > Generate Signed Bundle/APK
   - Use existing keystore or create new
3. Test thoroughly on multiple devices

## Support

For issues or questions:
1. Check the Logcat output in Android Studio
2. Review the native code in `CacaoModelInference.kt`
3. Ensure all files are in correct locations
4. Verify permissions are granted

---

**Model Details:**
- Architecture: YOLOv8s + CBAM + MobileNet
- Input Size: 640×640 RGB
- Output Format: ONNX
- Classes: 3 (under_fermented, properly_fermented, over_fermented)
