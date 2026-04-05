# Quick Start Commands

## Navigate to project
```bash
cd "c:\Users\drei\Documents\BSIT Projects\MOBILE\Capstone2.2\smartcacao"
```

## Clean and prepare
```bash
flutter clean
flutter pub get
```

## Build for Android

### Build APK (Debug - Fastest for development)
```bash
flutter build apk --debug
```

### Build APK (Release - Optimized, for distribution)
```bash
flutter build apk --release
```

### Build App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```

## Run on Device/Emulator

### Automatic build and run (fastest for development)
```bash
flutter run
```

### Run in verbose mode (for debugging)
```bash
flutter run -v
```

### Run in release mode
```bash
flutter run --release
```

## Android Studio Commands

### Create Android project (one-time)
```bash
flutter create --platforms android .
```

### Open in Android Studio
```bash
flutter run --debug
# Then switch to Android Studio IDE tab
```

## Check Connected Devices
```bash
flutter devices
```

## View Device Logs
```bash
flutter logs
```

## Full Build Steps (from scratch)
```bash
cd smartcacao
flutter clean
flutter pub get
flutter build apk --debug
flutter run
```

## Troubleshooting Commands

### Check Flutter setup
```bash
flutter doctor
```

### Fix pub cache
```bash
flutter pub cache repair
```

### Check build errors
```bash
flutter build apk --debug -v
```

### Get logs from device
```bash
flutter logs --v
```

---

**Tip**: After the first `flutter run`, you can just use `flutter run` for subsequent builds - it's much faster!
