import os
import sys
from ultralytics import YOLO
from pathlib import Path

def main():
    """Train YOLOv8 model for cacao bean fermentation detection."""
    
    # Configuration
    MODEL_NAME = "yolov8n"  # nano model for mobile deployment
    DATASET_CONFIG = "cacao_dataset.yaml"
    EPOCHS = 100
    IMG_SIZE = 640
    BATCH_SIZE = 16
    PATIENCE = 20  # Early stopping patience
    
    print("=" * 60)
    print("SmartCacao - YOLOv8 Training Script")
    print("=" * 60)
    
    # Verify dataset config exists
    if not os.path.exists(DATASET_CONFIG):
        print(f"ERROR: Dataset config '{DATASET_CONFIG}' not found!")
        sys.exit(1)
    
    # Verify dataset path exists
    with open(DATASET_CONFIG) as f:
        import yaml
        config = yaml.safe_load(f)
    
    dataset_path = config.get('path', 'dataset')
    if not os.path.exists(dataset_path):
        print(f"WARNING: Dataset path '{dataset_path}' not found.")
        print("Download your cacao dataset and organize it according to YOLO format:")
        print(f"  {dataset_path}/")
        print(f"    images/train/")
        print(f"    images/val/")
        print(f"    labels/train/")
        print(f"    labels/val/")
    
    try:
        # Load base model
        print(f"\nLoading {MODEL_NAME} base model...")
        model = YOLO(f"{MODEL_NAME}.pt")
        
        # Train model
        print(f"\nStarting training for {EPOCHS} epochs...")
        print(f"Batch size: {BATCH_SIZE}, Image size: {IMG_SIZE}")
        print("-" * 60)
        
        results = model.train(
            data=DATASET_CONFIG,
            epochs=EPOCHS,
            imgsz=IMG_SIZE,
            batch=BATCH_SIZE,
            patience=PATIENCE,
            device=0 if is_gpu_available() else "cpu",
            # Optimization settings
            optimizer='SGD',  # or 'Adam'
            lr0=0.01,
            lrf=0.01,
            momentum=0.937,
            weight_decay=0.0005,
            # Data augmentation
            hsv_h=0.015,
            hsv_s=0.7,
            hsv_v=0.4,
            degrees=10,
            translate=0.1,
            scale=0.5,
            flipud=0.5,
            fliplr=0.5,
            # Other settings
            save=True,
            save_period=10,
            val=True,
            verbose=True,
        )
        
        print("-" * 60)
        print(f"\nTraining completed!")
        print(f"Results saved to: runs/detect/train*/")
        
        # Validate model
        print(f"\nValidating model...")
        val_results = model.val()
        
        # Export model for different formats
        print(f"\nExporting model for deployment...")
        model.export(format='onnx', imgsz=IMG_SIZE)
        model.export(format='tflite', imgsz=IMG_SIZE)
        
        print(f"\nModel exports completed!")
        print(f"- ONNX: runs/detect/train*/weights/best.onnx")
        print(f"- TFLite: runs/detect/train*/weights/best.tflite")
        
        return 0
        
    except Exception as e:
        print(f"\nERROR during training: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1

def is_gpu_available():
    """Check if GPU is available."""
    try:
        import torch
        return torch.cuda.is_available()
    except:
        return False

if __name__ == "__main__":
    sys.exit(main())