# SmartCacao - Complete Integration Guide

This guide walks you through the entire SmartCacao system from dataset preparation to mobile deployment.

## Table of Contents

1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
3. [Dataset Preparation](#dataset-preparation)
4. [Model Training](#model-training)
5. [Model Conversion](#model-conversion)
6. [Flutter Integration](#flutter-integration)
7. [Testing & Deployment](#testing--deployment)
8. [Troubleshooting](#troubleshooting)

## Project Overview

SmartCacao is an AI-powered mobile application for detecting and classifying cacao bean fermentation levels. It uses:

- **Frontend**: Flutter (mobile app)
- **ML Framework**: YOLOv8 (nano model)
- **Enhancement**: MobileNet + CBAM architecture
- **Deployment**: TensorFlow Lite (mobile inference)
- **Classes**: Under-Fermented, Properly-Fermented, Over-Fermented

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      SmartCacao System                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐         ┌──────────────────┐        │
│  │   Machine Learning│         │   Mobile App     │        │
│  │   (Python/PyTorch)│         │   (Flutter/Dart) │        │
│  └──────────────────┘         └──────────────────┘        │
│           │                             │                  │
│           ├─ Dataset                    ├─ Camera          │
│           ├─ train.py                   ├─ TFLiteService   │
│           ├─ Model Training             ├─ ImageUtils      │
│           └─ convert_model.py           └─ UI Screens      │
│                    │                             │          │
│                    └──────────────┬──────────────┘          │
│                                   │                        │
│                          Model Exchange                    │
│                    (best.tflite 10-15MB)                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Dataset Preparation

### Step 1: Collect Images

Gather cacao bean images at different fermentation stages:

```
Quick Tips:
- Use consistent lighting (natural or studio)
- Capture from multiple angles
- Include closeups and wide shots
- Collect 100-200 images per class minimum
```

### Step 2: Prepare with Roboflow (Recommended)

1. **Create Account**
   - Go to [roboflow.com](https://roboflow.com/)
   - Sign up and create new dataset

2. **Upload Images**
   - Upload all collected images
   - Organize by fermentation class

3. **Annotate**
   - Draw bounding boxes around beans
   - Label each bean with correct class
   - Ensure accurate annotations

4. **Generate Dataset**
   - Export as "YOLO v8" format
   - Download to your computer
   - Extract to `dataset/` folder in ML directory

### Step 3: Verify Dataset Structure

```
smartcacao ML/
└── dataset/
    ├── images/
    │   ├── train/
    │   │   ├── image_001.jpg
    │   │   ├── image_002.jpg
    │   │   └── ...
    │   └── val/
    │       ├── image_050.jpg
    │       └── ...
    └── labels/
        ├── train/
        │   ├── image_001.txt
        │   ├── image_002.txt
        │   └── ...
        └── val/
            ├── image_050.txt
            └── ...
```

## Model Training

### Step 1: Setup Python Environment

```bash
cd "smartcacao ML"

# Create virtual environment
python -m venv venv

# Activate it
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Verify Dataset Config

Check `cacao_dataset.yaml`:

```yaml
path: dataset
train: images/train
val: images/val

names:
  0: under_fermented
  1: properly_fermented
  2: over_fermented
```

### Step 3: Start Training

```bash
python train.py
```

**What this does:**
- Loads YOLOv8 nano pre-trained model
- Trains on your cacao dataset
- Saves best model to `runs/detect/train/weights/best.pt`
- Validates on validation set
- Exports to TFLITE and ONNX formats

**Training takes:**
- ~30-60 minutes on GPU
- ~2-4 hours on CPU
- Depends on dataset size and hardware

### Step 4: Monitor Training

Check training metrics:
```bash
# View training plots
# Open: runs/detect/train/results.png

# View metrics
# Open: runs/detect/train/results.csv
```

Expected results:
- mAP@50: 85-92%
- Loss decreasing over epochs
- Validation metrics improving

## Model Conversion

### Step 1: Convert Model

```bash
# Automatic conversion (recommended)
python convert_model.py

# This will:
# 1. Find latest trained model
# 2. Convert to TFLite format
# 3. Convert to ONNX format
# 4. Copy TFLite to Flutter assets
```

### Step 2: Verify Conversion

Check that TFLite model is in place:

```
smartcacao/
├── assets/
│   └── models/
│       └── best.tflite  ✓ (Should be here)
```

### Step 3: Model Specifications

Your converted model should have:
- **Format**: FlatBuffers (.tflite)
- **Size**: 10-15 MB
- **Input Shape**: [1, 640, 640, 3]
- **Input Type**: Float32
- **Output**: Detections [1, 84, 8400]

## Flutter Integration

### Step 1: Verify Flutter Setup

```bash
cd ../smartcacao

# Check Flutter installation
flutter doctor

# Install dependencies
flutter pub get
```

### Step 2: Verify Model is Present

```bash
# The model should be at:
# smartcacao/assets/models/best.tflite

# If not, run conversion again:
cd ../smartcacao\ ML
python convert_model.py
```

### Step 3: Run the App

```bash
cd ../smartcacao

# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just run
flutter run
```

### Step 4: Test the App

1. **Home Screen**: Should display app features
2. **Camera Access**: Grant camera permission
3. **Capture**: Point at bean image, tap capture
4. **Results**: View fermentation classification

## Testing & Deployment

### Unit Testing

```bash
cd smartcacao
flutter test
```

### Integration Testing

```bash
# Test on real device
flutter run --profile

# Capture screenshots
flutter screenshot
```

### Building Release APK (Android)

```bash
cd smartcacao

# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/apk/release/app-release.apk
```

### Building IPA (iOS)

```bash
cd smartcacao

# Build for iOS
flutter build ipa

# Output location:
# build/ios/iphoneos/Runner.app
```

## Troubleshooting

### Training Issues

#### Error: "Dataset not found"
```
Solution:
1. Run in smartcacao ML/ directory
2. Verify dataset/ folder exists
3. Check cacao_dataset.yaml paths
```

#### Error: "CUDA out of memory"
```
Solution:
1. Edit train.py
2. Reduce BATCH_SIZE from 16 to 8
3. Or use device='cpu'
```

#### Error: "Model not converging"
```
Solution:
1. Increase EPOCHS in train.py
2. Check dataset quality
3. Ensure balanced class distribution
4. Verify annotations are correct
```

### Conversion Issues

#### Error: "Model file not found"
```
Solution:
python convert_model.py --list
# Choose the latest train run and specify it
python convert_model.py runs/detect/train/weights/best.pt
```

#### Error: "Output directory not found"
```
Solution:
1. Ensure smartcacao folder exists
2. Create assets/models directory:
   mkdir -p smartcacao/assets/models
3. Run conversion again
```

### Flutter Issues

#### Error: "Model not loaded"
```
Solution:
1. Verify assets/models/best.tflite exists
2. Run: flutter pub get
3. Run: flutter clean
4. Run: flutter run
```

#### Error: "Camera permission denied"
```
Solution:
1. Grant camera permission when prompted
2. Check AndroidManifest.xml for permissions
3. Check Info.plist for iOS permissions
4. Restart app
```

#### Error: "Inference failed"
```
Solution:
1. Check model file integrity
2. Ensure image preprocessing is correct
3. Verify model input shape matches
4. Check TFLite output parsing
```

## Performance Checklist

- [ ] Model accuracy >85% mAP@50
- [ ] Inference time <300ms
- [ ] App binary size <100MB
- [ ] Model file <20MB
- [ ] Camera permission granted
- [ ] All 3 classes trained
- [ ] Results screen displays correctly

## Deployment Checklist

### Pre-Deployment
- [ ] All tests pass
- [ ] Model converts successfully
- [ ] App runs on multiple devices
- [ ] Camera and predictions work
- [ ] UI is responsive
- [ ] No console errors

### Deployment
- [ ] Build release APK
- [ ] Test release build on device
- [ ] Prepare Google Play Store listing
- [ ] Configure app signing
- [ ] Submit for review

## Next Steps

1. **Immediate**
   - Prepare cacao dataset (100+ images per class)
   - Run training
   - Convert model
   - Test in Flutter

2. **Short-term**
   - Improve model accuracy with more data
   - Optimize for specific devices
   - Add data logging/reporting
   - Conduct user testing

3. **Long-term**
   - Deploy to Google Play Store
   - Collect user feedback
   - Retrain with user data
   - Add new features (batch processing, reports)

## Quick Start Commands

```bash
# ML Side
cd "smartcacao ML"
pip install -r requirements.txt
python train.py
python convert_model.py

# Flutter Side
cd ../smartcacao
flutter pub get
flutter run
```

## Documentation References

- [ML Setup Guide](smartcacao%20ML/README_ML_SETUP.md)
- [Flutter App Guide](smartcacao/README_FLUTTER_APP.md)
- [YOLOv8 Docs](https://github.com/ultralytics/ultralytics)
- [Flutter Docs](https://flutter.dev/docs)
- [TFLite Docs](https://www.tensorflow.org/lite)

## Contact & Support

For questions or issues:
1. Review the troubleshooting sections
2. Check documentation references
3. Review training metrics
4. Validate dataset quality

---

**SmartCacao - Capstone Project**
Cacao Bean Fermentation Detection System
