import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../services/tflite_service.dart';
import '../models/detection.dart';
import '../utils/permission_utils.dart';
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
  bool isInferenceBusy = false;
  bool isLiveDetectionMode = true; // ENABLED: Live detection mode
  List<Detection> liveDetections = [];
  int frameCount = 0;
  double fps = 0;
  DateTime lastFpsTime = DateTime.now();
  bool _captureInProgress = false; // LOCK to prevent multiple simultaneous captures

  @override
  void initState() {
    super.initState();
    print('CameraScreen initState - starting permission and model initialization');
    requestPermissionsAndInitialize();
    loadModel();
  }

  /// Request necessary permissions and then initialize camera
  Future<void> requestPermissionsAndInitialize() async {
    print('Requesting permissions...');
    try {
      final hasPermissions = await PermissionUtils.requestAllPermissions();
      print('Permission request result: $hasPermissions');
      
      if (hasPermissions) {
        print('Permissions granted, initializing camera');
        initCamera();
      } else {
        print('Permissions denied, showing error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Camera permission is required to use this app. '
                'Please enable camera access in Settings.',
              ),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open Settings',
                onPressed: () => PermissionUtils.openAppSettings(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error during permission request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
        if (mounted && tfliteService.isModelLoaded && isLiveDetectionMode) {
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
        // Only process frames if still in live mode
        if (!isLiveDetectionMode) return;
        
        // Skip frame if inference is still busy (prevent frame queue buildup)
        if (isInferenceBusy) return;
        
        // Process every frame for maximum FPS on powerful devices
        // The isInferenceBusy flag prevents queue buildup while still maintaining high framerate
        await processFrame(image);
        
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

  void toggleDetectionMode() async {
    setState(() {
      isLiveDetectionMode = !isLiveDetectionMode;
      if (!isLiveDetectionMode) {
        liveDetections = []; // Clear detections when switching to capture mode
      }
    });
    
    if (isLiveDetectionMode) {
      // Switch to live mode - start streaming
      if (mounted && tfliteService.isModelLoaded) {
        startLiveDetection();
      }
    } else {
      // Switch to capture mode - stop streaming
      try {
        await controller?.stopImageStream();
      } catch (e) {
        print('Error stopping image stream: $e');
      }
    }
  }

  Future<void> processFrame(CameraImage image) async {
    if (!tfliteService.isModelLoaded || !isLiveDetectionMode) return;
    
    // Mark as busy to prevent frame queue buildup
    isInferenceBusy = true;

    try {
      // Convert CameraImage to image file
      final imagePath = await _convertCameraImageToFile(image);
      if (imagePath == null) return;

      // Run inference directly (not analyzeBeans which adds extra processing)
      try {
        final detections = await tfliteService.runInference(imagePath);
        
        if (mounted && isLiveDetectionMode) {
          setState(() {
            liveDetections = detections;
          });
        }

        // Clean up temp file safely
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Failed to delete temp file: $e');
        }
      } catch (e) {
        print('Inference error: $e');
        // Clean up temp file on error
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (deleteError) {
          print('Failed to delete temp file on error: $deleteError');
        }
      }
    } catch (e) {
      print('Frame processing error: $e');
    } finally {
      // Mark as no longer busy
      isInferenceBusy = false;
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
    // Prevent multiple simultaneous captures
    if (isProcessing || _captureInProgress) {
      print('⚠️  Capture already in progress, ignoring tap');
      return;
    }

    _captureInProgress = true; // Lock before any async operation
    
    try {
      await initializeControllerFuture;
      setState(() => isProcessing = true);

      print('\n═══════════════════════════════════');
      print('📸 SINGLE CAPTURE START');
      print('═══════════════════════════════════');
      print('[1/4] Capturing image...');
      final image = await controller!.takePicture();
      print('[2/4] ✓ Image captured: ${image.path}');

      if (!mounted) return;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Run analysis
      print('[3/4] Starting inference and analysis...');
      final result = await tfliteService.analyzeBeans(image.path);
      print('[4/4] ✓ Analysis complete');
      print('Detections found: ${result['detections']?.length ?? 0}');
      if (result['success'] != true) {
        print('⚠️  Analysis failed: ${result['message']}');
      }

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
        print('═══════════════════════════════════');
        print('✅ Navigated to results screen');
        print('═══════════════════════════════════\n');
      }
    } catch (e) {
      print('\n❌ ERROR DURING CAPTURE: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        // Try to close dialog if it's open
        try {
          Navigator.pop(context);
        } catch (_) {}
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      _captureInProgress = false; // UNLOCK
      if (mounted) {
        setState(() => isProcessing = false);
      }
      print('═══════════════════════════════════');
      print('📸 SINGLE CAPTURE END');
      print('═══════════════════════════════════\n');
    }
  }

  @override
  void dispose() {
    // Stop live detection first
    isLiveDetectionMode = false;
    liveDetections.clear();
    
    // Stop image streaming
    try {
      controller?.stopImageStream().catchError((_) {});
    } catch (e) {
      print('Error stopping image stream: $e');
    }
    
    // Dispose controller
    try {
      controller?.dispose();
    } catch (e) {
      print('Error disposing controller: $e');
    }
    
    // Dispose TFLite service
    try {
      tfliteService.dispose();
    } catch (e) {
      print('Error disposing TFLite service: $e');
    }
    
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
        title: Text(isLiveDetectionMode ? 'Live Detection' : 'Single Capture'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GestureDetector(
                  onTap: toggleDetectionMode,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiveDetectionMode ? Icons.videocam : Icons.camera_alt,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLiveDetectionMode ? 'LIVE' : 'CAPTURE',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return SizedBox.expand(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(controller!),
                        // Detection overlay (only in live mode)
                        if (isLiveDetectionMode)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DetectionPainter(liveDetections, tfliteService: tfliteService),
                            ),
                          ),
                        // Grid overlay for composition guide
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
                        // Detection stats panel (only in live mode)
                        if (isLiveDetectionMode)
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
                    ),
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
                Text(
                  isLiveDetectionMode
                      ? 'Position cacao beans within the circle\n(Real-time detection enabled)'
                      : 'Position cacao beans within the circle\n(Tap Capture to analyze)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
  final TFLiteService? tfliteService;

  DetectionPainter(this.detections, {this.tfliteService});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const modelInputSize = 320.0; // Model was trained on 320x320

    // Calculate the scale factor accounting for aspect ratio
    // Camera preview maintains aspect ratio, so we need to find the visible area
    final screenAspect = size.width / size.height;
    final modelAspect = 1.0; // 320x320 is square
    
    print('📐 DetectionPainter: size=$size, aspect=${screenAspect.toStringAsFixed(2)}');
    
    // Calculate how much of the screen is actually used by the camera preview
    late double scaleX, scaleY, offsetX, offsetY;
    
    if (screenAspect > modelAspect) {
      // Screen is wider than model (common for portrait phones)
      // Model will be constrained by height
      scaleX = size.height; // Both scale by height
      scaleY = size.height;
      offsetX = (size.width - scaleX) / 2; // Center horizontally
      offsetY = 0;
    } else {
      // Screen is taller than model (unusual, but handle it)
      // Model will be constrained by width
      scaleX = size.width;
      scaleY = size.width;
      offsetX = 0;
      offsetY = (size.height - scaleY) / 2; // Center vertically
    }
    
    print('📐 Scale: scaleX=$scaleX, scaleY=$scaleY, offsetX=$offsetX, offsetY=$offsetY');

    for (var idx = 0; idx < detections.length; idx++) {
      final detection = detections[idx];
      
      // Set color based on class
      if (detection.label == 'under_fermented') {
        paint.color = Colors.red;
      } else if (detection.label == 'properly_fermented') {
        paint.color = Colors.green;
      } else {
        paint.color = Colors.orange;
      }

      // Model coordinates are in 320x320 letterboxed space.
      // Get actual camera dimensions from native code (this is the FIX!)
      double cameraWidth = 1280.0;
      double cameraHeight = 720.0;
      
      final actualWidth = tfliteService?.lastImageWidth;
      final actualHeight = tfliteService?.lastImageHeight;
      
      if (actualWidth != null && actualHeight != null && actualWidth > 0 && actualHeight > 0) {
        cameraWidth = actualWidth.toDouble();
        cameraHeight = actualHeight.toDouble();
        print('📐 CRITICAL FIX: Using actual camera dimensions: ${cameraWidth.toInt()}x${cameraHeight.toInt()}');
      } else {
        print('⚠️  WARNING: Could not get actual camera dimensions, using defaults: ${cameraWidth.toInt()}x${cameraHeight.toInt()}');
      }
      
      const modelInputSize = 320.0;
      final scale = 320.0 / cameraWidth; // Calculate the actual scale used  
      final scaledWidth = cameraWidth * scale;
      final scaledHeight = cameraHeight * scale;
      final paddingLeft = (modelInputSize - scaledWidth) / 2;
      final paddingTop = (modelInputSize - scaledHeight) / 2;
      
      print('📏 Transform: scale=$scale, scaledSize=${scaledWidth.toInt()}x${scaledHeight.toInt()}, padding=($paddingLeft, $paddingTop)');
      
      // Reverse letterbox: model space (0-320) → camera space
      final cameraX = (detection.x - paddingLeft) / scaledWidth * cameraWidth;
      final cameraY = (detection.y - paddingTop) / scaledHeight * cameraHeight;
      final cameraW = (detection.width / modelInputSize) * cameraWidth;
      final cameraH = (detection.height / modelInputSize) * cameraHeight;
      
      // Map camera coordinates to screen coordinates
      // The preview is displayed as a square (384x384) within the canvas
      // The canvas and camera both have 16:9 aspect ratio
      // So the preview fills the entire canvas (384x598.2)
      // NO PADDING NEEDED - just scale camera space directly to canvas space
      
      // Scale camera → canvas (maintaining aspect ratio perfectly)
      final screenX = (cameraX / cameraWidth) * size.width;
      final screenY = (cameraY / cameraHeight) * size.height;
      final screenW = (cameraW / cameraWidth) * size.width;
      final screenH = (cameraH / cameraHeight) * size.height;

      // Calculate bounding box corners (x,y are center coordinates)
      final left = screenX - screenW / 2;
      final top = screenY - screenH / 2;
      final right = screenX + screenW / 2;
      final bottom = screenY + screenH / 2;

      // DEBUG: Log detailed transformation
      print('📦 Detection[$idx] RAW model: x=${detection.x}, y=${detection.y}, w=${detection.width}, h=${detection.height}');
      print('📦 Detection[$idx] CAMERA: x=${cameraX.toStringAsFixed(1)}, y=${cameraY.toStringAsFixed(1)}, w=${cameraW.toStringAsFixed(1)}, h=${cameraH.toStringAsFixed(1)}');
      print('📦 Detection[$idx] SCREEN: center=(${screenX.toStringAsFixed(1)},${screenY.toStringAsFixed(1)}), box=(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, ${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)})');
      
      // DEBUG: Verify padding calculation
      final paddingCheckBottom = modelInputSize - paddingTop - scaledHeight;
      print('📊 Padding: top=$paddingTop, bottom=$paddingCheckBottom, image_height=$scaledHeight, scaled_w=$scaledWidth');
      
      // DEBUG: Verify if detection is in valid image area
      final isInValidArea = detection.y >= paddingTop && detection.y < (paddingTop + scaledHeight);
      print('📍 Detection[$idx] in valid area: $isInValidArea (y=${detection.y}, range=$paddingTop-${paddingTop + scaledHeight})');

      // Draw bounding box
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
      
      // Draw crosshair at detection center for visual verification
      final crosshairSize = 10.0;
      final crosshairPaint = Paint()
        ..color = Colors.cyan
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(screenX - crosshairSize, screenY),
        Offset(screenX + crosshairSize, screenY),
        crosshairPaint,
      );
      canvas.drawLine(
        Offset(screenX, screenY - crosshairSize),
        Offset(screenX, screenY + crosshairSize),
        crosshairPaint,
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