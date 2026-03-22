#!/usr/bin/env python3
"""
Convert YOLOv8 .pt model to TFLite format for Flutter
"""

import os
import shutil
from pathlib import Path

def find_best_model():
    """Find the latest trained model."""
    runs_path = Path("runs/detect")
    
    if not runs_path.exists():
        print("ERROR: No 'runs/detect' folder found!")
        return None
    
    # Find all train folders and sort by number to get the latest
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
    
    print(f"Found model at: {best_pt}")
    if best_pt.exists():
        return best_pt
    return None

def export_tflite():
    """Export YOLOv8 model to TFLite."""
    
    print("=" * 70)
    print("SmartCacao - Model Conversion (PyTorch → TFLite)")
    print("=" * 70)
    
    best_model = find_best_model()
    if not best_model:
        return False
    
    try:
        from ultralytics import YOLO
        
        print(f"\n[1/2] Loading model: {best_model}")
        model = YOLO(str(best_model))
        
        print(f"[2/2] Converting to TFLite...")
        print(f"      This may take 2-5 minutes...\n")
        
        # Export to TFLite using ultralytics built-in export
        tflite_path = model.export(
            format='tflite',
            imgsz=640,
            half=False,
            int8=False,
        )
        
        print(f"\n✓ Conversion successful!")
        print(f"   Temporary file: {tflite_path}")
        
        # Copy to Flutter assets
        flutter_models_dir = Path("..") / "smartcacao" / "assets" / "models"
        flutter_models_dir.mkdir(parents=True, exist_ok=True)
        
        flutter_model_path = flutter_models_dir / "best.tflite"
        
        print(f"\n[3/2] Copying to Flutter assets...")
        print(f"      From: {tflite_path}")
        print(f"      To:   {flutter_model_path}")
        
        shutil.copy(str(tflite_path), str(flutter_model_path))
        
        # Get file size
        file_size = flutter_model_path.stat().st_size / (1024 * 1024)
        
        print(f"\n" + "=" * 70)
        print(f"✓ Model ready for Flutter!")
        print(f"=" * 70)
        print(f"\n📁 Model file: {flutter_model_path}")
        print(f"📊 Size: {file_size:.2f} MB")
        print(f"\nNext steps:")
        print(f"  1. Run in smartcacao directory:")
        print(f"     flutter clean")
        print(f"     flutter pub get")
        print(f"     flutter run")
        print(f"\n" + "=" * 70)
        
        return True
        
    except Exception as e:
        print(f"\n✗ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    import sys
    success = export_tflite()
    sys.exit(0 if success else 1)
