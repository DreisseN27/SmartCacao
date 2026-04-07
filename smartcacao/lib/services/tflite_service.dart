import 'package:flutter/services.dart';
import '../utils/image_utils.dart';
import '../models/detection.dart';

class TFLiteService {
  static const platform = MethodChannel('com.example.smartcacao/model');
  bool _isModelLoaded = false;
  String _lastError = '';
  
  // Store actual image dimensions from native code
  int _lastImageWidth = 0;
  int _lastImageHeight = 0;
  
  /// Get last image width from native inference
  int get lastImageWidth => _lastImageWidth;
  
  /// Get last image height from native inference
  int get lastImageHeight => _lastImageHeight;

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
      print('  [runInference] Starting inference on: $imagePath');
      
      // Call native code to run inference
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'runInference',
        {'imagePath': imagePath},
      );
      
      if (result?['success'] == false) {
        final error = result?['error'] ?? 'Unknown error';
        print('  [runInference] ❌ Native error: $error');
        throw Exception(error);
      }

      // Extract actual image dimensions from native code  
      _lastImageWidth = (result?['imageWidth'] as num?)?.toInt() ?? 0;
      _lastImageHeight = (result?['imageHeight'] as num?)?.toInt() ?? 0;
      
      if (_lastImageWidth > 0 && _lastImageHeight > 0) {
        print('  [runInference] 📐 Image dimensions from native: ${_lastImageWidth}x${_lastImageHeight}');
      }

      // Parse detections from result
      final detections = _parseDetections(result);
      print('  [runInference] ✓ Inference complete: ${detections.length} detections');
      return detections;
    } catch (e) {
      print('  [runInference] ❌ Error: $e');
      rethrow;
    }
  }

  /// Parse detection results from native code
  List<Detection> _parseDetections(Map<dynamic, dynamic>? result) {
    final detections = <Detection>[];
    const double confidenceThreshold = 0.008; // Balanced threshold to catch beans but filter noise
    
    try {
      if (result == null) return detections;
      
      final detectionsList = result['detections'] as List<dynamic>? ?? [];
      print('  [parseDetections] Total detections from native: ${detectionsList.length}');
      
      int filtered = 0;
      int lowConfidence = 0;
      for (final det in detectionsList) {
        if (det is Map<dynamic, dynamic>) {
          // DEBUG: Log raw detection map from native
          print('  [parseDetections] RAW DETECTION: x=${det['x']}, y=${det['y']}, width=${det['width']}, height=${det['height']}, confidence=${det['confidence']}, label=${det['label']}');
          
          final confidence = (det['confidence'] as num?)?.toDouble() ?? 0.0;
          
          // Only include detections with sufficient confidence
          if (confidence >= confidenceThreshold) {
            final x = (det['x'] as num?)?.toDouble() ?? 0.0;
            final y = (det['y'] as num?)?.toDouble() ?? 0.0;
            final width = (det['width'] as num?)?.toDouble() ?? 0.0;
            final height = (det['height'] as num?)?.toDouble() ?? 0.0;
            
            // DEBUG: Log raw values received from native
            print('  [PARSE] Detection received from native: x=$x, y=$y, w=$width, h=$height, conf=$confidence, label=${det['label']}');
            
            detections.add(
              Detection(
                label: det['label'] as String? ?? 'unknown',
                confidence: confidence,
                x: x,
                y: y,
                width: width,
                height: height,
              ),
            );
          } else {
            lowConfidence++;
            print('  [parseDetections] FILTERED: confidence=$confidence < threshold=$confidenceThreshold');
          }
        }
      }
      
      print('  [parseDetections] Confidence threshold: $confidenceThreshold');
      print('  [parseDetections] Passed threshold: ${detections.length}, Low confidence (${confidenceThreshold-0.05}-${confidenceThreshold}): $lowConfidence, Filtered out: $filtered');
    } catch (e) {
      print('  [parseDetections] ❌ Error parsing: $e');
    }
    
    return detections;
  }

  /// Get fermentation analysis from detections
  Future<Map<String, dynamic>> analyzeBeans(String imagePath) async {
    try {
      print('📊 ANALYSIS START - Image: $imagePath');
      final detections = await runInference(imagePath);
      print('📊 Detections received: ${detections.length}');

      if (detections.isEmpty) {
        print('⚠️  WARNING: No beans detected in the image');
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
        print('  ✓ Detection: ${detection.label} @ confidence ${detection.confidence.toStringAsFixed(2)}');
      }

      final avgConfidence = totalConfidence / detections.length;
      print('📊 Statistics:');
      print('  - Total detections: ${detections.length}');
      print('  - Under-fermented: ${fermentationCounts['under_fermented']}');
      print('  - Properly-fermented: ${fermentationCounts['properly_fermented']}');
      print('  - Over-fermented: ${fermentationCounts['over_fermented']}');
      print('  - Average confidence: ${avgConfidence.toStringAsFixed(3)}');

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

      print('✅ ANALYSIS COMPLETE - Status: $mostCommonStatus');
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
      print('❌ ANALYSIS ERROR: $e');
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