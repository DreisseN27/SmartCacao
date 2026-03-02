"""
Model conversion script to convert YOLOv8 models to various formats
suitable for mobile deployment (TFLite, ONNX, CoreML)
"""

import os
import sys
import argparse
from pathlib import Path
from ultralytics import YOLO

def convert_model(model_path, output_dir="./models", formats=None):
    """
    Convert YOLOv8 model to multiple formats.
    
    Args:
        model_path: Path to the trained .pt model
        output_dir: Directory to save converted models
        formats: List of formats to export ['tflite', 'onnx', 'coreml']
    """
    
    if formats is None:
        formats = ['tflite', 'onnx']
    
    print("=" * 60)
    print("SmartCacao - Model Conversion Script")
    print("=" * 60)
    
    # Verify model exists
    if not os.path.exists(model_path):
        print(f"ERROR: Model file not found: {model_path}")
        return False
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    try:
        print(f"\nLoading model from: {model_path}")
        model = YOLO(model_path)
        
        print(f"\nModel loaded successfully!")
        print(f"Converting to formats: {', '.join(formats)}")
        print("-" * 60)
        
        # Export for Flutter (TFLite)
        if 'tflite' in formats:
            print("\n[1/3] Exporting to TFLite format...")
            try:
                tflite_path = model.export(
                    format='tflite',
                    imgsz=640,
                    half=False,  # Use full precision for better accuracy
                    int8=False,  # No quantization
                    dynamic=False,
                    simplify=True,
                )
                print(f"✓ TFLite model saved to: {tflite_path}")
                
                # Copy to Flutter assets
                flutter_asset_dir = "../smartcacao/assets/models"
                os.makedirs(flutter_asset_dir, exist_ok=True)
                
                import shutil
                flutter_model_path = os.path.join(flutter_asset_dir, "best.tflite")
                shutil.copy(tflite_path, flutter_model_path)
                print(f"✓ Copied to Flutter assets: {flutter_model_path}")
            except Exception as e:
                print(f"✗ TFLite export failed: {e}")
        
        # Export to ONNX (for testing and deployment)
        if 'onnx' in formats:
            print("\n[2/3] Exporting to ONNX format...")
            try:
                onnx_path = model.export(
                    format='onnx',
                    imgsz=640,
                    simplify=True,
                )
                print(f"✓ ONNX model saved to: {onnx_path}")
            except Exception as e:
                print(f"✗ ONNX export failed: {e}")
        
        # Export to CoreML (for iOS)
        if 'coreml' in formats:
            print("\n[3/3] Exporting to CoreML format...")
            try:
                coreml_path = model.export(
                    format='coreml',
                    imgsz=640,
                )
                print(f"✓ CoreML model saved to: {coreml_path}")
            except Exception as e:
                print(f"✗ CoreML export failed: {e}")
        
        print("\n" + "=" * 60)
        print("Model conversion completed successfully!")
        print("=" * 60)
        
        # Print model information
        print("\nModel Information:")
        print(f"  Input size: 640x640")
        print(f"  Classes: 3 (under_fermented, properly_fermented, over_fermented)")
        print(f"  Output format: YOLOv8 Detection (batch, 84, 8400)")
        
        return True
        
    except Exception as e:
        print(f"\nERROR during conversion: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def list_available_models():
    """List available trained models in the runs directory."""
    runs_dir = Path("runs/detect")
    
    if not runs_dir.exists():
        print("No trained models found in runs/detect/")
        return
    
    print("\nAvailable trained models:")
    for idx, model_dir in enumerate(sorted(runs_dir.iterdir()), 1):
        if model_dir.is_dir():
            weights_dir = model_dir / "weights"
            best_model = weights_dir / "best.pt"
            if best_model.exists():
                print(f"  {idx}. {model_dir.name}")
                print(f"     Path: {best_model}")

def main():
    parser = argparse.ArgumentParser(
        description='Convert YOLOv8 models for mobile deployment'
    )
    parser.add_argument(
        'model',
        nargs='?',
        default=None,
        help='Path to the trained model (e.g., runs/detect/train/weights/best.pt)'
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='List available trained models'
    )
    parser.add_argument(
        '--formats',
        nargs='+',
        default=['tflite', 'onnx'],
        help='Formats to export (tflite, onnx, coreml)'
    )
    parser.add_argument(
        '--output',
        default='./models',
        help='Output directory for converted models'
    )
    
    args = parser.parse_args()
    
    # List available models if requested
    if args.list:
        list_available_models()
        return 0
    
    # If no model specified, try to find the latest one
    if args.model is None:
        runs_dir = Path("runs/detect")
        if runs_dir.exists():
            latest_train = max(
                (d for d in runs_dir.iterdir() if d.name.startswith('train')),
                key=lambda d: d.stat().st_mtime,
                default=None
            )
            if latest_train:
                args.model = str(latest_train / "weights" / "best.pt")
                print(f"Using latest model: {args.model}\n")
        
        if args.model is None:
            print("ERROR: No model specified and no trained models found.")
            print("First train a model using: python train.py")
            print("Then convert it using: python convert_model.py <model_path>")
            list_available_models()
            return 1
    
    # Convert model
    success = convert_model(args.model, args.output, args.formats)
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
