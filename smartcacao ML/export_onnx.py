#!/usr/bin/env python3
import shutil
from pathlib import Path
from ultralytics import YOLO

model_path = Path("runs/detect/train10/weights/best.pt")
print(f"Exporting {model_path}...")

model = YOLO(str(model_path))

# Export to ONNX (simpler, fewer dependencies)
print("Exporting to ONNX...")
onnx_result = model.export(format='onnx', imgsz=640, opset=12)
print(f"✓ ONNX exported: {onnx_result}")

# Copy to Flutter
dest = Path("../smartcacao/assets/models/best.onnx")
dest.parent.mkdir(parents=True, exist_ok=True)
shutil.copy(str(onnx_result), str(dest))
print(f"✓ Copied to Flutter: {dest}")
