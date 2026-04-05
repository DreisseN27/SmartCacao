"""
Manual PyTorch to ONNX conversion that preserves all class probabilities.
This bypasses the ultralytics export issues.
"""

import torch
import onnx
from pathlib import Path

def convert_pytorch_to_onnx_manual():
    """Convert PyTorch YOLOv8 model to ONNX with all 3 classes intact."""
    
    model_path = "colab/my_model.pt"
    output_path = "smartcacao/assets/models/best.onnx"
    
    print(f"Loading PyTorch model from: {model_path}")
    
    # Use ultralytics to load the full model
    from ultralytics import YOLO
    model_obj = YOLO(model_path)
    model = model_obj.model
    
    print(f"Model type: {type(model)}")
    print(f"Model classes: {model.nc if hasattr(model, 'nc') else 'unknown'}")
    print(f"Model names: {model.names if hasattr(model, 'names') else 'unknown'}")
    
    model.eval()
    
    # Create dummy input (1, 3, 320, 320)
    dummy_input = torch.randn(1, 3, 320, 320)
    
    print(f"\nExporting to ONNX...")
    print(f"  Input shape: {dummy_input.shape}")
    
    # Test forward pass first
    with torch.no_grad():
        output = model(dummy_input)
        if isinstance(output, (list, tuple)):
            output = output[0]
        print(f"  Output shape: {output.shape}")
    
    # Export to ONNX
    try:
        torch.onnx.export(
            model,
            dummy_input,
            output_path,
            input_names=['images'],
            output_names=['output0'],
            opset_version=14,
            do_constant_folding=True,
            verbose=False
        )
        print(f"\n✓ ONNX export successful!")
        print(f"  Saved to: {output_path}")
        
        # Verify the exported model
        onnx_model = onnx.load(output_path)
        onnx.checker.check_model(onnx_model)
        
        print(f"\n✓ ONNX model verified!")
        
        # Get output shape
        for output in onnx_model.graph.output:
            shape = [d.dim_value for d in output.type.tensor_type.shape.dim]
            total_elements = 1
            for s in shape:
                total_elements *= s
            print(f"  Output shape: {shape}")
            print(f"  Total elements: {total_elements}")
        
        # Check file size
        file_size = Path(output_path).stat().st_size / 1024 / 1024
        print(f"  File size: {file_size:.2f} MB")
        
        return True
        
    except Exception as e:
        print(f"✗ Export failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = convert_pytorch_to_onnx_manual()
    exit(0 if success else 1)
