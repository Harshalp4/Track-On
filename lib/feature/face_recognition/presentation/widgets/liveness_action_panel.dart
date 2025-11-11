import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class LivenessDetectionService {
  bool isLive = false;
  
  // ✅ PRODUCTION: More sophisticated liveness detection
  int _consecutiveFramesWithGoodFace = 0;
  int _blinkCount = 0;
  bool _previousEyesOpen = true;
  double? _previousHeadEulerY;
  bool _hasMovement = false;
  
  // ✅ PRODUCTION SETTINGS: Stricter requirements
  static const int REQUIRED_CONSECUTIVE_FRAMES = 15; // Must see face for 15+ frames
  static const int REQUIRED_BLINKS = 1; // At least 1 blink detected
  static const double MIN_HEAD_MOVEMENT = 3.0; // Minimum head rotation in degrees
  static const double EYE_OPEN_PROBABILITY = 0.5; // Threshold for eyes open/closed
  
  // Anti-spoofing: Check for real human characteristics
  void checkLiveness(List<Face> faces) {
    if (faces.isEmpty) {
      _resetDetection();
      return;
    }

    Face face = faces.first;
    
    print("\n🔍 LIVENESS CHECK:");
    
    // ✅ Check 1: Face quality metrics
    bool hasSmilingProbability = face.smilingProbability != null;
    bool hasLeftEye = face.leftEyeOpenProbability != null;
    bool hasRightEye = face.rightEyeOpenProbability != null;
    bool hasHeadPose = face.headEulerAngleY != null;
    
    print("  👁️ Left eye probability: ${face.leftEyeOpenProbability?.toStringAsFixed(2)}");
    print("  👁️ Right eye probability: ${face.rightEyeOpenProbability?.toStringAsFixed(2)}");
    print("  😊 Smiling probability: ${face.smilingProbability?.toStringAsFixed(2)}");
    print("  🔄 Head angle Y: ${face.headEulerAngleY?.toStringAsFixed(2)}°");
    
    // ✅ Check 2: Blink detection (proves real eyes)
    if (hasLeftEye && hasRightEye) {
      double leftEye = face.leftEyeOpenProbability!;
      double rightEye = face.rightEyeOpenProbability!;
      
      bool currentEyesOpen = (leftEye > EYE_OPEN_PROBABILITY && 
                              rightEye > EYE_OPEN_PROBABILITY);
      
      // Detect blink: eyes were open, now closed, then open again
      if (_previousEyesOpen && !currentEyesOpen) {
        _blinkCount++;
        print("  👁️ BLINK DETECTED! Total blinks: $_blinkCount");
      }
      
      _previousEyesOpen = currentEyesOpen;
    }
    
    // ✅ Check 3: Head movement detection (proves 3D face, not photo)
    if (hasHeadPose) {
      double currentAngleY = face.headEulerAngleY!;
      
      if (_previousHeadEulerY != null) {
        double movement = (currentAngleY - _previousHeadEulerY!).abs();
        
        if (movement > MIN_HEAD_MOVEMENT) {
          _hasMovement = true;
          print("  🔄 HEAD MOVEMENT DETECTED: ${movement.toStringAsFixed(2)}°");
        }
      }
      
      _previousHeadEulerY = currentAngleY;
    }
    
    // ✅ Check 4: Consecutive frames (ensures sustained detection)
    if (hasSmilingProbability && hasLeftEye && hasRightEye && hasHeadPose) {
      _consecutiveFramesWithGoodFace++;
      print("  ✅ Good face frame: $_consecutiveFramesWithGoodFace/$REQUIRED_CONSECUTIVE_FRAMES");
    } else {
      _consecutiveFramesWithGoodFace = 0;
      print("  ❌ Poor quality face - resetting counter");
    }
    
    // ✅ PRODUCTION LIVENESS CRITERIA:
    // 1. Face detected for sufficient consecutive frames (stability)
    // 2. At least one blink detected (real eyes)
    // 3. Some head movement detected (3D face, not photo)
    
    bool sufficientFrames = _consecutiveFramesWithGoodFace >= REQUIRED_CONSECUTIVE_FRAMES;
    bool hasBlinkEvidence = _blinkCount >= REQUIRED_BLINKS;
    bool hasMovementEvidence = _hasMovement;
    
    print("\n  📊 LIVENESS CRITERIA:");
    print("  ${sufficientFrames ? '✅' : '❌'} Consecutive frames: $_consecutiveFramesWithGoodFace/$REQUIRED_CONSECUTIVE_FRAMES");
    print("  ${hasBlinkEvidence ? '✅' : '❌'} Blinks detected: $_blinkCount/$REQUIRED_BLINKS");
    print("  ${hasMovementEvidence ? '✅' : '❌'} Head movement: $_hasMovement");
    
    // ✅ All criteria must pass for liveness
    if (sufficientFrames && hasBlinkEvidence && hasMovementEvidence) {
      isLive = true;
      print("  🎉 LIVENESS CONFIRMED!\n");
    } else {
      isLive = false;
      print("  ⏳ Waiting for all criteria...\n");
    }
  }
  
  void _resetDetection() {
    _consecutiveFramesWithGoodFace = 0;
    // Don't reset blink count and movement - accumulate over session
  }
  
  // ✅ Call this when starting a new recognition session
  void resetSession() {
    isLive = false;
    _consecutiveFramesWithGoodFace = 0;
    _blinkCount = 0;
    _previousEyesOpen = true;
    _previousHeadEulerY = null;
    _hasMovement = false;
    print("🔄 Liveness detection session reset");
  }
  
  // ✅ Get detailed status for UI display
  String getLivenessStatus() {
    if (isLive) return "✅ Live Person Detected";
    
    List<String> pending = [];
    
    if (_consecutiveFramesWithGoodFace < REQUIRED_CONSECUTIVE_FRAMES) {
      pending.add("Hold steady (${_consecutiveFramesWithGoodFace}/$REQUIRED_CONSECUTIVE_FRAMES)");
    }
    
    if (_blinkCount < REQUIRED_BLINKS) {
      pending.add("Please blink");
    }
    
    if (!_hasMovement) {
      pending.add("Move your head slightly");
    }
    
    return pending.isEmpty ? "Checking..." : pending.join(" • ");
  }
  
  // ✅ Get progress percentage for UI
  double getLivenessProgress() {
    int completed = 0;
    int total = 3;
    
    if (_consecutiveFramesWithGoodFace >= REQUIRED_CONSECUTIVE_FRAMES) completed++;
    if (_blinkCount >= REQUIRED_BLINKS) completed++;
    if (_hasMovement) completed++;
    
    return completed / total;
  }
}