import os
import sys
import torch
import torch.nn as nn
from ultralytics import YOLO
import yaml

# ============================================================================ #
# CBAM (Convolutional Block Attention Module) Implementation
# ============================================================================ #

class ChannelAttention(nn.Module):
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
    def __init__(self, in_channels, reduction=16, kernel_size=7):
        super().__init__()
        self.ca = ChannelAttention(in_channels, reduction)
        self.sa = SpatialAttention(kernel_size)

    def forward(self, x):
        x = self.ca(x)
        x = self.sa(x)
        return x

# ============================================================================ #
# MobileNet Backbone (lightweight)
# ============================================================================ #

class MobileNetBackbone(nn.Module):
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
                nn.ReLU6(inplace=True)
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

# ============================================================================ #
# Register custom modules for YOLO
# ============================================================================ #
import ultralytics.nn.tasks as tasks
tasks.MobileNetBackbone = MobileNetBackbone
tasks.CBAM = CBAM

# ============================================================================ #
# Training
# ============================================================================ #

def is_gpu_available():
    return torch.cuda.is_available()

def verify_output_channels(model_path, img_size=320):
    """Verify model has 8 output channels (nc=4)"""
    try:
        import onnx
    except ImportError:
        print("\n" + "="*60)
        print("Installing onnx for output verification...")
        print("="*60)
        os.system("pip install onnx -q")
        import onnx
    
    try:
        print("\n" + "="*60)
        print("Verifying Output Channels...")
        print("="*60)
        
        # Load trained model
        model = YOLO(model_path)
        
        # Export to ONNX
        print("📤 Exporting model to ONNX format...")
        model.export(format="onnx", imgsz=img_size)
        
        # Get ONNX model path
        onnx_path = model_path.replace('.pt', '.onnx')
        
        # Load and inspect ONNX model
        if os.path.exists(onnx_path):
            onnx_model = onnx.load(onnx_path)
            outputs = onnx_model.graph.output
            
            if outputs:
                output_shape = outputs[0].type.tensor_type.shape.dim
                shape = [dim.dim_value for dim in output_shape]
                
                print(f"\n✓ ONNX Model Output Shape: {shape}")
                
                if len(shape) >= 2 and shape[1] == 8:
                    print("✅ SUCCESS! Model has 8 output channels (nc=4 confirmed)")
                    print("   Channels: [x, y, w, h, objectness, class0, class1, class2]")
                    return True
                else:
                    print(f"⚠️  WARNING! Expected 8 channels, got {shape[1] if len(shape) > 1 else 'unknown'}")
                    return False
            else:
                print("⚠️  Could not read ONNX output shape")
                return False
        else:
            print(f"⚠️  ONNX file not found at {onnx_path}")
            return False
            
    except Exception as e:
        print(f"❌ Error verifying output channels: {str(e)}")
        return False

def main():
    MODEL = "yolov8s.pt"  # base model
    DATA_CONFIG = "data.yaml"
    EPOCHS = 60
    IMG_SIZE = 320
    BATCH_SIZE = 16 if is_gpu_available() else 4

    if not os.path.exists(DATA_CONFIG):
        print(f"ERROR: {DATA_CONFIG} not found!")
        sys.exit(1)

    print("="*60)
    print("SmartCacao Training (YOLOv8 + MobileNet + CBAM)")
    print("="*60)

    # Load YOLOv8 model
    model = YOLO(MODEL)

    # Start training
    model.train(
        data=DATA_CONFIG,
        epochs=EPOCHS,
        imgsz=IMG_SIZE,
        batch=BATCH_SIZE,
        device=0 if is_gpu_available() else "cpu",
        optimizer='SGD',
        lr0=0.001,
        lrf=0.0001,
        momentum=0.937,
        weight_decay=0.0005,
        hsv_h=0.015,
        hsv_s=0.7,
        hsv_v=0.4,
        degrees=15,
        translate=0.1,
        scale=0.5,
        flipud=0.5,
        fliplr=0.5,
        mosaic=1.0,
        save=True,
        save_period=10,
        val=True,
        verbose=True
    )

    print("\nTraining completed! Model saved in runs/detect/train/weights/best.pt")
    
    # Verify 8 output channels
    best_model_path = "runs/detect/train/weights/best.pt"
    if os.path.exists(best_model_path):
        verify_output_channels(best_model_path, img_size=IMG_SIZE)
    else:
        print(f"\n⚠️  Best model not found at {best_model_path}")

if __name__ == "__main__":
    main()