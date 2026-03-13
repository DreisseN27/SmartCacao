import 'package:flutter/services.dart';
import '../utils/image_utils.dart';
import '../models/detection.dart';

class TFLiteService {
  static const platform = MethodChannel('com.example.smartcacao/model');
  bool _isModelLoaded = false;
  String _lastError = '';

  /// Get the last error that occurred
  String get lastError => _lastError;

  /// Load the model from assets via platform channel
  Future<bool> loadModel() async {
    try {
      if (_isModelLoaded) return true;
      
      print("=== LOADING MODEL FROM NATIVE CODE ===");
      
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>('loadModel');
      final success = result?['success'] as bool? ?? false;
      final errorMessage = result?['error'] as String?;
      
      if (success) {
        _isModelLoaded = true;
        _lastError = '';
        print('✓✓✓ Model loaded successfully ✓✓✓');
      } else {
        final error = errorMessage ?? 'Unknown error';
        _lastError = error;
        _isModelLoaded = false;
        print('✗✗✗ Failed to load model ✗✗✗');
        print('Error details: $error');
      }
      
      return _isModelLoaded;
    } on PlatformException catch (e) {
      _lastError = "Platform Error: ${e.code} - ${e.message}";
      print('✗ Platform exception: $_lastError');
      _isModelLoaded = false;
      return false;
    } catch (e) {
      _lastError = "Error: $e";
      print('✗ Exception loading model: $_lastError');
      _isModelLoaded = false;
      return false;
    }
  }

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Run inference on an image via platform channel
  Future<List<Detection>> runInference(String imagePath) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      // Call native code to run inference
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'runInference',
        {'imagePath': imagePath},
      );
      
      if (result?['success'] == false) {
        throw Exception(result?['error'] ?? 'Unknown error');
      }

      // Parse detections from result
      final detections = _parseDetections(result);
      return detections;
    } catch (e) {
      print('Inference error: $e');
      rethrow;
    }
  }

  /// Parse detection results from native code
  List<Detection> _parseDetections(Map<dynamic, dynamic>? result) {
    final detections = <Detection>[];
    
    try {
      if (result == null) return detections;
      
      final detectionsList = result['detections'] as List<dynamic>? ?? [];
      
      for (final det in detectionsList) {
        if (det is Map<dynamic, dynamic>) {
          detections.add(
            Detection(
              label: det['label'] as String? ?? 'unknown',
              confidence: (det['confidence'] as num?)?.toDouble() ?? 0.0,
              x: (det['x'] as num?)?.toDouble() ?? 0.0,
              y: (det['y'] as num?)?.toDouble() ?? 0.0,
              width: (det['width'] as num?)?.toDouble() ?? 0.0,
              height: (det['height'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      }
    } catch (e) {
      print('Error parsing detections: $e');
    }
    
    return detections;
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
            'Continue fermentation for 2-3 more days. Monitor moisture levels.';
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

  /// Dispose resources
  void dispose() {
    _isModelLoaded = false;
  }
}