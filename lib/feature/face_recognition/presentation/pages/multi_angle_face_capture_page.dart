import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:track_on/core/ML/Recognizer.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/face_detector_service.dart';
import '../../domain/services/image_converter.dart';

class MultiAngleFaceCapturePage extends StatefulWidget {
  const MultiAngleFaceCapturePage({super.key});

  @override
  _MultiAngleFaceCapturePageState createState() => _MultiAngleFaceCapturePageState();
}

class _MultiAngleFaceCapturePageState extends State<MultiAngleFaceCapturePage> {
  // Services
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final Recognizer _recognizer = Recognizer();

  // State variables
  bool _isProcessing = false;
  CameraImage? _currentFrame;
  Face? _detectedFace;
  
  // ✅ REDUCED: Only 6 checkpoints for easier capture
  static const int TOTAL_CHECKPOINTS = 6;
  List<bool> _capturedCheckpoints = List.filled(TOTAL_CHECKPOINTS, false);
  List<List<double>> _capturedEmbeddings = [];
  int _currentCheckpoint = 0;
  String _instruction = "Position your face in the center";
  
  // ✅ NEW: Debug info
  String _debugInfo = "";
  bool _showDebug = true;
  
  // Auto-capture timer
  Timer? _autoCaptureTimer;
  bool _canCapture = true;
  int _captureAttempts = 0;

  // Simpler 6-point pattern
  final List<double> _checkpointAngles = [
    0,    // Front
    60,   // Right
    120,  // Right-down
    180,  // Down
    240,  // Left-down
    300,  // Left
  ];

  final List<String> _checkpointInstructions = [
    "Look straight ahead",
    "Turn your head right",
    "Look right and down",
    "Look down",
    "Look left and down",
    "Turn your head left",
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize(_processCameraImage);
      setState(() {
        _debugInfo = "✅ Camera initialized";
      });
    } catch (e) {
      setState(() {
        _debugInfo = "❌ Camera error: $e";
      });
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_isProcessing || !_canCapture) return;
    
    if (_capturedEmbeddings.length >= TOTAL_CHECKPOINTS) return;

    _isProcessing = true;
    _currentFrame = image;
    _detectFaceInFrame();
  }

  Future<void> _detectFaceInFrame() async {
    if (_currentFrame == null) {
      setState(() {
        _debugInfo = "❌ No camera frame";
      });
      _isProcessing = false;
      return;
    }

    final inputImage = _faceDetectionService.getInputImageFromFrame(
      _currentFrame!,
      _cameraService.cameraDescription!,
      _cameraService.cameraDirection,
    );

    if (inputImage == null) {
      setState(() {
        _debugInfo = "❌ Failed to create input image";
      });
      _isProcessing = false;
      return;
    }

    try {
      final faces = await _faceDetectionService.detectFaces(inputImage);

      setState(() {
        _debugInfo = "👤 Faces detected: ${faces.length}";
      });

      if (faces.isNotEmpty && faces.length == 1) {
        _detectedFace = faces.first;
        
        setState(() {
          _instruction = _checkpointInstructions[_currentCheckpoint];
          _debugInfo = "✅ Face detected - Ready to capture";
        });

        // Auto-capture after face is stable
        if (!_capturedCheckpoints[_currentCheckpoint]) {
          _autoCaptureTimer?.cancel();
          _autoCaptureTimer = Timer(const Duration(seconds: 2), () {
            if (_detectedFace != null && !_capturedCheckpoints[_currentCheckpoint]) {
              _captureCurrentCheckpoint();
            }
          });
        }
      } else {
        setState(() {
          _detectedFace = null;
          _instruction = faces.length > 1 
              ? "Multiple faces - only one person"
              : "No face detected";
          _debugInfo = faces.length > 1 
              ? "⚠️ ${faces.length} faces detected"
              : "⚠️ No face in frame";
        });
        _autoCaptureTimer?.cancel();
      }

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print('❌ Error in face detection: $e');
      setState(() {
        _debugInfo = "❌ Detection error: $e";
      });
      _isProcessing = false;
    }
  }

  Future<void> _captureCurrentCheckpoint() async {
    if (_currentFrame == null || _detectedFace == null || !_canCapture) {
      setState(() {
        _debugInfo = "❌ Cannot capture: frame=${_currentFrame != null}, face=${_detectedFace != null}, canCapture=$_canCapture";
      });
      return;
    }

    setState(() {
      _canCapture = false;
      _captureAttempts++;
      _debugInfo = "📸 Attempting capture ${_captureAttempts}...";
    });

    print("📸 Capturing checkpoint ${_currentCheckpoint + 1}/$TOTAL_CHECKPOINTS");

    try {
      // Step 1: Convert camera image
      setState(() => _debugInfo = "🔄 Converting image...");
      final processedImage = ImageConverter.convertCameraImageToImage(
        _currentFrame!,
        Platform.isIOS,
      );
      
      setState(() => _debugInfo = "🔄 Rotating image...");
      final rotatedImage = img.copyRotate(processedImage, angle: 270);

      // Step 2: Crop face
      setState(() => _debugInfo = "✂️ Cropping face...");
      final faceRect = _detectedFace!.boundingBox;
      int left = faceRect.left.toInt().clamp(0, rotatedImage.width - 1);
      int top = faceRect.top.toInt().clamp(0, rotatedImage.height - 1);
      int width = faceRect.width.toInt().clamp(1, rotatedImage.width - left);
      int height = faceRect.height.toInt().clamp(1, rotatedImage.height - top);

      final croppedFace = img.copyCrop(
        rotatedImage,
        x: left,
        y: top,
        width: width,
        height: height,
      );

      print("✅ Cropped face: ${croppedFace.width}x${croppedFace.height}");
      
      // Step 3: Extract embedding
      setState(() => _debugInfo = "🧠 Extracting embedding...");
      final embedding = await _recognizer.extractEmbedding(croppedFace);
      
      print("✅ Embedding extracted: length=${embedding.length}");
      
      setState(() {
        _capturedCheckpoints[_currentCheckpoint] = true;
        _capturedEmbeddings.add(embedding);
        _debugInfo = "✅ Captured ${_capturedEmbeddings.length}/$TOTAL_CHECKPOINTS";
        
        print("✅ Checkpoint ${_currentCheckpoint + 1} SUCCESS. Total: ${_capturedEmbeddings.length}/$TOTAL_CHECKPOINTS");
        
        _moveToNextCheckpoint();
      });

      // Delay before next capture
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_capturedEmbeddings.length >= TOTAL_CHECKPOINTS) {
        _onAllCheckpointsCaptured();
      } else {
        setState(() => _canCapture = true);
      }
    } catch (e, stackTrace) {
      print("❌ CAPTURE ERROR: $e");
      print("Stack trace: $stackTrace");
      
      setState(() {
        _debugInfo = "❌ Capture failed: ${e.toString().substring(0, min(50, e.toString().length))}";
        _canCapture = true;
      });
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capture failed: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _moveToNextCheckpoint() {
    for (int i = 0; i < TOTAL_CHECKPOINTS; i++) {
      int nextIndex = (_currentCheckpoint + 1 + i) % TOTAL_CHECKPOINTS;
      if (!_capturedCheckpoints[nextIndex]) {
        _currentCheckpoint = nextIndex;
        break;
      }
    }
  }

  void _onAllCheckpointsCaptured() {
    print("🎉 All checkpoints captured!");
    _autoCaptureTimer?.cancel();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Face Capture Complete!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${_capturedEmbeddings.length} angles captured successfully'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.pop(context); // Close dialog
      Navigator.pop(context, _capturedEmbeddings);
    });
  }

  void _skipCurrentCheckpoint() {
    print("⏭️ Skipping checkpoint ${_currentCheckpoint + 1}");
    setState(() {
      _capturedCheckpoints[_currentCheckpoint] = true;
      _moveToNextCheckpoint();
      _debugInfo = "⏭️ Skipped. Move to next angle.";
    });
  }

  // ✅ NEW: Manual capture button
  void _manualCapture() {
    if (_detectedFace != null && _canCapture) {
      _captureCurrentCheckpoint();
    }
  }

  @override
  void dispose() {
    _autoCaptureTimer?.cancel();
    _cameraService.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Capture ${_capturedEmbeddings.length}/$TOTAL_CHECKPOINTS',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          // Toggle debug info
          IconButton(
            icon: Icon(_showDebug ? Icons.bug_report : Icons.bug_report_outlined, 
                       color: Colors.white),
            onPressed: () {
              setState(() => _showDebug = !_showDebug);
            },
          ),
        ],
      ),
      body: !_cameraService.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Camera preview
                Positioned.fill(
                  child: CameraPreview(_cameraService.cameraController!),
                ),

                // Circular guide overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: CircularGuidePainter(
                      checkpointAngles: _checkpointAngles,
                      capturedCheckpoints: _capturedCheckpoints,
                      currentCheckpoint: _currentCheckpoint,
                      faceDetected: _detectedFace != null,
                    ),
                  ),
                ),

                // Debug info
                if (_showDebug)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _debugInfo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                // Instruction text
                Positioned(
                  top: _showDebug ? 70 : 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Progress bar and controls
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _capturedEmbeddings.length / TOTAL_CHECKPOINTS,
                          backgroundColor: Colors.grey.shade700,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_capturedEmbeddings.length} of $TOTAL_CHECKPOINTS angles',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Manual capture button
                          ElevatedButton.icon(
                            onPressed: _detectedFace != null && _canCapture 
                                ? _manualCapture 
                                : null,
                            icon: const Icon(Icons.camera),
                            label: const Text('Capture Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              disabledBackgroundColor: Colors.grey,
                            ),
                          ),
                          
                          // Skip button
                          ElevatedButton.icon(
                            onPressed: _skipCurrentCheckpoint,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Skip'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class CircularGuidePainter extends CustomPainter {
  final List<double> checkpointAngles;
  final List<bool> capturedCheckpoints;
  final int currentCheckpoint;
  final bool faceDetected;

  CircularGuidePainter({
    required this.checkpointAngles,
    required this.capturedCheckpoints,
    required this.currentCheckpoint,
    required this.faceDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2.5);
    final radius = size.width * 0.35;

    // Face oval guide
    final ovalPaint = Paint()
      ..color = faceDetected ? Colors.green.withOpacity(0.7) : Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2.2,
        height: radius * 2.6,
      ),
      ovalPaint,
    );

    // Checkpoint dots
    final ringRadius = radius * 1.4;
    
    for (int i = 0; i < checkpointAngles.length; i++) {
      final angle = checkpointAngles[i] * pi / 180 - pi / 2;
      final x = center.dx + ringRadius * cos(angle);
      final y = center.dy + ringRadius * sin(angle);

      final dotPaint = Paint()..style = PaintingStyle.fill;

      if (capturedCheckpoints[i]) {
        dotPaint.color = Colors.green;
        canvas.drawCircle(Offset(x, y), 16, dotPaint);
        
        final checkPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(Offset(x - 6, y), Offset(x - 2, y + 5), checkPaint);
        canvas.drawLine(Offset(x - 2, y + 5), Offset(x + 6, y - 6), checkPaint);
      } else if (i == currentCheckpoint) {
        dotPaint.color = Colors.purple;
        canvas.drawCircle(Offset(x, y), 18, dotPaint);
        
        final glowPaint = Paint()
          ..color = Colors.purple.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawCircle(Offset(x, y), 26, glowPaint);
      } else {
        dotPaint.color = Colors.grey.withOpacity(0.5);
        canvas.drawCircle(Offset(x, y), 12, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CircularGuidePainter oldDelegate) => true;
}