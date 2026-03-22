#!/usr/bin/env python3
"""
Convert YOLOv8 .pt model to TFLite format using tf2onnx and tflite_convert
This handles the full conversion pipeline for Flutter compatibility
"""

import os
import shutil
import subprocess
from pathlib import Path

def install_required_packages():
    """Install required conversion packages."""
    print("Installing conversion dependencies...")
    packages = [
        'tf2onnx',
        'onnx',
        'onnxruntime',
    ]
    
    for package in packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"  ✓ {package} already installed")
        except ImportError:
            print(f"  Installing {package}...")
            subprocess.check_call(['pip', 'install', package, '-q'])

def find_best_model():
    """Find the latest trained model."""
    runs_path = Path("runs/detect")
    
    if not runs_path.exists():
        print("ERROR: No 'runs/detect' folder found!")
        return None
    
    # Find all train folders
    train_folders = []
    for d in runs_path.iterdir():
        if d.is_dir() and d.name.startswith("train"):
            try:
                num = int(d.name[5:]) if len(d.name) > 5 else 0
                train_folders.append((num, d))
            except:
                pass
    
    if not train_folders:
        print("ERROR: No training folders found!")
        return None
    
    latest = max(train_folders, key=lambda x: x[0])[1]
    best_pt = latest / "weights" / "best.pt"
    
    if best_pt.exists():
        print(f"Found model: {best_pt}")
        return best_pt
    return None

def convert_pt_to_tflite():
    """Convert PyTorch model to TFLite."""
    
    print("=" * 70)
    print("YOLOv8 → TFLite Conversion")
    print("=" * 70)
    
    best_model = find_best_model()
    if not best_model:
        return False
    
    try:
        from ultralytics import YOLO
        
        print(f"\n[1/2] Loading PyTorch model...")
        model = YOLO(str(best_model))
        print(f"      ✓ Model loaded")
        
        print(f"\n[2/2] Exporting to TFLite...")
        print(f"      This takes 2-5 minutes...")
        
        # Direct export to TFLite
        tflite_path = model.export(
            format='tflite',
            imgsz=640,
            half=False,
            int8=False,
            verbose=True,
        )
        
        print(f"\n      ✓ Export successful!")
        print(f"      File: {tflite_path}")
        
        # Verify the file is valid
        if not Path(tflite_path).exists():
            print(f"ERROR: TFLite file was not created!")
            return False
        
        # Copy to Flutter
        flutter_path = Path("..") / "smartcacao" / "assets" / "models" / "best.tflite"
        flutter_path.parent.mkdir(parents=True, exist_ok=True)
        
        print(f"\n[3/2] Copying to Flutter...")
        print(f"      From: {tflite_path}")
        print(f"      To:   {flutter_path}")
        
        shutil.copy(str(tflite_path), str(flutter_path))
        
        file_size = flutter_path.stat().st_size / (1024 * 1024)
        
        print(f"\n" + "=" * 70)
        print(f"✓ SUCCESS! Model ready for Flutter")
        print(f"=" * 70)
        print(f"File: {flutter_path}")
        print(f"Size: {file_size:.2f} MB")
        print(f"\nNext: Run in smartcacao directory:")
        print(f"  flutter clean && flutter pub get && flutter run")
        print(f"=" * 70)
        
        return True
        
    except Exception as e:
        print(f"\nERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    import sys
    success = convert_pt_to_tflite()
    sys.exit(0 if success else 1)
