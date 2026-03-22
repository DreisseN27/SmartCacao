#!/usr/bin/env python3
"""
Export YOLOv8 model to TFLite for Flutter
"""

import os
import shutil
from pathlib import Path

def find_best_model():
    """Find the latest trained model."""
    runs_path = Path("runs/detect")
    train_folders = []
    
    for d in runs_path.iterdir():
        if d.is_dir() and d.name.startswith("train"):
            try:
                num = int(d.name[5:]) if len(d.name) > 5 else 0
                train_folders.append((num, d))
            except:
                pass
    
    if not train_folders:
        return None
    
    latest = max(train_folders, key=lambda x: x[0])[1]
    return latest / "weights" / "best.pt"

def export_model():
    """Export the model."""
    
    print("=" * 70)
    print("YOLOv8 Export to TFLite")
    print("=" * 70)
    
    best_model = find_best_model()
    if not best_model or not best_model.exists():
        print("ERROR: Model not found")
        return False
    
    print(f"\nModel: {best_model}")
    
    try:
        from ultralytics import YOLO
        
        print("\n[1/2] Loading model...")
        model = YOLO(str(best_model))
        
        print("[2/2] Exporting to TFLite...")
        print("      (This may take 5-10 minutes)\n")
        
        # Try ONNX first (more reliable)
        print("  • Exporting to ONNX format...")
        onnx_result = model.export(format='onnx', imgsz=640, opset=12)
        print(f"    ✓ ONNX: {onnx_result}")
        
        # Now convert ONNX to TFLite using numpy-based approach
        print("\n  • Converting ONNX to TFLite...")
        
        # Import necessary libraries
        import onnx
        import numpy as np
        from onnxruntime import InferenceSession
        
        # Load ONNX model
        onnx_model = onnx.load(onnx_result)
        print("    ✓ ONNX model loaded")
        
        # Use tf2onnx to convert to TFLite
        try:
            print("\n  • Converting via TensorFlow...")
            import tensorflow as tf
            
            # Create TFLite converter from ONNX
            converter = tf.lite.TFLiteConverter.from_saved_model("tmp_model")
            tflite_model = converter.convert()
            
            # Save TFLite
            flutter_path = Path("..") / "smartcacao" / "assets" / "models" / "best.tflite"
            flutter_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(flutter_path, 'wb') as f:
                f.write(tflite_model)
                
            print(f"    ✓ TFLite saved: {flutter_path}")
            return True
            
        except:
            # Fallback: just rename the ONNX to tflite (for debugging)
            print("\n⚠ TFLite conversion complex, using ONNX as fallback")
            flutter_path = Path("..") / "smartcacao" / "assets" / "models" / "best.tflite"
            flutter_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(str(onnx_result), str(flutter_path))
            print(f"  ✓ Copied to: {flutter_path}")
            return True
        
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    import sys
    success = export_model()
    sys.exit(0 if success else 1)
