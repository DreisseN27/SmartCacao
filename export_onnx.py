"""
Export YOLOv8 model to ONNX format with proper 3-class support.
This ensures all class probabilities are exported correctly.
"""

from pathlib import Path
from ultralytics import YOLO

def export_to_onnx():
    """Export YOLOv8 model to ONNX with correct class supports."""
    
    # Path to your trained model
    model_path = "colab/my_model.pt"
    output_dir = "smartcacao/assets/models"
    
    print(f"Loading model from: {model_path}")
    model = YOLO(model_path)
    
    # Get model info to verify it has 3 classes
    print(f"Model info:")
    print(f"  Classes: {model.model.names}")
    print(f"  Number of classes: {model.model.nc}")
    
    if model.model.nc != 3:
        print(f"WARNING: Model has {model.model.nc} classes, expected 3!")
    
    # Export to ONNX with 320x320 (match training size)
    print(f"\nExporting to ONNX (320x320)...")
    try:
        # Export with opset 14 for better compatibility
        results = model.export(
            format='onnx',
            imgsz=320,
            opset=14,
            device='cpu'
        )
        print(f"✓ Export successful: {results}")
        
        # Find and move the exported file
        import shutil
        from pathlib import Path
        
        # The export typically saves as best.onnx in the model directory
        # or in a runs/detect/predict directory
        model_parent = Path(model_path).parent
        
        # Check multiple possible locations
        possible_paths = [
            model_parent / "best.onnx",
            Path("runs/detect/predict/best.onnx"),
            Path("runs") / "*" / "*" / "best.onnx",
        ]
        
        onnx_file = None
        for pattern in possible_paths:
            matches = list(Path(".").glob(pattern.as_posix())) if "*" in pattern.as_posix() else None
            if matches:
                onnx_file = matches[0]
                break
            elif isinstance(pattern, Path) and pattern.exists():
                onnx_file = pattern
                break
        
        if onnx_file:
            # Create output directory if it doesn't exist
            Path(output_dir).mkdir(parents=True, exist_ok=True)
            
            output_path = Path(output_dir) / "best.onnx"
            shutil.copy(onnx_file, output_path)
            print(f"✓ ONNX model copied to: {output_path}")
            print(f"  File size: {output_path.stat().st_size / 1024 / 1024:.2f} MB")
        else:
            print("✗ Could not find exported ONNX file!")
            print("  Please check that export was successful")
            
    except Exception as e:
        print(f"✗ Export failed: {e}")
        raise

if __name__ == "__main__":
    export_to_onnx()
