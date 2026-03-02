import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/image_utils.dart';
import '../models/detection.dart';

class TFLiteService {
  Interpreter? interpreter;
  bool _isModelLoaded = false;

  /// Load the TFLite model from assets
  Future<bool> loadModel() async {
    try {
      if (_isModelLoaded) return true;
      
      interpreter = await Interpreter.fromAsset(
        'assets/models/best.tflite',
      );
      
      _isModelLoaded = true;
      return true;
    } catch (e) {
      _isModelLoaded = false;
      return false;
    }
  }

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Run inference on an image
  Future<List<Detection>> runInference(String imagePath) async {
    if (interpreter == null || !_isModelLoaded) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      // Preprocess the image
      final imageData = await ImageUtils.preprocessImage(imagePath);
      if (imageData.isEmpty) {
        throw Exception('Failed to preprocess image');
      }

      // Prepare input tensor
      final input = _reshapeInput(imageData);

      // Run inference
      final output = List<dynamic>.filled(1, null);
      interpreter!.run(input, output);

      // Parse output and convert to Detection objects
      final detections = _parseOutput(output[0]);

      return detections;
    } catch (e) {
      rethrow;
    }
  }

  /// Get fermentation analysis from detections
  Future<Map<String, dynamic>> analyzeBeans(String imagePath) async {
    try {
      final detections = await runInference(imagePath);

      if (detections.isEmpty) {
        return {
          'success': false,
          'message': 'No beans detected in the image',
          'detections': [],
          'recommendation': 'Make sure the beans are visible in the image',
        };
      }

      // Calculate statistics
      final fermentationCounts = {
        'under_fermented': 0,
        'properly_fermented': 0,
        'over_fermented': 0,
      };

      double totalConfidence = 0;
      for (final detection in detections) {
        fermentationCounts[detection.label] = 
            (fermentationCounts[detection.label] ?? 0) + 1;
        totalConfidence += detection.confidence;
      }

      final avgConfidence = totalConfidence / detections.length;

      // Determine overall fermentation status
      final mostCommonStatus = fermentationCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      String recommendation = '';
      if (mostCommonStatus == 'under_fermented') {
        recommendation = 
            'Continue fermentation for ${"2-3"} more days. Monitor moisture levels.';
      } else if (mostCommonStatus == 'properly_fermented') {
        recommendation = 'Beans are ready for drying. Excellent fermentation!';
      } else if (mostCommonStatus == 'over_fermented') {
        recommendation = 
            'Fermentation has exceeded optimal time. Reduce fermentation duration next time.';
      }

      return {
        'success': true,
        'message': 'Analysis completed successfully',
        'fermentationStatus': mostCommonStatus,
        'statistics': {
          'totalBeansDetected': detections.length,
          'underFermented': fermentationCounts['under_fermented'],
          'properlyFermented': fermentationCounts['properly_fermented'],
          'overFermented': fermentationCounts['over_fermented'],
        },
        'confidence': {
          'average': avgConfidence,
          'highest': detections.isNotEmpty 
              ? detections.map((d) => d.confidence).reduce((a, b) => a > b ? a : b)
              : 0.0,
        },
        'recommendation': recommendation,
        'detections': detections.map((d) => d.toJson()).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during analysis: $e',
        'detections': [],
      };
    }
  }

  /// Reshape input data to match model input shape
  List<Object> _reshapeInput(List<List<List<List<double>>>> imageData) {
    // Convert to the format expected by the TFLite interpreter
    // This assumes [1, 640, 640, 3] input shape
    // Convert to flat list of floats
    final flatInput = <double>[];
    for (final batch in imageData) {
      for (final row in batch) {
        for (final pixel in row) {
          for (final channel in pixel) {
            flatInput.add(channel);
          }
        }
      }
    }

    // Create a tensor with proper shape
    return [flatInput];
  }

  /// Parse model output to Detection objects
  List<Detection> _parseOutput(dynamic rawOutput) {
    final detections = <Detection>[];
    
    try {
      // Handle different output types
      List<dynamic> predictions = [];
      
      if (rawOutput is List<List<dynamic>>) {
        // Output is already a list of predictions
        predictions = rawOutput.cast<dynamic>();
      } else if (rawOutput is List<dynamic>) {
        predictions = rawOutput;
      } else {
        return detections;
      }

      // Class names for cacao fermentation
      const classNames = [
        'under_fermented',
        'properly_fermented',
        'over_fermented',
      ];

      // Parse each prediction (confidence threshold: 0.5)
      for (int i = 0; i < predictions.length; i++) {
        final pred = predictions[i];
        
        if (pred is! List || pred.length < 5) continue;

        // Extract bbox and confidence
        final x = (pred[0] as num).toDouble();
        final y = (pred[1] as num).toDouble();
        final w = (pred[2] as num).toDouble();
        final h = (pred[3] as num).toDouble();
        final confidence = (pred[4] as num).toDouble();

        // Skip low confidence detections
        if (confidence < 0.45) continue;

        // Find best class
        int classIdx = 0;
        double maxClassProb = 0.0;
        
        for (int j = 5; j < pred.length && j - 5 < classNames.length; j++) {
          final classProb = (pred[j] as num).toDouble();
          if (classProb > maxClassProb) {
            maxClassProb = classProb;
            classIdx = j - 5;
          }
        }

        final label = classIdx < classNames.length 
            ? classNames[classIdx]
            : 'unknown';

        detections.add(
          Detection(
            label: label,
            confidence: confidence,
            x: x,
            y: y,
            width: w,
            height: h,
          ),
        );
      }
    } catch (e) {
      // Error parsing output - return empty detections
    }

    return detections;
  }

  /// Dispose resources
  void dispose() {
    interpreter?.close();
    _isModelLoaded = false;
  }
}