import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../services/tflite_service.dart';
import '../models/detection.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  late Future<void> initializeControllerFuture;
  final TFLiteService tfliteService = TFLiteService();
  bool isProcessing = false;
  List<Detection> liveDetections = [];
  int frameCount = 0;
  double fps = 0;
  DateTime lastFpsTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  Future<void> loadModel() async {
    final loaded = await tfliteService.loadModel();
    if (!loaded) {
      if (mounted) {
        final errorMessage = tfliteService.lastError.isEmpty 
          ? 'Model not found. You need to:\n1. Prepare cacao dataset\n2. Run: python train.py\n3. Run: python convert_model.py\n4. Uncomment assets in pubspec.yaml'
          : tfliteService.lastError;
          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'MODEL LOADING ERROR:\n$errorMessage',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
        return;
      }

      final camera = cameras.first;
      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      initializeControllerFuture = controller!.initialize();
      
      // Start live detection after initialization
      initializeControllerFuture.then((_) {
        if (mounted && tfliteService.isModelLoaded) {
          startLiveDetection();
        }
      });
      
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  void startLiveDetection() {
    try {
      controller?.startImageStream((CameraImage image) async {
        // Process every 3rd frame to balance performance
        if (frameCount % 3 == 0) {
          await processFrame(image);
        }
        frameCount++;
        
        // Update FPS
        final now = DateTime.now();
        if (now.difference(lastFpsTime).inSeconds >= 1) {
          if (mounted) {
            setState(() {
              fps = frameCount / now.difference(lastFpsTime).inMilliseconds * 1000;
            });
          }
          frameCount = 0;
          lastFpsTime = now;
        }
      });
    } catch (e) {
      print('Error starting image stream: $e');
    }
  }

  Future<void> processFrame(CameraImage image) async {
    if (!tfliteService.isModelLoaded) return;

    try {
      // Convert CameraImage to image file
      final imagePath = await _convertCameraImageToFile(image);
      if (imagePath == null) return;

      // Run inference directly (not analyzeBeans which adds extra processing)
      try {
        final detections = await tfliteService.runInference(imagePath);
        
        if (mounted) {
          setState(() {
            liveDetections = detections;
          });
        }

        // Clean up temp file
        File(imagePath).deleteSync();
      } catch (e) {
        print('Inference error: $e');
        File(imagePath).deleteSync();
      }
    } catch (e) {
      print('Frame processing error: $e');
    }
  }

  Future<String?> _convertCameraImageToFile(CameraImage image) async {
    try {
      // Convert NV21 (typical Android camera format) to RGB
      final bytes = _convertNV21toRGB(image);
      if (bytes == null) return null;

      // Create image from raw bytes
      final img.Image imgLib = img.Image(
        width: image.width,
        height: image.height,
        format: img.Format.uint8,
        numChannels: 3,
      );
      
      // Copy pixel data
      for (int i = 0; i < bytes.length; i++) {
        imgLib.getBytes()[i] = bytes[i];
      }

      // Encode as JPEG
      final jpg = img.encodeJpg(imgLib, quality: 90);
      
      // Save to system temp directory
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/live_frame_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(jpg);
      
      return file.path;
    } catch (e) {
      print('Image conversion error: $e');
      return null;
    }
  }

  Uint8List? _convertNV21toRGB(CameraImage image) {
    try {
      // Handle YUV420 / NV21 format (common on Android)
      final int width = image.width;
      final int height = image.height;
      
      final Plane plane0 = image.planes[0];
      final Plane plane1 = image.planes[1];
      final Plane plane2 = image.planes[2];

      final int pixelStride1 = plane1.bytesPerPixel ?? 1;
      final int pixelStride2 = plane2.bytesPerPixel ?? 1;

      final Uint8List data = Uint8List(width * height * 3);

      int count = 0;
      for (int y = 0; y < height; y++) {
        int uvPixelStride = pixelStride1;
        int index = y * width;

        for (int x = 0; x < width; x++) {
          final int uvIndex = (y >> 1) * (width >> 1) + (x >> 1);
          final int yValue = plane0.bytes[y * plane0.bytesPerRow + x] & 0xff;
          final int uValue = plane1.bytes[uvIndex * pixelStride1] & 0xff;
          final int vValue = plane2.bytes[uvIndex * pixelStride2] & 0xff;

          data[count++] = _clampToUint8(_toRGB(yValue, uValue, vValue, 0));
          data[count++] = _clampToUint8(_toRGB(yValue, uValue, vValue, 1));
          data[count++] = _clampToUint8(_toRGB(yValue, uValue, vValue, 2));
        }
      }

      return data;
    } catch (e) {
      print('NV21 conversion error: $e');
      return null;
    }
  }

  int _toRGB(int y, int u, int v, int channel) {
    y -= 16;
    u -= 128;
    v -= 128;

    const int cy = 298;
    const int cu = -100;
    const int cv = 208;
    const int cgu = -208;
    const int cgv = -100;

    int r = (cy * y + cv * v) >> 8;
    int g = (cy * y + cu * u + cgv * v) >> 8;
    int b = (cy * y + cu * u) >> 8;

    return switch (channel) {
      0 => r,
      1 => g,
      _ => b,
    };
  }

  int _clampToUint8(int value) {
    return value.clamp(0, 255);
  }

  Future<void> captureImage() async {
    if (isProcessing) return;

    try {
      await initializeControllerFuture;
      setState(() => isProcessing = true);

      final image = await controller!.takePicture();

      if (!mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Run analysis
      final result = await tfliteService.analyzeBeans(image.path);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              result: result,
              imagePath: image.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, null); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    controller?.stopImageStream().catchError((_) {});
    controller?.dispose();
    tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Cacao Detection'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      CameraPreview(controller!),
                      // Detection overlay
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DetectionPainter(liveDetections),
                        ),
                      ),
                      // Grid overlay
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GridPainter(),
                        ),
                      ),
                      // Center guide circle
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha((0.7 * 255).toInt()),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.grain,
                            size: 60,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      // Detection stats panel
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.6 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Detections: ${liveDetections.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (liveDetections.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Classes: ${_getClassBreakdown()}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Position cacao beans within the circle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : captureImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade700,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isProcessing ? Icons.hourglass_bottom : Icons.camera,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isProcessing ? 'Processing...' : 'Capture',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getClassBreakdown() {
    final counts = <String, int>{};
    for (final det in liveDetections) {
      counts[det.label] = (counts[det.label] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(' | ');
  }
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;

  DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final detection in detections) {
      // Set color based on class
      if (detection.label == 'under_fermented') {
        paint.color = Colors.red;
      } else if (detection.label == 'properly_fermented') {
        paint.color = Colors.green;
      } else {
        paint.color = Colors.orange;
      }

      // Convert normalized coordinates to screen coordinates
      final left = detection.x * size.width - (detection.width * size.width / 2);
      final top = detection.y * size.height - (detection.height * size.height / 2);
      final right = detection.x * size.width + (detection.width * size.width / 2);
      final bottom = detection.y * size.height + (detection.height * size.height / 2);

      // Draw bounding box
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );

      // Draw label text
      final confidenceStr = (detection.confidence * 100).toStringAsFixed(1);
      textPainter.text = TextSpan(
        text: '${detection.label}\n$confidenceStr%',
        style: TextStyle(
          color: paint.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black87,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(left, top - 30));
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return oldDelegate.detections.length != detections.length;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha((0.3 * 255).toInt())
      ..strokeWidth = 1;

    final gridSize = 3;
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;

    // Draw vertical lines
    for (int i = 1; i < gridSize; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 1; i < gridSize; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}