import 'dart:io';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Standard YOLO input size for inference
  static const int modelInputSize = 640;
  
  /// Model normalization constants (ImageNet standard)
  static const List<double> mean = [0.0, 0.0, 0.0];
  static const List<double> std = [1.0, 1.0, 1.0];

  /// Load image from file path
  static Future<img.Image?> loadImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        return null;
      }
      
      final bytes = await imageFile.readAsBytes();
      return img.decodeImage(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Preprocess image for YOLOv8 inference
  static Future<List<List<List<List<double>>>>> preprocessImage(
    String imagePath,
  ) async {
    final image = await loadImage(imagePath);
    if (image == null) {
      throw Exception('Failed to load image: $imagePath');
    }

    // Resize image to model input size with letterboxing (maintains aspect ratio)
    final resized = letterboxResize(image, modelInputSize);

    // Convert to normalized float array [1, 640, 640, 3]
    return imageToTensor(resized);
  }

  /// Resize image with letterboxing (maintains aspect ratio, adds padding)
  static img.Image letterboxResize(img.Image image, int targetSize) {
    final scale = (targetSize / 
        (image.width > image.height ? image.width : image.height));
    
    final newWidth = (image.width * scale).toInt();
    final newHeight = (image.height * scale).toInt();

    // Resize image
    var resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // Create canvas with target size and gray background
    final canvas = img.Image(
      width: targetSize,
      height: targetSize,
    );
    
    // Fill with gray color
    img.fillRect(
      canvas,
      x1: 0,
      y1: 0,
      x2: targetSize,
      y2: targetSize,
      color: img.ColorRgba8(114, 114, 114, 255),
    );

    // Calculate position to center the resized image
    final dx = ((targetSize - newWidth) / 2).toInt();
    final dy = ((targetSize - newHeight) / 2).toInt();

    // Composite resized image onto canvas
    return img.compositeImage(canvas, resized, dstX: dx, dstY: dy);
  }

  /// Convert preprocessed image to normalized float tensor
  static List<List<List<List<double>>>> imageToTensor(img.Image image) {
    final tensor = List.generate(
      1,
      (_) => List.generate(
        image.height,
        (y) => List.generate(
          image.width,
          (x) {
            final pixel = image.getPixelSafe(x, y);
            // Normalize pixel values [0, 255] -> [0.0, 1.0]
            return [
              pixel.r.toDouble() / 255.0, // Red channel
              pixel.g.toDouble() / 255.0, // Green channel
              pixel.b.toDouble() / 255.0, // Blue channel
            ];
          },
        ),
      ),
    );

    // Reshape from [1, H, W, 3] to the expected input format
    // This depends on your TFLite model's expected input shape
    return tensor;
  }

  /// Parse YOLOv8 detection output (batch, 84, 8400)
  /// Output format: [x, y, w, h, conf, class0_conf, class1_conf, class2_conf, ...]
  static List<Map<String, dynamic>> parseDetections(
    List<dynamic> output, {
    double confidenceThreshold = 0.5,
    List<String> classNames = const [
      'under_fermented',
      'properly_fermented',
      'over_fermented'
    ],
  }) {
    final detections = <Map<String, dynamic>>[];

    try {
      // Handle different output formats
      if (output.isEmpty) return detections;

      // Get predictions from output
      final predictions = output[0] as List?;
      if (predictions == null) return detections;

      for (int i = 0; i < predictions.length; i++) {
        final prediction = predictions[i];
        if (prediction is! List || prediction.length < 5) continue;

        // Extract values
        final x = (prediction[0] as num).toDouble();
        final y = (prediction[1] as num).toDouble();
        final w = (prediction[2] as num).toDouble();
        final h = (prediction[3] as num).toDouble();
        final confidence = (prediction[4] as num).toDouble();

        // Skip if confidence is below threshold
        if (confidence < confidenceThreshold) continue;

        // Extract class scores and find the best class
        int classIndex = 0;
        double maxClassConf = 0.0;

        if (prediction.length > 5) {
          for (int j = 5; j < prediction.length && j - 5 < classNames.length; j++) {
            final classConf = (prediction[j] as num).toDouble();
            if (classConf > maxClassConf) {
              maxClassConf = classConf;
              classIndex = j - 5;
            }
          }
        }

        // Calculate bounding box coordinates
        final left = x - w / 2;
        final top = y - h / 2;
        final right = x + w / 2;
        final bottom = y + h / 2;

        detections.add({
          'x': x,
          'y': y,
          'width': w,
          'height': h,
          'confidence': confidence,
          'classIndex': classIndex,
          'className': classNames[classIndex],
          'classConfidence': maxClassConf,
          'boundingBox': {
            'left': left,
            'top': top,
            'right': right,
            'bottom': bottom,
          },
        });
      }
    } catch (e) {
      // Error parsing detections - return parsed results
    }

    return detections;
  }

  /// Get fermentation status from detected class
  static String getFermentationStatus(String className) {
    switch (className) {
      case 'under_fermented':
        return 'Under Fermented - Requires More Fermentation Time';
      case 'properly_fermented':
        return 'Properly Fermented - Ready for Processing';
      case 'over_fermented':
        return 'Over Fermented - Quality Degraded';
      default:
        return 'Unknown Status';
    }
  }

  /// Get color for displaying status based on fermentation level
  static int getStatusColor(String className) {
    switch (className) {
      case 'under_fermented':
        return 0xFFFF6B6B; // Red
      case 'properly_fermented':
        return 0xFF51CF66; // Green
      case 'over_fermented':
        return 0xFFFFD43B; // Yellow
      default:
        return 0xFF808080; // Gray
    }
  }
}