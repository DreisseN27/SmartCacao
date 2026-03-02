# SmartCacao - Flutter Mobile App

A Flutter-based mobile application for real-time cacao bean fermentation detection using machine learning (YOLOv8).

## Features

✨ **Real-time Detection**
- Live camera feed with detection overlay
- Instant fermentation status analysis
- Visual grid guide for optimal positioning

🧠 **AI-Powered Analysis**
- YOLOv8 nano model for fast inference
- MobileNet+CBAM architecture for enhanced accuracy
- 3-class classification (Under, Proper, Over-fermented)

📊 **Detailed Reports**
- Comprehensive fermentation statistics
- Confidence scores for each detection
- Actionable recommendations
- Detection breakdown by class

🎨 **User-Friendly Interface**
- Intuitive home screen with feature overview
- Real-time camera preview with guides
- Beautiful result visualization
- Easy navigation between screens

## Project Structure

```
smartcacao/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   └── detection.dart        # Detection data model
│   ├── screens/
│   │   ├── home_screen.dart      # Home page
│   │   ├── camera_screen.dart    # Camera capture
│   │   └── result_screen.dart    # Results display
│   ├── services/
│   │   └── tflite_service.dart   # ML model inference
│   └── utils/
│       └── image_utils.dart      # Image preprocessing
├── assets/
│   └── models/
│       └── best.tflite           # Trained model
├── pubspec.yaml                  # Dependencies
└── analysis_options.yaml         # Lint rules
```

## Prerequisites

### System Requirements
- Flutter SDK 3.10.7 or higher
- Android SDK (for Android development)
- Xcode (for iOS development on macOS)
- A device with camera support

### Development Tools
- VS Code or Android Studio
- Git

## Installation & Setup

### 1. Clone/Open the Project
```bash
cd smartcacao
```

### 2. Get Flutter Dependencies
```bash
flutter pub get
```

### 3. Ensure Model is in Place
The ML team should provide the trained model:
```
assets/models/best.tflite
```

Run the conversion script in the ML folder:
```bash
cd ../smartcacao\ ML
python convert_model.py
```

### 4. Run the App
```bash
# Run on connected device
flutter run

# Run on Android emulator
flutter emulators launch <emulator-name>
flutter run

# Run on iOS simulator (macOS only)
open -a Simulator
flutter run
```

## Dependencies

### Core Dependencies
- **flutter**: Basic Flutter framework
- **camera**: ^0.10.5 - Camera access
- **image**: ^4.1.3 - Image processing
- **tflite_flutter**: ^0.10.4 - TensorFlow Lite inference

### Dev Dependencies
- **flutter_test**: Testing framework
- **flutter_lints**: Code quality

## Usage

### Home Screen
- Displays app information and features
- Shows model details (YOLOv8, MobileNet+CBAM)
- Provides quick access to scanning

### Camera Screen
1. Point camera at cacao beans
2. Position beans within the center circle
3. Tap "Capture" button
4. Wait for analysis to complete

### Results Screen
Displays:
- **Status**: Overall fermentation classification
- **Statistics**: Number of beans detected per class
- **Confidence**: Average and highest detection confidence
- **Recommendation**: Action items for the farmer
- **Actions**: Option to scan again or return home

## Model Integration

### Model Details
- **Name**: YOLOv8 Nano
- **Input**: 640x640 RGB image
- **Output**: Detection results with bounding boxes and confidence scores
- **Classes**: 
  - 0: Under-Fermented
  - 1: Properly-Fermented
  - 2: Over-Fermented

### Image Processing Pipeline
1. **Load**: Read image from camera/file
2. **Resize**: Letterbox to 640x640 (maintains aspect ratio)
3. **Normalize**: Scale pixel values to [0, 1]
4. **Inference**: Run through TFLite model
5. **Parse**: Extract detections from model output
6. **Aggregate**: Calculate statistics and recommendations

### Inference Performance
- **Latency**: 100-300ms per image
- **Model Size**: ~10-15 MB
- **Memory**: ~50-100 MB during inference

## Building for Production

### Android Build
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk

# Or for App Bundle (Play Store)
flutter build appbundle
```

### iOS Build
```bash
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app

# Create IPA for distribution
flutter build ipa
```

## Architecture & Code Organization

### TFLiteService
Handles ML model loading and inference:
```dart
- loadModel()              // Load TFLite model from assets
- runInference()          // Run inference on image
- analyzeBeans()          // Full analysis pipeline
- parseOutput()           // Parse model predictions
```

### ImageUtils
Image processing utilities:
```dart
- loadImage()            // Load image from file
- preprocessImage()      // Preprocess for inference
- letterboxResize()      // Resize with padding
- imageToTensor()        // Convert to tensor format
- parseDetections()      // Parse output detections
- getFermentationStatus()// Get status description
- getStatusColor()       // Get UI color for status
```

### UI Screens
- **HomeScreen**: Feature overview and navigation
- **CameraScreen**: Real-time camera capture
- **ResultScreen**: Analysis results and recommendations

## Troubleshooting

### Common Issues

**Issue: Model not found error**
```
Solution:
1. Ensure assets/models/best.tflite exists
2. Run: flutter pub get
3. Verify pubspec.yaml has assets section
4. Run: flutter clean && flutter run
```

**Issue: Camera not initializing**
```
Solution:
1. Check camera permissions in manifest/plist
2. Grant camera permission when prompted
3. Ensure device has a working camera
4. Try restarting app
```

**Issue: Slow inference**
```
Solution:
1. Close background apps
2. Use High resolution preset
3. Ensure sufficient RAM available
4. Try on device with better specs
```

**Issue: Inaccurate detections**
```
Solution:
1. Ensure good lighting
2. Position beans clearly within circle
3. Use trained model (not base model)
4. Check model confidence threshold
```

## Performance Optimization

### Memory Management
- Images are released after processing
- Model is kept in memory during app runtime
- Background tasks run asynchronously

### Battery Optimization
- Camera uses minimum necessary resolution
- Inference done only on capture
- Screen keeps on during capture mode

### Network
- App works completely offline
- No network requests needed after model is loaded

## Testing

### Manual Testing
```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

### Device Testing
1. Test on various devices (phones, tablets)
2. Test with different image qualities
3. Test with different lighting conditions
4. Verify all UI interactions work

## Deployment

### Development
```bash
flutter run -d <device-id>
```

### Testing
```bash
flutter run --profile
```

### Production
```bash
flutter run --release
```

## Contributing

When making changes:
1. Follow Dart best practices
2. Run `flutter analyze` to check code quality
3. Format code: `flutter format lib/`
4. Test all changes thoroughly

## API Reference

### Detection Model
```dart
class Detection {
  String label;           // 'under_fermented', 'properly_fermented', 'over_fermented'
  double confidence;      // 0.0 to 1.0
  double x, y;           // Center coordinates
  double width, height;  // Bounding box dimensions
}
```

### Analysis Result
```dart
{
  'success': bool,
  'message': String,
  'fermentationStatus': String,
  'statistics': {
    'totalBeansDetected': int,
    'underFermented': int,
    'properlyFermented': int,
    'overFermented': int,
  },
  'confidence': {
    'average': double,
    'highest': double,
  },
  'recommendation': String,
  'detections': List<Map>
}
```

## File Size Reference

- **App APK**: ~45-50 MB (with model)
- **App IPA**: ~60-70 MB (with model)
- **Model Size**: 10-15 MB

## Future Enhancements

- [ ] Batch image processing
- [ ] Historical data visualization
- [ ] Export reports to PDF
- [ ] Cloud backup of results
- [ ] Multi-language support
- [ ] Dark theme support
- [ ] AR visualization of detections

## License

This project is part of a capstone thesis project.

## Support & Contact

For issues or questions:
1. Check the troubleshooting section
2. Review Flutter logs: `flutter logs`
3. Check ML model metrics in `smartcacao ML/README_ML_SETUP.md`
4. Verify dataset quality and model training

---
**SmartCacao** - Capstone Project for Cacao Bean Fermentation Detection
Built with Flutter and YOLOv8 Machine Learning
