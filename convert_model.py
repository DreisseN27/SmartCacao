"""
Script to convert PyTorch YOLOv8 model to TFlite format for mobile deployment
Usage: python convert_model.py
"""

import os
from pathlib import Path

def convert_yolov8_to_tflite(pytorch_model_path, tflite_output_path):
    """
    Convert YOLOv8 PyTorch model to TFlite format using ultralytics
    
    Args:
        pytorch_model_path: Path to the .pt model file
        tflite_output_path: Path where to save the .tflite file
    """
    print(f"Loading YOLOv8 model from: {pytorch_model_path}")
    
    try:
        from ultralytics import YOLO
        
        # Load model using ultralytics (handles state_dict or full model)
        model = YOLO(pytorch_model_path)
        print("✓ Model loaded successfully")
        
        # Export to TFlite with 320x320 (matching training size)
        print(f"Converting to TFlite (320x320) and saving to: {tflite_output_path}")
        results = model.export(format='tflite', imgsz=320, device='cpu')
        print(f"✓ Model converted to TFlite: {results}")
        
        # The export creates the file in a runs/ subdirectory, we need to move it
        import shutil
        
        # YOLOv8 export saves to runs/detect/predict/ by default
        # We need to find and move it to our target location
        
        # First, try to find the TFlite model that was created
        import glob
        tflite_files = glob.glob((Path(pytorch_model_path).parent / "*.tflite").as_posix())
        
        if tflite_files:
            source = tflite_files[0]
            print(f"Found TFlite file: {source}")
            shutil.copy(source, tflite_output_path)
            print(f"✓ TFlite file copied to: {tflite_output_path}")
        else:
            # Try the standard export location
            runs_path = Path(pytorch_model_path).parent.parent / "runs/detect/predict" / "best.tflite"
            if runs_path.exists():
                shutil.copy(runs_path, tflite_output_path)
                print(f"✓ TFlite file copied from runs directory to: {tflite_output_path}")
            else:
                # Look recursively
                search_path = Path(pytorch_model_path).parent.parent
                for tflite_file in search_path.rglob("*.tflite"):
                    print(f"Found TFlite file at: {tflite_file}")
                    if "best" in str(tflite_file) or "runs" in str(tflite_file):
                        shutil.copy(tflite_file, tflite_output_path)
                        print(f"✓ TFlite file copied to: {tflite_output_path}")
                        break
        
        # Verify the TFlite model
        if Path(tflite_output_path).exists():
            print("✓ TFlite file verified to exist")
            
            # Print file sizes
            pt_size = os.path.getsize(pytorch_model_path) / 1024 / 1024
            tflite_size = os.path.getsize(tflite_output_path) / 1024 / 1024
            print(f"\nFile sizes:")
            print(f"  PyTorch (.pt):  {pt_size:.2f} MB")
            print(f"  TFlite (.tflite):   {tflite_size:.2f} MB")
            
            return True
        else:
            print("✗ TFlite file was not found after conversion")
            return False
            
    except ImportError:
        print("✗ Error: ultralytics not installed")
        print("  Install with: pip install ultralytics")
        return False
    except Exception as e:
        print(f"✗ Error during conversion: {e}")
        print(f"  Error type: {type(e).__name__}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    # Get script directory
    script_dir = Path(__file__).parent.absolute()
    
    # Paths - use the best.pt from training, not my_model.pt
    pytorch_model = script_dir / "colab" / "train" / "weights" / "best.pt"
    tflite_model = script_dir / "smartcacao" / "assets" / "models" / "best.tflite"
    
    print("=" * 70)
    print("YOLOv8 to TFlite Model Conversion (320x320)")
    print("=" * 70)
    
    # Check if pytorch model exists
    if not pytorch_model.exists():
        print(f"✗ Error: PyTorch model not found at {pytorch_model}")
        print("  Make sure the file exists at: colab/train/weights/best.pt")
        exit(1)
    
    # Create output directory if needed
    tflite_model.parent.mkdir(parents=True, exist_ok=True)
    
    # Convert
    success = convert_yolov8_to_tflite(str(pytorch_model), str(tflite_model))
    
    print("=" * 70)
    if success:
        print("✓ Conversion completed successfully!")
        print(f"✓ TFlite model ready at: {tflite_model}")
        print("\nNext steps:")
        print("  1. Rebuild the Flutter app: flutter clean && flutter build apk --debug")
        print("  2. Run on device: flutter run")
    else:
        print("✗ Conversion failed. Check errors above.")
        exit(1)
