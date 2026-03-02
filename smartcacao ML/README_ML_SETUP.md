# SmartCacao - ML Setup Guide

## Project Overview
This is a cacao bean fermentation detection system using YOLOv8 with MobileNet+CBAM architecture. The system classifies cacao beans into three fermentation states:
- **Under-Fermented**: Requires more fermentation time
- **Properly-Fermented**: Ready for processing
- **Over-Fermented**: Quality degraded

## Prerequisites
- Python 3.8+
- pip (Python package manager)
- Git (optional, for version control)

## Setup Instructions

### 1. Create a Python Virtual Environment
```bash
python -m venv venv
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

### 2. Install Required Packages
```bash
pip install -r requirements.txt
```

If `requirements.txt` doesn't exist, run:
```bash
pip install ultralytics opencv-python numpy pillow pyyaml
```

## Dataset Preparation

### Dataset Structure
Organize your cacao dataset in YOLO format:
```
dataset/
├── images/
│   ├── train/
│   │   ├── image1.jpg
│   │   ├── image2.jpg
│   │   └── ...
│   └── val/
│       ├── image3.jpg
│       └── ...
└── labels/
    ├── train/
    │   ├── image1.txt
    │   ├── image2.txt
    │   └── ...
    └── val/
        ├── image3.txt
        └── ...
```

### Label Format
Each `.txt` file contains one line per object:
```
<class_id> <x_center> <y_center> <width> <height>
```

Class IDs:
- `0`: under_fermented
- `1`: properly_fermented
- `2`: over_fermented

Coordinates are normalized (0-1) relative to image dimensions.

### Example with Roboflow
1. Create a dataset on [Roboflow](https://roboflow.com/)
2. Import your images and annotate them
3. Export in "YOLO v8" format
4. Download and extract to the `dataset/` folder

## Training

### Start Training
```bash
python train.py
```

The script will:
- Load YOLOv8 nano model
- Train on your dataset for 100 epochs
- Save best model to `runs/detect/train/weights/best.pt`
- Validate model performance
- Export to multiple formats (TFLITE, ONNX)

### Training Parameters
Edit `train.py` to adjust:
- `EPOCHS`: Number of training epochs (default: 100)
- `IMG_SIZE`: Input image size (default: 640)
- `BATCH_SIZE`: Batch size (default: 16)
- `PATIENCE`: Early stopping patience (default: 20)

### With GPU
The script automatically detects and uses GPU if available. For CPU-only:
```python
# In train.py, modify the device parameter:
model.train(
    # ... other params ...
    device='cpu'
)
```

## Model Conversion

### Auto-Convert (Recommended)
After training, automatically convert the model:
```bash
python convert_model.py
```

This will:
1. Find the latest trained model
2. Convert to TFLite format
3. Convert to ONNX format
4. Copy TFLite to Flutter assets

### Manual Conversion
```bash
# List available models
python convert_model.py --list

# Convert specific model
python convert_model.py runs/detect/train/weights/best.pt --formats tflite onnx
```

## Model Evaluation

### Validate Model
```python
from ultralytics import YOLO

model = YOLO('runs/detect/train/weights/best.pt')
results = model.val()
```

### Test on Image
```python
from ultralytics import YOLO

model = YOLO('runs/detect/train/weights/best.pt')
results = model.predict(source='path/to/image.jpg', conf=0.5)
```

## Exporting Models

The converted TFLite model is automatically copied to:
```
../smartcacao/assets/models/best.tflite
```

### Model Export Formats
- **TFLite (.tflite)**: For mobile deployment on Flutter
- **ONNX (.onnx)**: For cross-platform deployment and testing
- **CoreML (.mlmodel)**: For native iOS apps

## Flutter Integration

### Step 1: Copy Model
The `convert_model.py` script automatically copies the converted TFLite model to:
```
smartcacao/assets/models/best.tflite
```

### Step 2: Install Flutter Dependencies
```bash
cd ../smartcacao
flutter pub get
```

### Step 3: Run Flutter App
```bash
flutter run
```

## Performance Optimization

### Model Size
- TFLite model: ~10-15 MB
- ONNX model: ~20-25 MB

### Inference Speed
- Expected latency: 100-300ms per image on mobile
- Batch processing supported for multiple beans

### Accuracy
- mAP@50: ~85-92% (depends on dataset quality)
- Confidence threshold: 0.5

## Troubleshooting

### Common Issues

**Issue: "CUDA out of memory"**
- Reduce `BATCH_SIZE` in `train.py`
- Use `--device cpu` for CPU-only training

**Issue: Low accuracy**
- Increase training `EPOCHS`
- Ensure dataset has balanced classes
- Augment data with `--augment`

**Issue: Model not found in Flutter**
- Run `python convert_model.py` in ML folder
- Verify `assets/models/best.tflite` exists
- Run `flutter pub get` again

**Issue: Inference too slow**
- Use quantization: `int8=True` in `convert_model.py`
- Reduce image input size

## Additional Resources

- [YOLOv8 Documentation](https://github.com/ultralytics/ultralytics)
- [TensorFlow Lite Guide](https://www.tensorflow.org/lite)
- [Flutter Camera Plugin](https://pub.dev/packages/camera)
- [TFLite Flutter Plugin](https://pub.dev/packages/tflite_flutter)

## Dataset Tips

1. **Data Collection**
   - Capture images from multiple angles
   - Use consistent lighting
   - Include various cacao bean sizes

2. **Annotation**
   - Label beans accurately with bounding boxes
   - Ensure correct fermentation class labels
   - Remove duplicate/unclear images

3. **Data Augmentation**
   - Rotation: ±10 degrees
   - Brightness: ±20%
   - Horizontal flip: 50%
   - Scale: 0.8-1.2x

4. **Train/Val Split**
   - 80% training data
   - 20% validation data
   - Maintain class balance

## Model Architecture

### YOLOv8 Nano (Mobile)
- Lightweight: ~6M parameters
- Fast inference: 100-300ms
- Suitable for mobile devices
- Pre-trained on COCO dataset

### Enhancement: MobileNet+CBAM
- MobileNet backbone for efficiency
- CBAM (Convolutional Block Attention Module) for precision
- Optimized for feature extraction
- Better performance on small objects (cacao beans)

## Next Steps

1. ✅ Prepare your dataset
2. ✅ Run `python train.py`
3. ✅ Run `python convert_model.py`
4. ✅ Test in Flutter app
5. ✅ Deploy to mobile devices

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review training metrics in `runs/detect/train/`
3. Validate dataset format
4. Check Flutter logs with `flutter logs`

---
**SmartCacao** - Capstone Project for Cacao Bean Fermentation Detection
