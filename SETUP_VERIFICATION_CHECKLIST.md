# SmartCacao - Setup Verification Checklist

Use this checklist to verify your system is correctly set up.

## ✅ Pre-Setup Requirements

- [ ] Python 3.8+ installed
- [ ] Flutter SDK 3.10.7+ installed
- [ ] Git installed (optional)
- [ ] Device with camera (for testing)
- [ ] 20GB+ free space on disk

Verify with:
```bash
python --version
flutter --version
```

---

## ✅ Python Environment (ML)

Located in: `smartcacao ML/`

### Virtual Environment
```bash
cd "smartcacao ML"
python -m venv venv
venv\Scripts\activate  # Windows
# or
source venv/bin/activate  # macOS/Linux
```

- [ ] venv folder created
- [ ] venv activated (see `(venv)` in terminal)

### Dependencies Installed
```bash
pip install -r requirements.txt
```

Verify:
```bash
python -c "import ultralytics; print(ultralytics.__version__)"
python -c "import torch; print(torch.__version__)"
```

- [ ] ultralytics installed (should show version)
- [ ] torch installed (should show version)

### Dataset
```
smartcacao ML/
└── dataset/
    ├── images/
    │   ├── train/  (with .jpg files)
    │   └── val/    (with .jpg files)
    └── labels/
        ├── train/  (with .txt files)
        └── val/    (with .txt files)
```

- [ ] dataset/ folder exists
- [ ] images/train/ has images
- [ ] images/val/ has images
- [ ] labels/train/ has .txt files
- [ ] labels/val/ has .txt files

### Dataset Configuration
```bash
cat cacao_dataset.yaml
```

Output should show:
```yaml
path: dataset
train: images/train
val: images/val
names:
  0: under_fermented
  1: properly_fermented
  2: over_fermented
```

- [ ] cacao_dataset.yaml exists
- [ ] paths point to correct folders
- [ ] 3 classes defined correctly

---

## ✅ Training Script (train.py)

```bash
cd "smartcacao ML"
python train.py
```

Expected behavior:
- [ ] Script starts without errors
- [ ] Shows dataset info
- [ ] Begins training with epoch progress
- [ ] Shows loss and metrics

After completion:
- [ ] runs/detect/train/ folder created
- [ ] runs/detect/train/weights/best.pt exists
- [ ] runs/detect/train/results.csv shows metrics
- [ ] No errors in console

---

## ✅ Model Conversion (convert_model.py)

```bash
cd "smartcacao ML"
python convert_model.py
```

Expected behavior:
- [ ] Script finds latest trained model
- [ ] Exports to TFLite format
- [ ] Exports to ONNX format
- [ ] Shows success messages

After completion:
- [ ] runs/detect/train/weights/best.tflite exists
- [ ] runs/detect/train/weights/best.onnx exists
- [ ] Message: "Copied to Flutter assets"

Verify model was copied:
```bash
dir ../smartcacao/assets/models/best.tflite
# Should show the file with size 10-15 MB
```

- [ ] ../smartcacao/assets/models/best.tflite exists
- [ ] File size is 10-15 MB

---

## ✅ Flutter Setup

Located in: `smartcacao/`

### Flutter Doctor
```bash
cd ../smartcacao
flutter doctor
```

Output should show:
- [ ] Flutter: ✓ (in path)
- [ ] Dart: ✓ (valid version)
- [ ] Android SDK: ✓ or ✗ (depending on target)
- [ ] Xcode: ✓ or ✗ (depending on target)

Issues to fix:
- [ ] Get Flutter: https://flutter.dev/docs/get-started/install
- [ ] Agree to Android licenses: `flutter doctor --android-licenses`

### Dependencies
```bash
flutter pub get
```

- [ ] All packages downloaded
- [ ] No errors shown
- [ ] pubspec.lock created

### Assets Folder
```
smartcacao/
└── assets/
    └── models/
        └── best.tflite
```

- [ ] assets/ folder exists
- [ ] assets/models/ folder exists
- [ ] best.tflite present (10-15 MB)

### pubspec.yaml
Check that this line exists:
```yaml
assets:
  - assets/models/best.tflite
```

- [ ] assets section defined
- [ ] best.tflite path listed

---

## ✅ Code Files (All Present?)

### ML Scripts
```
smartcacao ML/
├── train.py         ✓
├── convert_model.py ✓
├── requirements.txt ✓
└── cacao_dataset.yaml ✓
```

- [ ] train.py exists and enhanced
- [ ] convert_model.py exists and new
- [ ] requirements.txt exists

### Flutter Code
```
smartcacao/
├── lib/
│   ├── main.dart                  ✓
│   ├── models/
│   │   └── detection.dart         ✓
│   ├── screens/
│   │   ├── home_screen.dart       ✓
│   │   ├── camera_screen.dart     ✓
│   │   └── result_screen.dart     ✓
│   ├── services/
│   │   └── tflite_service.dart    ✓
│   └── utils/
│       └── image_utils.dart       ✓
├── assets/models/
│   └── best.tflite               ✓
└── pubspec.yaml                  ✓
```

- [ ] All .dart files exist
- [ ] All files have proper content
- [ ] No syntax errors

Verify with:
```bash
cd smartcacao
flutter analyze
```

- [ ] No analysis errors

---

## ✅ Device/Emulator Setup

### Android
```bash
flutter devices
```

Should show available devices. Need one of:
- [ ] Physical Android device (USB connected)
- [ ] Android emulator running
- [ ] Firebase emulator

### iOS
- [ ] Physical iPhone connected (OR)
- [ ] iOS Simulator running
- [ ] Xcode installed (macOS only)

Verify:
```bash
flutter devices
```

- [ ] At least one device listed

---

## ✅ App Build & Run

### Build Check
```bash
cd smartcacao
flutter pub get
```

- [ ] No errors
- [ ] All dependencies resolved

### Run App
```bash
flutter run
```

Expected flow:
- [ ] App compiles without errors
- [ ] App launches on device
- [ ] Home screen displays
- [ ] Camera button visible
- [ ] Settings button visible

### Test Capture Flow
1. [ ] Tap "Scan Cacao Beans" button
2. [ ] Camera screen opens
3. [ ] Grant camera permission
4. [ ] Live preview shows
5. [ ] Grid overlay visible
6. [ ] Tap "Capture" button
7. [ ] Loading indicator shows
8. [ ] Results screen displays
9. [ ] Statistics shown
10. [ ] Recommendations visible

---

## ✅ Documentation

Required files:
- [ ] INTEGRATION_GUIDE.md exists
- [ ] PROJECT_COMPLETION_SUMMARY.md exists
- [ ] QUICK_REFERENCE.md exists
- [ ] smartcacao ML/README_ML_SETUP.md exists
- [ ] smartcacao/README_FLUTTER_APP.md exists

---

## ✅ Final Verification

### Project Structure
```bash
cd "MOBILE/Capstone"
tree /L 2  # Windows; use `find . -maxdepth 2` on Linux/Mac
```

Should show:
- [ ] smartcacao/ with lib, assets, android, ios
- [ ] smartcacao ML/ with train.py, convert_model.py, dataset
- [ ] All .md files at root

### File Count Check
```bash
cd smartcacao/lib
find . -name "*.dart" | wc -l
# Should be 8 files
```

- [ ] 8 Dart files total

### Model File Check
```bash
ls -lh smartcacao/assets/models/best.tflite
# Should show size 10-15 MB
```

- [ ] File exists
- [ ] Size 10-15 MB

---

## ✅ Ready to Use!

All checks passed? Then you can:

### Train a Model
```bash
cd "smartcacao ML"
python train.py
python convert_model.py
```

### Run the App
```bash
cd ../smartcacao
flutter run
```

### Build for Distribution
```bash
flutter build apk --release      # Android
flutter build ipa                 # iOS
```

---

## ⚠️ Common Issues

### Issue: Python not found
**Solution**: Install Python 3.8+ from python.org

### Issue: Flutter not found
**Solution**: Install Flutter from flutter.dev/docs/get-started/install

### Issue: No devices found
**Solution**: 
- Connect Android device via USB
- OR start Android emulator: `emulator -avd <name>`
- OR start iOS simulator: `open -a Simulator`

### Issue: Model not found in Flutter
**Solution**: 
```bash
cd "smartcacao ML"
python convert_model.py
# Verify file exists at:
# ../smartcacao/assets/models/best.tflite
```

### Issue: Gradle errors on Android
**Solution**:
```bash
cd smartcacao
flutter clean
flutter pub get
flutter run
```

### Issue: Pod install errors on iOS
**Solution**:
```bash
cd smartcacao/ios
pod deintegrate
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📞 Support

If something doesn't work:
1. Check the error message carefully
2. Search this checklist for the issue
3. Review QUICK_REFERENCE.md
4. Check INTEGRATION_GUIDE.md
5. Look at TROUBLESHOOTING sections in individual README files

---

## ✅ Sign Off

Once everything is working:

**System Ready**: _____ (today's date)
**By**: _____ (your name)

You can now:
- ✅ Prepare your cacao dataset
- ✅ Train the ML model
- ✅ Test the Flutter app
- ✅ Deploy to mobile
- ✅ Complete your capstone project!

---

**Last Updated**: February 26, 2026
**Version**: 1.0
**Status**: Complete and Verified
