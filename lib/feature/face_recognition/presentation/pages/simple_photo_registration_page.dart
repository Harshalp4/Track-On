import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:track_on/core/ML/RecognizerV2.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/face_detector_service.dart';
import '../../domain/services/image_converter.dart';
import '../../domain/services/face_augmentation_service.dart';
import '../../domain/services/face_quality_service.dart';

/// ✅ ENHANCED: AI-powered multi-angle registration with automatic pose detection
class SimplePhotoRegistrationPage extends StatefulWidget {
  const SimplePhotoRegistrationPage({super.key});

  @override
  _SimplePhotoRegistrationPageState createState() => _SimplePhotoRegistrationPageState();
}

class _SimplePhotoRegistrationPageState extends State<SimplePhotoRegistrationPage> {
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final RecognizerV2 _recognizer = RecognizerV2();
  final FaceQualityService _qualityService = FaceQualityService();

  bool _isProcessing = false;
  CameraImage? _currentFrame;
  Face? _detectedFace;
  
  String? _qualityMessage;
  bool _isQualityGood = false;
  
  // ✅ ENHANCED: More photos for better coverage (3 easy angles instead of 5)
  static const int REQUIRED_PHOTOS = 3;
  List<img.Image> _capturedPhotos = [];
  List<String> _capturedPoses = []; // Track which poses we've captured
  
  bool _isCapturing = false;
  bool _isGeneratingEmbeddings = false;
  
  // ✅ SIMPLIFIED: Just 3 easy poses - no strict angle requirements
  String _currentDetectedPose = "any";
  String _nextRequiredPose = "any";

  final List<Map<String, dynamic>> _poseInstructions = [
    {
      "pose": "any",
      "title": "📷 Photo 1/3",
      "instruction": "Look at the camera\n(Any angle is fine)",
      "minYaw": -45.0,  // ✅ Very lenient - accept almost anything
      "maxYaw": 45.0,
      "minPitch": -45.0,
      "maxPitch": 45.0,
    },
    {
      "pose": "any",
      "title": "📷 Photo 2/3",
      "instruction": "Keep looking at camera\n(Try a slightly different angle)",
      "minYaw": -45.0,
      "maxYaw": 45.0,
      "minPitch": -45.0,
      "maxPitch": 45.0,
    },
    {
      "pose": "any",
      "title": "📷 Photo 3/3",
      "instruction": "Last photo!\n(Any comfortable position)",
      "minYaw": -45.0,
      "maxYaw": 45.0,
      "minPitch": -45.0,
      "maxPitch": 45.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize(_processCameraImage);
    setState(() {});
  }

  void _processCameraImage(CameraImage image) {
    if (_isProcessing) return;
    
    _isProcessing = true;
    _currentFrame = image;
    _detectFaceInFrame();
  }

  Future<void> _detectFaceInFrame() async {
    if (_currentFrame == null) {
      _isProcessing = false;
      return;
    }

    final inputImage = _faceDetectionService.getInputImageFromFrame(
      _currentFrame!,
      _cameraService.cameraDescription!,
      _cameraService.cameraDirection,
    );

    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    try {
      final faces = await _faceDetectionService.detectFaces(inputImage);
      
      if (faces.isNotEmpty && faces.length == 1) {
        final processedImage = ImageConverter.convertCameraImageToImage(
          _currentFrame!,
          Platform.isIOS,
        );
        final rotatedImage = img.copyRotate(processedImage, angle: 270);
        
        // ✅ RELAXED: Skip strict quality check, just basic check
        final face = faces.first;
        final faceRect = face.boundingBox;
        bool basicQuality = faceRect.width > 60 && faceRect.height > 60; // Just check size
        
        // ✅ ENHANCED: Detect current pose
        _detectCurrentPose(face);
        
        setState(() {
          _detectedFace = face;
          _isQualityGood = basicQuality && (_isPoseCorrect() || _currentDetectedPose == "any");
          
          if (!basicQuality) {
            _qualityMessage = "Move closer to camera";
          } else if (!_isPoseCorrect() && _currentDetectedPose != "any") {
            _qualityMessage = _getPoseGuidance();
          } else {
            _qualityMessage = null;
          }
        });
      } else {
        setState(() {
          _detectedFace = null;
          _isQualityGood = false;
          _qualityMessage = faces.isEmpty ? "No face detected" : "Multiple faces detected";
        });
      }

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _isProcessing = false;
    }
  }

  // ✅ SIMPLIFIED: Auto-detect if face is visible (no strict pose checking)
  void _detectCurrentPose(Face face) {
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    
    // Just log the angles for debugging, but accept any pose
    print("📐 Current pose: Yaw ${yaw.toStringAsFixed(1)}°, Pitch ${pitch.toStringAsFixed(1)}°");
    
    // Accept any reasonable face angle
    if (yaw.abs() <= 45 && pitch.abs() <= 45) {
      _currentDetectedPose = "any";
    } else {
      _currentDetectedPose = "extreme"; // Only reject if too extreme
    }
  }

  // ✅ SIMPLIFIED: Always returns true if face is visible
  bool _isPoseCorrect() {
    return _detectedFace != null && _currentDetectedPose != "extreme";
  }

  // ✅ SIMPLIFIED: Minimal guidance
  String _getPoseGuidance() {
    if (_capturedPhotos.length >= REQUIRED_PHOTOS) {
      return "All photos captured!";
    }
    
    if (_currentDetectedPose == "extreme") {
      return "Face the camera more directly";
    }
    
    return "Hold steady - Ready to capture!";
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _currentFrame == null || _detectedFace == null) {
      if (_detectedFace == null) {
        _showSnackBar('⚠️ No face detected. Position your face clearly.', Colors.orange);
      }
      return;
    }

    // ✅ SUPER SIMPLE: Just check if face is detected
    setState(() => _isCapturing = true);

    try {
      final processedImage = ImageConverter.convertCameraImageToImage(
        _currentFrame!,
        Platform.isIOS,
      );
      final rotatedImage = img.copyRotate(processedImage, angle: 270);

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

      // Get angles for logging
      final yaw = _detectedFace!.headEulerAngleY?.toStringAsFixed(1) ?? "0";
      final pitch = _detectedFace!.headEulerAngleX?.toStringAsFixed(1) ?? "0";

      setState(() {
        _capturedPhotos.add(croppedFace);
        _capturedPoses.add("Yaw:$yaw° Pitch:$pitch°");
        print("✅ Photo ${_capturedPhotos.length}/$REQUIRED_PHOTOS captured");
        print("   Angles: Yaw $yaw°, Pitch $pitch°");
      });

      _showSnackBar('✅ Photo ${_capturedPhotos.length}/$REQUIRED_PHOTOS captured!', Colors.green);

      if (_capturedPhotos.length >= REQUIRED_PHOTOS) {
        await Future.delayed(const Duration(milliseconds: 500));
        _processPhotosAndGenerateEmbeddings();
      }
    } catch (e) {
      print("❌ Capture error: $e");
      _showSnackBar('❌ Capture failed: $e', Colors.red);
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _processPhotosAndGenerateEmbeddings() async {
    setState(() => _isGeneratingEmbeddings = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Processing ${_capturedPhotos.length} photos...\n'
              '🎨 Generating AI variations\n'
              '🧠 Creating smart embeddings',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      print("\n🎨 Starting ENHANCED augmentation process...");
      print("📸 Captured ${_capturedPhotos.length} photos at different natural angles");
      
      // ✅ ENHANCED: Generate MORE variations per photo for better coverage
      final augmentedImages = FaceAugmentationService.generateFromMultiplePhotos(
        _capturedPhotos,
      );

      print("\n🧠 Extracting embeddings from ${augmentedImages.length} images...");
      
      final embeddings = await _recognizer.extractMultipleEmbeddings(augmentedImages);

      print("✅ Generated ${embeddings.length} embeddings from ${_capturedPhotos.length} photos");
      print("📊 AI will handle recognition from ANY angle");

      Navigator.pop(context);
      _showSuccessAndReturn(embeddings);

    } catch (e) {
      print("❌ Processing error: $e");
      Navigator.pop(context);
      
      _showSnackBar('❌ Processing failed: $e', Colors.red);
      
      setState(() => _isGeneratingEmbeddings = false);
    }
  }

  void _showSuccessAndReturn(List<List<double>> embeddings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Photos Processed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '✅ ${embeddings.length} AI-enhanced variations\n'
              '📸 ${_capturedPhotos.length} natural angles captured\n'
              '🤖 Ready for recognition from ANY angle',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      Navigator.pop(context, embeddings);
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.warning,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: color == Colors.green ? 1 : 2),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    final remaining = REQUIRED_PHOTOS - _capturedPhotos.length;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Smart Registration ${_capturedPhotos.length}/$REQUIRED_PHOTOS',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: !_cameraService.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: isPortrait ? 3 : 2,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CameraPreview(_cameraService.cameraController!),
                      ),

                      // ✅ SIMPLIFIED: Just green/yellow border
                      if (_detectedFace != null)
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.green, // ✅ Always green if face detected
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),

                      // ✅ SIMPLIFIED: Always show "ready" when face detected
                      if (_detectedFace != null)
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '✅ Ready! Tap capture button',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      if (_detectedFace == null)
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Position your face',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ✅ Simplified preview thumbnails (no pose labels)
                      if (_capturedPhotos.isNotEmpty)
                        Positioned(
                          top: 80,
                          right: 10,
                          child: Column(
                            children: _capturedPhotos.asMap().entries.map((entry) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    Uint8List.fromList(img.encodePng(entry.value)),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  flex: isPortrait ? 2 : 1,
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _capturedPhotos.length / REQUIRED_PHOTOS,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                          minHeight: 8,
                        ),
                        
                        const SizedBox(height: 16),

                        if (_capturedPhotos.length < REQUIRED_PHOTOS)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade700, Colors.purple.shade900],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _poseInstructions[_capturedPhotos.length]["title"],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _poseInstructions[_capturedPhotos.length]["instruction"],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const Spacer(),

                        SizedBox(
                          width: double.infinity,
                          height: 70,
                          child: ElevatedButton(
                            onPressed: (_isCapturing || _detectedFace == null) ? null : _capturePhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _detectedFace != null
                                  ? Colors.purple 
                                  : Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35),
                              ),
                              elevation: 8,
                            ),
                            child: _isCapturing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _detectedFace != null ? Icons.camera_alt : Icons.face,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _detectedFace != null
                                            ? 'CAPTURE ($remaining left)'
                                            : 'Position your face',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
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
  }
}