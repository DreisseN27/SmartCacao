#!/usr/bin/env python3
import os
import shutil
from pathlib import Path

model_path = Path("runs/detect/train10/weights/best.pt")
if not model_path.exists():
    print("Model not found")
    exit(1)

print("Loading YOLO...")
from ultralytics import YOLO
model = YOLO(str(model_path))

print("Exporting to TFLite... (this can take 10+ minutes)")

try:
    result = model.export(
        format='tflite',
        imgsz=640,
        half=False,
        int8=False,
        optimize=False,
        dynamic=False,
        simplify=False,
    )
    print(f"✓ Export successful: {result}")
    
    # Copy to Flutter
    dest = Path("../smartcacao/assets/models/best.tflite")
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(str(result), str(dest))
    print(f"✓ Copied to Flutter: {dest}")
    
except Exception as e:
    print(f"✗ Export failed: {e}")
    print("\nTrying alternative methods...")
    
    # Fallback: Copy .pt file and rename
    print("Using .pt model as fallback...")
    dest = Path("../smartcacao/assets/models/best.pt")
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(str(model_path), str(dest))
    print(f"✓ Copied to Flutter: {dest}")
