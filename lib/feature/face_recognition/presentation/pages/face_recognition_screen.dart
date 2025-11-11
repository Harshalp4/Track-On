import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_on/core/ML/RecognizerV2.dart';
import 'package:track_on/core/endpoints/base_url.dart';
import 'package:track_on/core/face_recon_db/database_helper_hive.dart';
import 'package:track_on/core/ML/Recognition.dart';
import 'package:track_on/feature/auth/presentation/pages/login_controller.dart';
import 'package:track_on/feature/face_recognition/domain/services/fetch_new_face_from_device.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/animated_border_scanner.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/confirm_page.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/face_list_page.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/face_registration_page.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/setting_page.dart';
import 'package:track_on/feature/face_recognition/presentation/widgets/face_detection_painter.dart';
import 'package:track_on/main.dart';

import '../../domain/services/camera_service.dart';
import '../../domain/services/face_detector_service.dart';
import '../../domain/services/face_recognition_service.dart';
import '../../domain/services/device_tracking_api_call_service.dart';
import '../../domain/services/image_converter.dart';
import '../../domain/services/liveness_detector_service.dart';
import '../../domain/services/ai_liveness_service.dart';
import '../../domain/services/face_quality_service.dart';
import '../../domain/services/network_monitor_api_call.dart';
import '../widgets/face_boxes_painter.dart';
import '../widgets/kiosk_mode_widgets/liveness_confirmation_card.dart';
import 'multi_angle_face_capture_page.dart';
import 'simple_photo_registration_page.dart';
import '../widgets/face_guide_overlay.dart';
import '../widgets/liveness_progress_overlay.dart';
import '../widgets/recognition_feedback_widget.dart';
import '../../domain/services/tts_service.dart';
import '../widgets/animated_recognition_overlay.dart';
import '../widgets/clock_in_success_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../domain/services/geofence_service.dart';
import '../../../../domain/services/location_api_service.dart';
import '../../../../domain/models/geofence_model.dart';
// ✅ NEW: Advanced liveness components
import '../../domain/services/advanced_liveness_detector_service.dart';
import '../widgets/advanced_liveness_challenge_overlay.dart';


class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  // ✅ ENHANCED: Use RecognizerV2
  late RecognizerV2 _recognizer;
  
  // Services
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final FaceRecognitionService _faceRecognitionService = FaceRecognitionService();
  final LivenessDetectionService _livenessService = LivenessDetectionService();
  final DatabaseHelperHive _dbHelper = DatabaseHelperHive();
  
  // ✅ NEW: AI Services
  late AILivenessService _aiLivenessService;
  late FaceQualityService _qualityService;
  late AdvancedLivenessDetectorService _advancedLivenessService;

 final TTSService _ttsService = TTSService();

  // State variables
  bool _isProcessing = false;
  List<Recognition> _recognitions = [];
  CameraImage? _currentFrame;
  bool _shouldRegisterFace = false;
  bool _isFaceRecognitionActive = true;
  String _lastClockOutTime = "12:46 pm today";
  bool _useLivenessConfirmationCard = true;

  String? _clockInMessage;
  bool _showClockInLoader = false;

  int _frameCounter = 0;
  static const int PROCESS_EVERY_N_FRAMES = 3;

  // Frame tracking for preventing immediate false recognition
  int _framesSinceStart = 0;
  static const int MIN_FRAMES_BEFORE_RECOGNITION = 15;

  // ✅ NEW: UI state variables
  bool _showFaceGuide = true;
  bool _showLivenessProgress = false;
  double _livenessProgress = 0.0;
  String _livenessStatusMessage = "";
  String? _faceQualityMessage;
  bool _showSuccessFeedback = false;
  String _feedbackName = "";
  String _feedbackMessage = "";
  Face? _detectedFace;
  
  // ✅ NEW: AI liveness control
  bool _useAILiveness = false; // Toggle: false = rule-based, true = AI
  LivenessResult? _lastAILivenessResult;
  
  // ✅ NEW: Advanced liveness control
  bool _useAdvancedLiveness = false;
  bool _showAdvancedLivenessUI = false;

    bool _showRecognitionOverlay = false;
  String? _overlayName;
  double _overlayConfidence = 0.0;
  bool _isRecognitionSuccess = false;

  bool _isClockInInProgress = false;
  Map<String, DateTime> _personCooldowns = {}; // Track each person separately
  static const int COOLDOWN_SECONDS = 10;

bool _isFlashlightOn = false;
  bool _isLowLight = false;


final GeofenceService _geofenceService = GeofenceService();
  final LocationApiService _locationApi = LocationApiService();
  List<Geofence> _assignedGeofences = [];
  bool _locationEnabled = true;
  Position? _lastPosition;



 void _resetAllState() {
  print("\n🔄 RESETTING STATE (preserving liveness)");
  
  setState(() {
    _framesSinceStart = 0;
    _frameCounter = 0;
    _isProcessing = false;
    _recognitions.clear();
    _isFaceRecognitionActive = true;
    _clockInMessage = null;
    _showClockInLoader = false;
    _lastAILivenessResult = null;
    _isClockInInProgress = false;
    
    // ✅ ADD THESE:
    _detectedFace = null;
    _faceQualityMessage = null;
    _showRecognitionOverlay = false;
    _overlayName = null;
    _isRecognitionSuccess = false;
    _showLivenessProgress = false;
    _showAdvancedLivenessUI = false;
  });
  
  print("✅ Partial reset complete\n");
}

  void _resetForRetry() {
    print("\n🔄 FULL RESET - User clicked retry");
    
    setState(() {
      _framesSinceStart = 0;
      _frameCounter = 0;
      _isProcessing = false;
      _recognitions.clear();
      _isFaceRecognitionActive = true;
      _livenessService.resetSession();
      _aiLivenessService.reset();
      _advancedLivenessService.resetSession();
      _showAdvancedLivenessUI = false;
      _clockInMessage = null;
      _showClockInLoader = false;
      _lastAILivenessResult = null;
    });
    
    print("✅ Full reset complete\n");
  }

@override
void initState() {
  super.initState();

  print("\n🚀 FACE RECOGNITION SCREEN INITIALIZED");
  
  _recognizer = RecognizerV2();
  _aiLivenessService = AILivenessService();
  _qualityService = FaceQualityService();
  _advancedLivenessService = AdvancedLivenessDetectorService();
  _ttsService.initialize();

  _resetAllState();
  _dbHelper.init();
  _loadSettings();
  _initializeServices();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final deviceTrackingService = DeviceTrackingService(
    apiUrl: BaseUrl.getDeviceTracking,
  );
  deviceTrackingService.start();

  // ✅ FIXED: Safe handling of fetchNewFaceForDevice
  _fetchNewFacesWithRetry();
}

// ✅ ADD THIS NEW METHOD to the class:
void _fetchNewFacesWithRetry() {
  try {
    print("📡 Calling fetchNewFaceForDevice...");
    fetchNewFaceForDevice(3, _recognizer as dynamic);
  } catch (e) {
    print("⚠️ fetchNewFaceForDevice error: $e");
    print("   Continuing without server sync...");
  }

  // Retry after 3 minutes
  Future.delayed(Duration(minutes: 3), () {
    try {
      print("📡 Calling fetchNewFaceForDevice after 3 minutes...");
      fetchNewFaceForDevice(3, _recognizer as dynamic);
    } catch (e) {
      print("⚠️ fetchNewFaceForDevice error (retry): $e");
    }
  });
}
  
 Future<void> _loadSettings() async {
  final settingsBox = await Hive.openBox('settingsBox');
  setState(() {
    _useLivenessConfirmationCard = settingsBox.get('useLivenessConfirmationCard', defaultValue: true);
    _useAILiveness = settingsBox.get('useAILiveness', defaultValue: true); // ✅ Load from settings
  });
  
  print("⚙️ Settings loaded:");
  print("   Liveness confirmation card: $_useLivenessConfirmationCard");
  print("   AI Liveness: ${_useAILiveness ? 'ENABLED' : 'DISABLED (Rule-based)'}");
}

  Future<void> _initializeServices() async {
    await _cameraService.initialize(_processCameraImage);
    setState(() {});
  }

  void _processCameraImage(CameraImage image) {
    if (_isProcessing || !_isFaceRecognitionActive) return;

    _framesSinceStart++;
    
    if (_framesSinceStart % 30 == 0) {
    _checkLightingConditions(image);
  }
  

    if (_framesSinceStart < MIN_FRAMES_BEFORE_RECOGNITION) {
      if (_framesSinceStart % 5 == 0) {
        print("⏳ Warming up... Frame ${_framesSinceStart}/$MIN_FRAMES_BEFORE_RECOGNITION");
      }
      return;
    }
    
    if (_framesSinceStart == MIN_FRAMES_BEFORE_RECOGNITION) {
      print("\n✅ Warmup complete - Starting face recognition\n");
    }

    _frameCounter++;
    if (_frameCounter % PROCESS_EVERY_N_FRAMES != 0) {
      return;
    }

    _isProcessing = true;
    _currentFrame = image;
    _detectFacesInFrame();
  }

Future<void> _detectFacesInFrame() async {
  if (_currentFrame == null) {
    _isProcessing = false;
    return;
  }

  final inputImage = _faceDetectionService.getInputImageFromFrame(
      _currentFrame!,
      _cameraService.cameraDescription!,
      _cameraService.cameraDirection);

  if (inputImage == null) {
    _isProcessing = false;
    return;
  }

  try {
    final faces = await _faceDetectionService.detectFaces(inputImage);

    if (faces.isNotEmpty) {
      _updateFaceQualityFeedback(faces.first);
      _processDetectedFaces(faces);
    } else {
      print("👻 No faces detected - clearing state");
      
      // ✅ CRITICAL: Clear ALL state when no face detected
      setState(() {
        _recognitions.clear();
        _detectedFace = null;
        _faceQualityMessage = null;
        _showLivenessProgress = false;
        _showRecognitionOverlay = false;  // ✅ ADD THIS
        _overlayName = null;               // ✅ ADD THIS
        _isRecognitionSuccess = false;     // ✅ ADD THIS
      });
      
      _livenessService.resetSession();
      _aiLivenessService.reset();
      _advancedLivenessService.resetSession();
      _showAdvancedLivenessUI = false;
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  } catch (e) {
    print('Error in face detection: $e');
    _isProcessing = false;
  }
}

  Rect _transformRectFor270Rotation(Rect rect, int originalWidth, int originalHeight) {
  // For 270° clockwise rotation:
  // new_x = y
  // new_y = original_width - x - width
  
  final newLeft = rect.top;
  final newTop = originalWidth - rect.right;
  final newRight = rect.bottom;
  final newBottom = originalWidth - rect.left;
  
  return Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
}


void _processDetectedFaces(List<Face> faces) async {
  // ✅ CHECK: Is any clock-in currently showing popup?
  if (_isClockInInProgress) {
    print("⏸️ Clock-in popup is showing - skipping frame");
    return;
  }
  
  final processedImage = ImageConverter.convertCameraImageToImage(
      _currentFrame!, Platform.isIOS);
  final rotatedImage = img.copyRotate(processedImage, angle: 270);


print("\n📐 IMAGE SIZE DEBUG:");
  print("   Original camera image: ${processedImage.width} x ${processedImage.height}");
  print("   After 270° rotation: ${rotatedImage.width} x ${rotatedImage.height}");
  
if (faces.isNotEmpty) {
    final face = faces.first;
    print("   ML Kit face box (BEFORE rotation): ${face.boundingBox}");
    
    // ✅ CRITICAL: Transform face coordinates for 270° rotation
    final transformedRect = _transformRectFor270Rotation(
      face.boundingBox,
      processedImage.width,
      processedImage.height,
    );
    print("   Transformed box (AFTER rotation): $transformedRect");
  }

  _recognitions = _faceRecognitionService.recognizeFaces(faces, rotatedImage);

  print("\n🔍 RECOGNITION RESULTS:");
  print("╔" + "═" * 60 + "╗");
  for (var i = 0; i < _recognitions.length; i++) {
    var rec = _recognitions[i];
    print("║ Face ${i + 1}: ${rec.name}");
    print("║   Distance: ${rec.distance.toStringAsFixed(4)}");
    print("║   Threshold: ${_recognizer.cosineThreshold}");
    
    if (rec.secondBestName != null && rec.secondBestName != "Unknown") {
      print("║   Runner-up: ${rec.secondBestName} (${rec.secondBestDistance!.toStringAsFixed(4)})");
      print("║   Confidence Gap: ${rec.confidenceGap!.toStringAsFixed(4)}");
    }
    
    bool isValid = rec.distance <= _recognizer.cosineThreshold && 
                   rec.name != "Unregister" && 
                   rec.name != "Unknown";
    
    if (isValid && rec.confidenceGap != null) {
      isValid = rec.confidenceGap! >= _recognizer.minConfidenceGap;
    }
    
    print("║   Status: ${isValid ? '✅ VERIFIED KNOWN' : '❌ STRANGER/UNCERTAIN'}");
    print("║");
  }
  print("╚" + "═" * 60 + "╝");

 print("\n🔍 FILTERING KNOWN FACES:");
final knownFaces = _recognitions.where((rec) {
  if (rec.name == "Unregister" || rec.name == "Unknown") {
    print("  🚫 Filtered: ${rec.name} - marked as unregistered");
    return false;
  }
  
  if (rec.distance > _recognizer.cosineThreshold) {
    print("  🚫 Filtered: ${rec.name} - distance too high");
    return false;
  }
  
  // ✅ FIX: Only check confidence gap if there's a valid second-best match
  if (rec.secondBestName != null && 
      rec.secondBestName != "Unknown" && 
      rec.secondBestName != "Unregister" &&
      rec.confidenceGap != null && 
      rec.confidenceGap! < _recognizer.minConfidenceGap) {
    print("  🚫 Filtered: ${rec.name} - ambiguous match (gap: ${rec.confidenceGap!.toStringAsFixed(4)})");
    return false;
  }
  
  // ✅ CHECK: Person-specific cooldown
  if (_personCooldowns.containsKey(rec.name)) {
    final lastClockIn = _personCooldowns[rec.name]!;
    final secondsSince = DateTime.now().difference(lastClockIn).inSeconds;
    
    if (secondsSince < COOLDOWN_SECONDS) {
      print("  🚫 Filtered: ${rec.name} - in cooldown (${COOLDOWN_SECONDS - secondsSince}s remaining)");
      return false;
    } else {
      print("  ✅ Cooldown expired for ${rec.name} (${secondsSince}s since last clock-in)");
      _personCooldowns.remove(rec.name);
    }
  }
  
  print("  ✅ Accepted: ${rec.name} - all verification checks passed");
  return true;
}).toList();

  print("\n📊 FINAL SUMMARY: ${knownFaces.length} verified known / ${_recognitions.length} total faces");

  if (knownFaces.isNotEmpty) {
    print("\n✅ VERIFIED KNOWN FACE DETECTED: ${knownFaces.first.name}");
    print("   Confidence: ${((1 - knownFaces.first.distance) * 100).toStringAsFixed(1)}%");
    
    setState(() {
      _showRecognitionOverlay = true;
      _overlayName = knownFaces.first.name;
      _overlayConfidence = 1 - knownFaces.first.distance;
      _isRecognitionSuccess = false;
    });
    
    // TTS
    print("\n🔊 CALLING TTS NOW...");
    _ttsService.initialize().then((_) {
      _ttsService.speakClockIn(knownFaces.first.name);
    });
    
    // ✅ ENHANCED: Continue with liveness (3 modes)
    if (_useAdvancedLiveness && _currentFrame != null) {
      await _performAdvancedLivenessCheck(knownFaces.first, faces, _currentFrame!);
    } else if (_useAILiveness) {
      await _performAILivenessCheck(knownFaces.first, faces, rotatedImage);
    } else {
      _performRuleBasedLivenessCheck(knownFaces.first, faces, rotatedImage);
    }
  } else {
    setState(() {
      _showRecognitionOverlay = false;
      _overlayName = null;
      _isRecognitionSuccess = false;
    });
    
    print("\n🚫 NO VERIFIED KNOWN FACES");
    setState(() {});
  }

  if (_shouldRegisterFace && faces.isNotEmpty) {
    _handleFaceRegistration(faces, rotatedImage);
  }
  
  print("\n" + "="*60 + "\n");
}


Future<void> _performAILivenessCheck(Recognition knownFace, List<Face> faces, img.Image rotatedImage) async {
  print("\n🔐 AI LIVENESS CHECK");
  
  // ✅ SPEAK IMMEDIATELY (don't wait for liveness)
  print("🔊 Speaking name (AI liveness mode)...");
  _ttsService.speakClockIn(knownFace.name);
  
  // Extract face crop for AI liveness
  final faceRect = knownFace.location;
  int left = faceRect.left.toInt().clamp(0, rotatedImage.width - 1);
  int top = faceRect.top.toInt().clamp(0, rotatedImage.height - 1);
  int width = faceRect.width.toInt().clamp(1, rotatedImage.width - left);
  int height = faceRect.height.toInt().clamp(1, rotatedImage.height - top);
  
  final faceCrop = img.copyCrop(
    rotatedImage,
    x: left,
    y: top,
    width: width,
    height: height,
  );
  
  // Run AI liveness check
  _lastAILivenessResult = await _aiLivenessService.checkLiveness(faceCrop);
  
  print("   Decision: ${_lastAILivenessResult!.decision.name}");
  print("   Real score: ${_lastAILivenessResult!.realScore.toStringAsFixed(2)}");
  print("   Fake score: ${_lastAILivenessResult!.fakeScore.toStringAsFixed(2)}");
  print("   Confidence: ${_lastAILivenessResult!.confidence.toStringAsFixed(2)}");
  
  // Get stable result from history
  final stableResult = _aiLivenessService.getStableResult();
  
  if (stableResult.isReal && stableResult.decision == LivenessDecision.real) {
    print("   ✅ AI confirms: REAL PERSON (Stable)");
    await _proceedWithClockIn(knownFace, rotatedImage);
  } else if (stableResult.decision == LivenessDecision.fake) {
    print("   ❌ AI detected: SPOOF/FAKE");
    setState(() {
      _faceQualityMessage = "⚠️ Spoofing attempt detected";
    });
  } else {
    print("   ⏳ AI result: UNCERTAIN - Need more frames");
    
    // ✅ ADD: Auto-proceed after 3 uncertain results (model not working)
    if (_aiLivenessService.getStableResult().decision == LivenessDecision.uncertain) {
      print("   ⚠️ AI liveness uncertain - auto-proceeding anyway");
      await _proceedWithClockIn(knownFace, rotatedImage);
    }
    
    setState(() {
      _faceQualityMessage = _aiLivenessService.getStatusMessage(stableResult);
    });
  }
}


// ✅ NEW: Advanced Liveness Check with 5-layer security
Future<void> _performAdvancedLivenessCheck(Recognition knownFace, List<Face> faces, CameraImage frame) async {
  print("\n🛡️ STARTING ADVANCED LIVENESS CHECK (5-Layer Security)");
  
  await _advancedLivenessService.checkLiveness(faces, frame);
  
  if (_advancedLivenessService.state == LivenessState.waitingForResponse ||
      _advancedLivenessService.state == LivenessState.generatingChallenge) {
    if (!_showAdvancedLivenessUI) {
      setState(() {
        _showAdvancedLivenessUI = true;
      });
      print("👁️ Showing challenge UI...");
    }
    return; // Wait for user to complete challenge
  }
  
  if (_advancedLivenessService.isLive) {
    print("✅ ADVANCED LIVENESS VERIFIED - All 5 layers passed!");
   
    
    setState(() {
      _isRecognitionSuccess = true;
      _showAdvancedLivenessUI = false;
    });
    
    // Proceed to clock-in
    _handleClockIn();
  } else {
    print("❌ ADVANCED LIVENESS FAILED");
    setState(() {
      _showAdvancedLivenessUI = false;
    });
    _showLivenessFailureDialog();
  }
}

void _performRuleBasedLivenessCheck(Recognition knownFace, List<Face> faces, img.Image rotatedImage) {
  // ✅ SPEAK IMMEDIATELY (before liveness check)
  print("\n🔊 Speaking name (rule-based liveness mode)...");
  _ttsService.speakClockIn(knownFace.name);
  
  _livenessService.checkLiveness(faces);
  _updateLivenessUI();

  print("\n👁️ LIVENESS STATUS CHECK:");
  print("  Progress: ${(_livenessService.getLivenessProgress() * 100).toStringAsFixed(0)}%");
  print("  Status: ${_livenessService.getLivenessStatus()}");
  print("  Is Live: ${_livenessService.isLive}");
  print("  Consecutive Frames: ${_livenessService.consecutiveFrames}/${LivenessDetectionService.REQUIRED_CONSECUTIVE_FRAMES}");
  print("  Blink Count: ${_livenessService.blinkCount}/${LivenessDetectionService.REQUIRED_BLINKS}");
  print("  Has Movement: ${_livenessService.hasMovement}");

  if (_livenessService.isLive) {
    print("\n🎉 ALL CHECKS PASSED - PROCEEDING TO CLOCK-IN");
    _proceedWithClockIn(knownFace, rotatedImage);
  } else {
    print("\n⏳ WAITING FOR LIVENESS VERIFICATION");
    print("   Face: ✅ Verified as ${knownFace.name}");
    print("   Liveness: ⏳ ${_livenessService.getLivenessStatus()}");
    setState(() {});
  }
}

// ✅ REPLACE your _verifyEmployeeLocation method with this fixed version:

Future<LocationVerificationResult> _verifyEmployeeLocation(String employeeName) async {
  // ✅ CHECK: Is geofencing enabled in settings?
  try {
    final settingsBox = await Hive.openBox('settingsBox');
    bool geofencingEnabled = settingsBox.get('enableGeofencing', defaultValue: false);
    
    if (!geofencingEnabled) {
      print("🔓 Geofencing DISABLED in settings - Skipping location check");
      return LocationVerificationResult(
        isValid: true,
        reason: "Geofencing disabled in settings",
      );
    }
    
    print("🔒 Geofencing ENABLED - Performing location check");
    
    // Get employee ID
    final box = await Hive.openBox('faces');
    final faceData = box.get(employeeName);
    
    if (faceData == null || faceData['employeeId'] == null) {
      print("⚠️ No employee ID found for $employeeName");
      return LocationVerificationResult(
        isValid: true,
        reason: "No employee ID configured",
      );
    }
    
    String employeeId = faceData['employeeId'].toString();
    
    // Fetch assigned geofences
    if (_assignedGeofences.isEmpty) {
      _assignedGeofences = await _locationApi.getAssignedGeofences(employeeId);
      print("📍 Loaded ${_assignedGeofences.length} geofences");
    }
    
    // If no geofences assigned, allow clock-in
    if (_assignedGeofences.isEmpty) {
      print("⚠️ No geofences assigned to $employeeName - allowing clock-in");
      return LocationVerificationResult(
        isValid: true,
        reason: "No geofences configured",
      );
    }
    
    // Get current location
    Position? position = await _geofenceService.getCurrentLocation();
    
    if (position == null) {
      print("❌ Unable to get GPS location - allowing clock-in (lenient)");
      return LocationVerificationResult(
        isValid: true,
        reason: "GPS unavailable - proceeding without location check",
      );
    }
    
    print("📍 Current location: ${position.latitude}, ${position.longitude}");
    print("   Accuracy: ±${position.accuracy.toStringAsFixed(0)}m");
    
    // Check for spoofing
    if (_geofenceService.detectSpoofing(
      currentPosition: position,
      lastPosition: _lastPosition,
    )) {
      print("🚨 GPS SPOOFING DETECTED!");
      
      await _locationApi.reportViolation(
        employeeId: employeeId,
        latitude: position.latitude,
        longitude: position.longitude,
        reason: "GPS spoofing detected",
      );
      
      return LocationVerificationResult(
        isValid: false,
        reason: "Location spoofing detected. Contact your manager.",
      );
    }
    
    // Verify location against geofences
    final result = _geofenceService.verifyLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      assignedGeofences: _assignedGeofences,
    );
    
    print("\n📊 LOCATION VERIFICATION RESULT:");
    print("   Valid: ${result.isValid ? '✅' : '❌'}");
    if (result.isValid) {
      print("   Geofence: ${result.geofence!.name}");
      print("   Distance from center: ${result.distanceFromCenter!.toStringAsFixed(0)}m");
    } else {
      print("   Reason: ${result.reason}");
      if (result.nearestGeofence != null) {
        print("   Nearest: ${result.nearestGeofence!.name}");
        print("   Distance: ${result.distanceFromCenter!.toStringAsFixed(0)}m");
      }
    }
    
    // Log to server
    await _locationApi.logLocationVerification(
      employeeId: employeeId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      isValid: result.isValid,
      geofenceId: result.geofence?.id,
      distance: result.distanceFromCenter,
    );
    
    // Update last position for spoofing detection
    _lastPosition = position;
    
    return result;
    
  } catch (e) {
    print("❌ Location verification error: $e");
    print("⚠️ Allowing clock-in despite error (lenient approach)");
    
    return LocationVerificationResult(
      isValid: true,
      reason: "Location check failed - proceeding anyway",
    );
  }
}

// ✅ REPLACE your _showClockInMessage method with this:

void _showClockInMessage(String recognizedName) {
  print("\n🎬 Showing clock-in message for: $recognizedName");
  
  // Get current time
  final now = DateTime.now();
  final timeString = DateFormat('hh:mm a').format(now);
  
  // Show snackbar with name and time
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  recognizedName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Clocked in at $timeString',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFF10B981),
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.all(16),
    ),
  );
  
  // Reset state after showing message
  Future.delayed(Duration(milliseconds: 500), () {
    if (mounted) {
      setState(() {
        _isClockInInProgress = false;
        _personCooldowns[recognizedName] = DateTime.now();
        _isFaceRecognitionActive = true;
      });
      
      print("✅ $recognizedName is in cooldown for $COOLDOWN_SECONDS seconds");
    }
  });
}

// ✅ UPDATE your _proceedWithClockIn method - replace the section at the end:

Future<void> _proceedWithClockIn(Recognition recognized, img.Image rotatedImage) async {
  print("\n🎯 _proceedWithClockIn called for: ${recognized.name}");
  
  // ✅ STEP 1: Verify Location (only if enabled in settings)
  if (_locationEnabled) {
    print("\n📍 Checking location...");
    
    final locationCheck = await _verifyEmployeeLocation(recognized.name);
    
    if (!locationCheck.isValid) {
      _showLocationError(locationCheck);
      return; // ❌ Block clock-in
    }
    
    print("✅ Location verified: ${locationCheck.geofence?.name ?? 'Geofencing disabled'}");
  }
  
  // ✅ STEP 2: Set flag to prevent re-recognition
  setState(() {
    _isClockInInProgress = true;
  });
  
  // ✅ STEP 3: Continue with existing face recognition flow...
  setState(() {
    _isFaceRecognitionActive = false;
  });

  final faceImageBytes = Uint8List.fromList(img.encodeJpg(rotatedImage));
  final box = await Hive.openBox('faces');
  final faceData = box.get(recognized.name);

  if (faceData != null && faceData['employeeId'] != null) {
    String employeeId = faceData['employeeId'].toString();

    print("\n📞 CALLING CLOCK-IN API");
    print("   Employee Name: ${recognized.name}");
    print("   Employee ID: $employeeId");

    // ✅ ALWAYS call API
    try {
      sendDataToApi(
        type: 'clockIn',
        faceImage: faceImageBytes,
        employeeId: employeeId,
      );
      print("   ✅ API call initiated");
    } catch (e) {
      print("   ❌ API call failed: $e");
    }

    // ✅ ALWAYS show bottom message (no popup)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showClockInMessage(recognized.name);
    });
  }
}

void _showLocationError(LocationVerificationResult result) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.location_off, color: Color(0xFFEF4444), size: 32),
          SizedBox(width: 12),
          Text('Location Error'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.reason ?? "You are outside the authorized location.",
            style: TextStyle(fontSize: 16),
          ),
          if (result.nearestGeofence != null && result.distanceFromCenter != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 ${result.nearestGeofence!.name}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Distance: ${result.distanceFromCenter!.toStringAsFixed(0)}m away'),
                  Text('Required: Within ${result.nearestGeofence!.radiusMeters.toStringAsFixed(0)}m'),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _resetRecognition();
          },
          child: Text('OK'),
        ),
      ],
    ),
  );
}

// ✅ REPLACE your _showClockInMessage method with this:


 void _handleFaceRegistration(List<Face> faces, img.Image rotatedImage) {
    final face = faces.first;
    final croppedFace = _faceRecognitionService.cropFaceFromImage(rotatedImage, face);

    final faceRect = face.boundingBox;
    final recognition = _recognitions.isNotEmpty
        ? _recognitions.first
        : Recognition("", faceRect, [0.0], 0.0);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => FaceRegistrationPage(
                croppedFace: croppedFace,
                recognition: recognition,
              )),
    );

    _shouldRegisterFace = false;
  }

 void _resetRecognition() {
  setState(() {
    _isClockInInProgress = false;
  });
  
  _resetForRetry();
}
  void pauseFaceRecognition() {
    print('⛔ Face Recognition Paused');
    setState(() => _isFaceRecognitionActive = false);
  }

  void resumeFaceRecognition() {
    print('▶️ Face Recognition Resumed');
    _resetAllState();
  }

  Future<void> _toggleCameraDirection() async {
    await _cameraService.toggleCameraDirection();
    setState(() {});
  }

 @override
void dispose() {
  print("\n🛑 FACE RECOGNITION SCREEN DISPOSED");
  _cameraService.dispose();
  _faceDetectionService.dispose();
  _aiLivenessService.dispose();
  _ttsService.dispose(); 
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 254, 254),
        appBar: _buildAppBar(),
        body: _buildBody(size),
      ),
    );
  }

PreferredSizeWidget _buildAppBar() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(65),
    child: AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 254, 254),
      centerTitle: true,
      title: Column(
        children: [
          const Text(
            'Kiosk Mode',
            style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontSize: 20,
            ),
          ),
          // Show AI/Rule-based status
          Text(
            _useAdvancedLiveness 
              ? '🛡️ Advanced (5-Layer)' 
              : (_useAILiveness ? '🤖 AI Liveness' : '👁️ Rule-based'),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/settings.svg',
          width: 36,
          height: 36,
          color: Colors.black,
        ),
        onPressed: () {
          context.read<LoginController>().openSettingsGate(
                context,
                pauseFaceRecognition,
                resumeFaceRecognition,
              );
        },
      ),
      actions: [
        // ✅ NEW: Flashlight button with low-light indicator
        Stack(
          children: [
            IconButton(
              icon: Icon(
                _isFlashlightOn ? Icons.flash_on : Icons.flash_off,
                color: _isFlashlightOn ? Color(0xFFFBBF24) : Colors.grey,
                size: 30,
              ),
              onPressed: _toggleFlashlight,
              tooltip: _isFlashlightOn ? 'Turn Off Light' : 'Turn On Light',
            ),
            // ✅ Low light warning indicator
            if (_isLowLight && !_isFlashlightOn)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        
        // Your existing buttons...
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/plus-circle.svg',
            width: 36,
            height: 36,
            color: Colors.black,
          ),
          onPressed: () => _showRegistrationOptions(),
        ),
        
        // IconButton(
        //   icon: const Icon(Icons.delete_forever, color: Colors.red),
        //   onPressed: _clearAllRegistrations,
        // ),
        
        // AI Liveness toggle
        IconButton(
          icon: Icon(
            _useAILiveness ? Icons.psychology : Icons.remove_red_eye,
            color: _useAILiveness ? Colors.purple : Colors.blue,
          ),
          onPressed: () async {
            setState(() => _useAILiveness = !_useAILiveness);
            final settingsBox = await Hive.openBox('settingsBox');
            await settingsBox.put('useAILiveness', _useAILiveness);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_useAILiveness 
                  ? '🤖 AI Liveness Enabled' 
                  : '👁️ Rule-based Liveness Enabled'
                ),
                duration: Duration(seconds: 2),
              ),
            );
            
            _resetForRetry();
          },
        ),
        
        // ✅ NEW: Advanced Liveness toggle
        IconButton(
          icon: Icon(
            _useAdvancedLiveness ? Icons.security : Icons.shield_outlined,
            color: _useAdvancedLiveness ? Colors.green : Colors.grey,
          ),
          onPressed: () async {
            setState(() {
              _useAdvancedLiveness = !_useAdvancedLiveness;
              if (_useAdvancedLiveness) {
                _useAILiveness = false; // Disable AI when Advanced is on
              }
            });
            final settingsBox = await Hive.openBox('settingsBox');
            await settingsBox.put('useAdvancedLiveness', _useAdvancedLiveness);
            if (_useAdvancedLiveness) {
              await settingsBox.put('useAILiveness', false);
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_useAdvancedLiveness 
                  ? '🛡️ Advanced Liveness Enabled (5-Layer)' 
                  : '👁️ Basic Liveness'),
                duration: Duration(seconds: 2),
              ),
            );
            
            _resetForRetry();
          },
        ),
      ],
    ),
  );
}
  
  void _showRegistrationOptions() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Register New Face',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose registration method:'),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.face_retouching_natural),
                  label: const Text(
                    'Smart Registration\n(Just 3 photos - Recommended)',
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _startSimplePhotoRegistration();
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Quick Single Capture'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _startQuickCapture();
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }

  void _startSimplePhotoRegistration() {
    pauseFaceRecognition();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimplePhotoRegistrationPage(),
      ),
    ).then((embeddings) {
      resumeFaceRecognition();
      
      if (embeddings != null && embeddings is List<List<double>>) {
        print("✅ Received ${embeddings.length} embeddings from registration");
        
        pauseFaceRecognition();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FaceRegistrationPage(
              multiAngleEmbeddings: embeddings,
            ),
          ),
        ).then((_) {
          resumeFaceRecognition();
        });
      }
    });
  }

  void _startQuickCapture() {
    setState(() {
      _shouldRegisterFace = true;
    });
  }

  Future<Uint8List> _captureFaceImage() async {
    try {
      XFile imageFile = await _cameraService.takePicture();
      return await imageFile.readAsBytes();
    } catch (e) {
      print('Error capturing face image: $e');
      throw Exception('Failed to capture face image');
    }
  }

  Widget _buildBody(Size size) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              _buildCameraOrConfirmationArea(size),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraOrConfirmationArea(Size size) {
    if (!_cameraService.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_livenessService.isLive &&
        _recognitions.isNotEmpty &&
        _useLivenessConfirmationCard) {
      return FutureBuilder<Uint8List>(
        future: _captureFaceImage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error capturing image: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return LivenessConfirmationCard(
               recognizedName: _recognitions[0].name,
              cameraController: _cameraService.cameraController!,
              onRetry: _resetRecognition,
              onClockIn: _handleClockIn,
              lastClockOutTime: _lastClockOutTime,
              faceImage: snapshot.data!,
            );
          } else {
            return const Center(child: Text('Failed to capture image'));
          }
        },
      );
    }

    return _buildCameraPreview(size);
  }


Widget _buildCameraPreview(Size size) {
  return Column(
    children: [
      Expanded(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Camera preview
            Center(
              child: Container(
                width: size.width * 0.9,
                height: size.width * 1.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera feed
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: CameraPreview(_cameraService.cameraController!),
                      ),
                      
                      // Vignette effect
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                            stops: [0.6, 1.0],
                            radius: 1.0,
                          ),
                        ),
                      ),

                      AnimatedBorderScanner(
                        faceDetected: _detectedFace != null && !_isClockInInProgress,
                        faceRecognized: _recognitions.isNotEmpty && 
                                       _recognitions.first.name != "Unknown" && 
                                       _recognitions.first.name != "Unregister" &&
                                       !_isClockInInProgress,  
                        livenessComplete: (_useAILiveness 
                          ? (_lastAILivenessResult?.isReal ?? false)
                          : _livenessService.isLive) && !_isClockInInProgress,  
                        recognizedName: (_recognitions.isNotEmpty && 
                                       _recognitions.first.name != "Unknown" && 
                                       _recognitions.first.name != "Unregister" &&
                                       !_isClockInInProgress)  
                          ? _recognitions.first.name 
                          : null,
                        confidence: (_recognitions.isNotEmpty && 
                                   _recognitions.first.name != "Unknown" && 
                                   _recognitions.first.name != "Unregister" &&
                                   !_isClockInInProgress)  
                          ? (1 - _recognitions.first.distance) 
                          : null,
                        isLowLight: _isLowLight,
                      ), // ✅ Added missing closing parenthesis
                    ],
                  ),
                ),
              ),
            ),

            // Liveness progress
            if (_showLivenessProgress && !_showSuccessFeedback)
              Positioned(
                top: size.width * 0.1,
                child: LivenessProgressOverlay(
                  progress: _livenessProgress,
                  statusMessage: _livenessStatusMessage,
                  isComplete: _useAILiveness 
                    ? (_lastAILivenessResult?.isReal ?? false)
                    : _livenessService.isLive,
                ),
              ),

            // Advanced Liveness Challenge Overlay
            if (_showAdvancedLivenessUI && _useAdvancedLiveness)
              Positioned.fill(
                child: AdvancedLivenessChallengeOverlay(
                  livenessService: _advancedLivenessService,
                  onComplete: () {
                    setState(() {
                      _showAdvancedLivenessUI = false;
                    });
                    print("✅ Advanced liveness verification completed!");
                  },
                  onFailed: () {
                    setState(() {
                      _showAdvancedLivenessUI = false;
                    });
                    _showLivenessFailureDialog();
                  },
                ),
              ),

            // Quality indicators at top
            if (_detectedFace != null && !_showSuccessFeedback)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _faceQualityMessage == null 
                        ? Color(0xFF10B981).withOpacity(0.6)
                        : Color(0xFFFBBF24).withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_faceQualityMessage == null 
                          ? Color(0xFF10B981) 
                          : Color(0xFFFBBF24)
                        ).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_faceQualityMessage == null 
                            ? Color(0xFF10B981) 
                            : Color(0xFFFBBF24)
                          ).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _faceQualityMessage == null 
                            ? Icons.check_circle 
                            : Icons.warning_amber_rounded,
                          color: _faceQualityMessage == null 
                            ? Color(0xFF10B981) 
                            : Color(0xFFFBBF24),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _faceQualityMessage ?? 'Face detected - Good quality',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
  );
}
// Helper method (keep this)
Widget _buildStatusIndicator({
  required IconData icon,
  required bool isActive,
  required String label,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isActive 
        ? Color(0xFF10B981).withOpacity(0.2)
        : Colors.grey.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isActive 
          ? Color(0xFF10B981).withOpacity(0.5)
          : Colors.grey.withOpacity(0.3),
        width: 1.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Color(0xFF10B981) : Colors.grey,
          size: 16,
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
  
  
  Future<void> _handleClockIn() async {
    try {
      XFile imageFile = await _cameraService.takePicture();
      Uint8List faceImage = await imageFile.readAsBytes();

      if (_recognitions.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmPage(
              recognizedName: _recognitions[0].name, 
              faceImage: faceImage,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No face recognized. Please try again.')));
      }
    } catch (e) {
      print('Error capturing image: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _clearAllRegistrations() async {
    final box = await Hive.openBox('faces');
    await box.clear();
    print("✅ All old registrations cleared!");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All registrations cleared. Please re-register.'),
        backgroundColor: Colors.orange,
      ),
    );
    
    setState(() {});
  }

  void _updateLivenessUI() {
    if (mounted) {
      setState(() {
        _livenessProgress = _livenessService.getLivenessProgress();
        _livenessStatusMessage = _livenessService.getLivenessStatus();
        _showLivenessProgress = _livenessProgress > 0 && !_livenessService.isLive;
      });
    }
  }

  void _updateFaceQualityFeedback(Face? face) {
    if (face == null) {
      _faceQualityMessage = null;
      _detectedFace = null;
      return;
    }

    _detectedFace = face;
    final faceRect = face.boundingBox;
    
    if (faceRect.width < 80 || faceRect.height < 80) {
      _faceQualityMessage = "Move closer";
    } else if (faceRect.width > MediaQuery.of(context).size.width * 0.8) {
      _faceQualityMessage = "Move back";
    } else if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 25) {
      _faceQualityMessage = "Face camera directly";
    } else if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null &&
        (face.leftEyeOpenProbability! < 0.5 || face.rightEyeOpenProbability! < 0.5)) {
      _faceQualityMessage = "Keep eyes open";
    } else {
      _faceQualityMessage = null;
    }
  }

  void _showSuccessMessage(String name) {
    setState(() {
      _showSuccessFeedback = true;
      _feedbackName = name;
      _feedbackMessage = "You're clocked in";
      _showFaceGuide = false;
      _showLivenessProgress = false;
    });
  }

  void _dismissFeedback() {
    setState(() {
      _showSuccessFeedback = false;
    });
    _resetRecognition();
  }

  void _checkLightingConditions(CameraImage image) {
  // Simple brightness detection from camera image
  // Calculate average brightness from first 100 pixels
  int sum = 0;
  int sampleSize = min(100, image.planes[0].bytes.length);
  
  for (int i = 0; i < sampleSize; i++) {
    sum += image.planes[0].bytes[i];
  }
  
  double avgBrightness = sum / sampleSize;
  
  // If brightness is below 50 (on scale of 0-255), it's low light
  bool isCurrentlyLowLight = avgBrightness < 50;
  
  if (isCurrentlyLowLight != _isLowLight) {
    setState(() {
      _isLowLight = isCurrentlyLowLight;
    });
    
    if (isCurrentlyLowLight) {
      print("⚠️ Low light detected - Consider turning on flashlight");
    }
  }
}

Future<void> _toggleFlashlight() async {
  try {
    final controller = _cameraService.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isFlashlightOn = !_isFlashlightOn;
    });

    await controller.setFlashMode(
      _isFlashlightOn ? FlashMode.torch : FlashMode.off
    );

    print("💡 Flashlight ${_isFlashlightOn ? 'ON' : 'OFF'}");
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFlashlightOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(_isFlashlightOn ? 'Flashlight ON' : 'Flashlight OFF'),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: _isFlashlightOn ? Color(0xFFFBBF24) : Colors.grey,
      ),
    );
  } catch (e) {
    print("❌ Flashlight error: $e");
  }
}


void _showLivenessFailureDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 10),
          Text('Liveness Check Failed'),
        ],
      ),
      content: Text(
        'We could not verify you are a real person. This could be due to:\n\n'
        '• Photo or video being used\n'
        '• Poor lighting conditions\n'
        '• Not following instructions\n\n'
        'Please try again.',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _resetForRetry();
          },
          child: Text('Try Again'),
        ),
      ],
    ),
  );
}
}