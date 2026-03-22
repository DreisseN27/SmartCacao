import 'dart:convert';
import 'dart:io';
import '../models/detection.dart';

class DetectionRecord {
  final String id;
  final DateTime timestamp;
  final String imagePath;
  final String fermentationStatus; // under_fermented, properly_fermented, over_fermented
  final int underFermentedCount;
  final int properlyFermentedCount;
  final int overFermentedCount;
  final double averageConfidence;
  final List<Detection> detections;
  final String recommendation;

  DetectionRecord({
    required this.id,
    required this.timestamp,
    required this.imagePath,
    required this.fermentationStatus,
    required this.underFermentedCount,
    required this.properlyFermentedCount,
    required this.overFermentedCount,
    required this.averageConfidence,
    required this.detections,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'fermentationStatus': fermentationStatus,
      'underFermentedCount': underFermentedCount,
      'properlyFermentedCount': properlyFermentedCount,
      'overFermentedCount': overFermentedCount,
      'averageConfidence': averageConfidence,
      'recommendation': recommendation,
      'detectionCount': detections.length,
    };
  }

  factory DetectionRecord.fromJson(Map<String, dynamic> json) {
    return DetectionRecord(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      imagePath: json['imagePath'] ?? '',
      fermentationStatus: json['fermentationStatus'] ?? 'unknown',
      underFermentedCount: json['underFermentedCount'] ?? 0,
      properlyFermentedCount: json['properlyFermentedCount'] ?? 0,
      overFermentedCount: json['overFermentedCount'] ?? 0,
      averageConfidence: (json['averageConfidence'] ?? 0.0).toDouble(),
      detections: [],
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class StorageService {
  static const String _fileName = 'detection_history.json';

  Future<String> get _localPath async {
    // Use system temp directory to avoid path_provider dependency
    final tempDir = Directory.systemTemp;
    final appDir = Directory('${tempDir.path}/smartcacao');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir.path;
  }

  Future<File> get _historyFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<File> _imagesDir() async {
    final path = await _localPath;
    final dir = Directory('$path/detection_images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(dir.path);
  }

  Future<List<DetectionRecord>> getAllRecords() async {
    try {
      final file = await _historyFile;
      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final jsonData = jsonDecode(contents) as List;
      return jsonData.map((json) => DetectionRecord.fromJson(json)).toList();
    } catch (e) {
      print('Error reading records: $e');
      return [];
    }
  }

  Future<void> saveDetection({
    required String originalImagePath,
    required String fermentationStatus,
    required int underFermentedCount,
    required int properlyFermentedCount,
    required int overFermentedCount,
    required double averageConfidence,
    required List<Detection> detections,
    required String recommendation,
  }) async {
    try {
      // Copy image to app documents
      final sourceFile = File(originalImagePath);
      final imagesDir = await _imagesDir();
      final newImageName = 'detection_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newImagePath = '${imagesDir.path}/$newImageName';
      await sourceFile.copy(newImagePath);

      // Create record
      final record = DetectionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        imagePath: newImagePath,
        fermentationStatus: fermentationStatus,
        underFermentedCount: underFermentedCount,
        properlyFermentedCount: properlyFermentedCount,
        overFermentedCount: overFermentedCount,
        averageConfidence: averageConfidence,
        detections: detections,
        recommendation: recommendation,
      );

      // Get all records and add new one
      final records = await getAllRecords();
      records.add(record);

      // Save to file
      final file = await _historyFile;
      final jsonList = records.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      print('Detection saved: ${record.id}');
    } catch (e) {
      print('Error saving detection: $e');
    }
  }

  Future<List<DetectionRecord>> getRecordsByStatus(String status) async {
    final records = await getAllRecords();
    return records.where((r) => r.fermentationStatus == status).toList();
  }

  Future<Map<String, int>> getStatistics() async {
    final records = await getAllRecords();
    return {
      'total': records.length,
      'under_fermented': records.where((r) => r.fermentationStatus == 'under_fermented').length,
      'properly_fermented':
          records.where((r) => r.fermentationStatus == 'properly_fermented').length,
      'over_fermented': records.where((r) => r.fermentationStatus == 'over_fermented').length,
    };
  }

  Future<void> deleteRecord(String id) async {
    try {
      final records = await getAllRecords();
      final record = records.firstWhere((r) => r.id == id);
      
      // Delete image file
      final imageFile = File(record.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      // Remove from records and save
      records.removeWhere((r) => r.id == id);
      final file = await _historyFile;
      final jsonList = records.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      print('Record deleted: $id');
    } catch (e) {
      print('Error deleting record: $e');
    }
  }

  Future<void> clearAllRecords() async {
    try {
      final records = await getAllRecords();
      
      // Delete all image files
      for (final record in records) {
        final imageFile = File(record.imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Clear history file
      final file = await _historyFile;
      await file.writeAsString(jsonEncode([]));

      print('All records cleared');
    } catch (e) {
      print('Error clearing records: $e');
    }
  }
}
