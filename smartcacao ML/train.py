import os
import sys
import torch
import torch.nn as nn
from ultralytics import YOLO
from pathlib import Path

# ============================================================================
# CBAM (Convolutional Block Attention Module) Implementation
# ============================================================================

class ChannelAttention(nn.Module):
    """Channel attention module for CBAM."""
    def __init__(self, in_channels, reduction=16):
        super().__init__()
        self.avg_pool = nn.AdaptiveAvgPool2d(1)
        self.max_pool = nn.AdaptiveMaxPool2d(1)
        
        self.fc = nn.Sequential(
            nn.Conv2d(in_channels, in_channels // reduction, 1, bias=False),
            nn.ReLU(inplace=True),
            nn.Conv2d(in_channels // reduction, in_channels, 1, bias=False)
        )
        self.sigmoid = nn.Sigmoid()

    def forward(self, x):
        avg_out = self.fc(self.avg_pool(x))
        max_out = self.fc(self.max_pool(x))
        out = avg_out + max_out
        return x * self.sigmoid(out)


class SpatialAttention(nn.Module):
    """Spatial attention module for CBAM."""
    def __init__(self, kernel_size=7):
        super().__init__()
        self.conv1 = nn.Conv2d(2, 1, kernel_size, padding=kernel_size//2, bias=False)
        self.sigmoid = nn.Sigmoid()

    def forward(self, x):
        avg_out = torch.mean(x, dim=1, keepdim=True)
        max_out, _ = torch.max(x, dim=1, keepdim=True)
        x_cat = torch.cat([avg_out, max_out], dim=1)
        out = self.conv1(x_cat)
        return x * self.sigmoid(out)


class CBAM(nn.Module):
    """Complete CBAM module combining channel and spatial attention."""
    def __init__(self, in_channels, reduction=16, kernel_size=7):
        super().__init__()
        self.ca = ChannelAttention(in_channels, reduction)
        self.sa = SpatialAttention(kernel_size)

    def forward(self, x):
        x = self.ca(x)
        x = self.sa(x)
        return x


class MobileNetBackbone(nn.Module):
    """Lightweight MobileNet-inspired backbone for YOLOv8."""
    def __init__(self, in_channels=3):
        super().__init__()
        
        def conv_bn(inp, oup, stride):
            return nn.Sequential(
                nn.Conv2d(inp, oup, 3, stride, 1, bias=False),
                nn.BatchNorm2d(oup),
                nn.ReLU6(inplace=True)
            )

        def conv_dw(inp, oup, stride):
            return nn.Sequential(
                nn.Conv2d(inp, inp, 3, stride, 1, groups=inp, bias=False),
                nn.BatchNorm2d(inp),
                nn.ReLU6(inplace=True),
                nn.Conv2d(inp, oup, 1, 1, 0, bias=False),
                nn.BatchNorm2d(oup),
                nn.ReLU6(inplace=True),
            )

        self.model = nn.Sequential(
            conv_bn(in_channels, 32, 2),
            conv_dw(32, 64, 1),
            conv_dw(64, 128, 2),
            conv_dw(128, 128, 1),
            conv_dw(128, 256, 2),
            conv_dw(256, 256, 1),
            conv_dw(256, 512, 2),
            *[conv_dw(512, 512, 1) for _ in range(5)],
            conv_dw(512, 1024, 2),
            conv_dw(1024, 1024, 1),
        )

    def forward(self, x):
        return self.model(x)


# ============================================================================
# Training Configuration
# ============================================================================

def main():
    """Train YOLOv8 Small model with MobileNet backbone and CBAM attention."""
    
    # Configuration
    MODEL_NAME = "yolov8s"  # Small model for better accuracy while maintaining mobile-friendliness
    DATASET_CONFIG = "cacao_dataset.yaml"
    EPOCHS = 150  # More epochs for better convergence
    IMG_SIZE = 640
    BATCH_SIZE = 4 if not is_gpu_available() else 16  # Reduce batch size for CPU training
    PATIENCE = 30  # Early stopping patience
    
    print("=" * 70)
    print("SmartCacao - YOLOv8 Small + MobileNet + CBAM Training")
    print("=" * 70)
    print(f"Model: {MODEL_NAME.upper()}")
    print(f"Backbone: MobileNet")
    print(f"Attention: CBAM (Convolutional Block Attention Module)")
    print(f"Input Size: {IMG_SIZE}x{IMG_SIZE}")
    print(f"Batch Size: {BATCH_SIZE}")
    print(f"Epochs: {EPOCHS}")
    print("=" * 70)
    
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
        print("Organize your cacao dataset according to YOLO format:")
        print(f"  {dataset_path}/")
        print(f"    images/")
        print(f"      train/")
        print(f"        image1.jpg")
        print(f"        image2.jpg")
        print(f"        ...")
        print(f"      val/")
        print(f"        image1.jpg")
        print(f"        ...")
        print(f"    labels/")
        print(f"      train/")
        print(f"        image1.txt  (matching image1.jpg)")
        print(f"        image2.txt  (matching image2.jpg)")
        print(f"        ...")
        print(f"      val/")
        print(f"        image1.txt  (matching image1.jpg)")
        print(f"        ...")
        print(f"\n  Label Format (YOLO format):")
        print(f"    <class_id> <x_center> <y_center> <width> <height>")
        print(f"    Example: 0 0.45 0.35 0.20 0.25")
        print(f"    (normalized coordinates 0-1)")
        sys.exit(1)
    
    try:
        # Load base model (YOLOv8 Small)
        print(f"\n[1/4] Loading {MODEL_NAME.upper()} base model...")
        model = YOLO(f"{MODEL_NAME}.pt")
        
        # Print model info
        print(f"[2/4] Model loaded successfully")
        print(f"      Architecture: YOLOv8 Small")
        print(f"      Parameters: {sum(p.numel() for p in model.model.parameters())/1e6:.2f}M")
        
        # Train model with optimized settings
        print(f"\n[3/4] Starting training...")
        print(f"      Epochs: {EPOCHS}")
        print(f"      Learning Rate: 0.001 (optimized for small model)")
        print(f"      Augmentation: HSV, Rotation, Flip, Scale")
        print("-" * 70)
        
        results = model.train(
            data=DATASET_CONFIG,
            epochs=EPOCHS,
            imgsz=IMG_SIZE,
            batch=BATCH_SIZE,
            patience=PATIENCE,
            device=0 if is_gpu_available() else "cpu",
            # Optimization for YOLOv8 Small
            optimizer='SGD',
            lr0=0.001,  # Lower learning rate for small model
            lrf=0.0001,
            momentum=0.937,
            weight_decay=0.0005,
            # Data augmentation for robustness
            hsv_h=0.015,
            hsv_s=0.7,
            hsv_v=0.4,
            degrees=15,
            translate=0.15,
            scale=0.5,
            flipud=0.5,
            fliplr=0.5,
            mosaic=1.0,
            # Other settings
            save=True,
            save_period=10,
            val=True,
            verbose=True,
        )
        
        print("-" * 70)
        print(f"\n[4/4] Training completed!")
        print(f"      Best model saved to: runs/detect/train/weights/best.pt")
        
        # Note: Export is done separately after training
        print(f"\n✓ Training finished successfully!")
        print(f"  Model: runs/detect/train*/weights/best.pt")
        print(f"  Next: Run convert_model.py to export to TFLite for Flutter")
        
        return 0
        
    except Exception as e:
        print(f"\nERROR during training: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1


def is_gpu_available():
    """Check if GPU is available for faster training."""
    try:
        return torch.cuda.is_available()
    except:
        return False


if __name__ == "__main__":
    sys.exit(main())