import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// ✅ FACE QUALITY ASSESSMENT SERVICE
/// Validates face quality before registration and during recognition
/// Checks: Blur, Lighting, Pose, Occlusion, Size
class FaceQualityService {
  // ✅ Quality thresholds
  static const double MIN_FACE_SIZE = 80.0;           // Minimum face size in pixels
  static const double MAX_HEAD_YAW = 25.0;            // Max head rotation (degrees)
  static const double MAX_HEAD_PITCH = 20.0;          // Max head tilt up/down
  static const double MIN_EYE_OPEN_PROB = 0.5;        // Eyes must be open
  static const double MIN_BRIGHTNESS = 40.0;          // Minimum average brightness
  static const double MAX_BRIGHTNESS = 220.0;         // Maximum average brightness
  static const double MIN_SHARPNESS = 0.3;            // Minimum sharpness score
  static const double OVERALL_QUALITY_THRESHOLD = 0.6; // Minimum overall quality
  
  /// ✅ MAIN METHOD: Comprehensive quality assessment
  FaceQualityResult assessQuality(img.Image faceImage, Face? faceMetadata) {
    print("\n📸 FACE QUALITY ASSESSMENT");
    print("="*50);
    
    Map<String, double> scores = {};
    List<String> issues = [];
    List<String> warnings = [];
    
    // ✅ CHECK 1: Face size
    var sizeScore = _checkFaceSize(faceImage, faceMetadata);
    scores['size'] = sizeScore.score;
    if (sizeScore.score < 0.5) {
      issues.add(sizeScore.message);
    } else if (sizeScore.score < 0.8) {
      warnings.add(sizeScore.message);
    }
    print("  Size: ${sizeScore.score.toStringAsFixed(2)} - ${sizeScore.message}");
    
    // ✅ CHECK 2: Head pose
    var poseScore = _checkHeadPose(faceMetadata);
    scores['pose'] = poseScore.score;
    if (poseScore.score < 0.5) {
      issues.add(poseScore.message);
    } else if (poseScore.score < 0.8) {
      warnings.add(poseScore.message);
    }
    print("  Pose: ${poseScore.score.toStringAsFixed(2)} - ${poseScore.message}");
    
    // ✅ CHECK 3: Eye openness
    var eyeScore = _checkEyeOpenness(faceMetadata);
    scores['eyes'] = eyeScore.score;
    if (eyeScore.score < 0.5) {
      issues.add(eyeScore.message);
    }
    print("  Eyes: ${eyeScore.score.toStringAsFixed(2)} - ${eyeScore.message}");
    
    // ✅ CHECK 4: Brightness/Lighting
    var brightnessScore = _checkBrightness(faceImage);
    scores['brightness'] = brightnessScore.score;
    if (brightnessScore.score < 0.5) {
      issues.add(brightnessScore.message);
    } else if (brightnessScore.score < 0.8) {
      warnings.add(brightnessScore.message);
    }
    print("  Brightness: ${brightnessScore.score.toStringAsFixed(2)} - ${brightnessScore.message}");
    
    // ✅ CHECK 5: Sharpness/Blur
    var sharpnessScore = _checkSharpness(faceImage);
    scores['sharpness'] = sharpnessScore.score;
    if (sharpnessScore.score < 0.5) {
      issues.add(sharpnessScore.message);
    } else if (sharpnessScore.score < 0.8) {
      warnings.add(sharpnessScore.message);
    }
    print("  Sharpness: ${sharpnessScore.score.toStringAsFixed(2)} - ${sharpnessScore.message}");
    
    // ✅ Calculate overall quality score (weighted average)
    double overallScore = (
      scores['size']! * 0.20 +
      scores['pose']! * 0.25 +
      scores['eyes']! * 0.15 +
      scores['brightness']! * 0.20 +
      scores['sharpness']! * 0.20
    );
    
    // ✅ Determine quality level
    QualityLevel level;
    if (overallScore >= 0.8) {
      level = QualityLevel.excellent;
    } else if (overallScore >= 0.6) {
      level = QualityLevel.good;
    } else if (overallScore >= 0.4) {
      level = QualityLevel.fair;
    } else {
      level = QualityLevel.poor;
    }
    
    bool isAcceptable = overallScore >= OVERALL_QUALITY_THRESHOLD && issues.isEmpty;
    
    print("\n📊 OVERALL QUALITY:");
    print("  Score: ${overallScore.toStringAsFixed(2)}");
    print("  Level: ${level.name.toUpperCase()}");
    print("  Acceptable: ${isAcceptable ? 'YES ✅' : 'NO ❌'}");
    print("="*50 + "\n");
    
    return FaceQualityResult(
      overallScore: overallScore,
      qualityLevel: level,
      isAcceptable: isAcceptable,
      scores: scores,
      issues: issues,
      warnings: warnings,
    );
  }
  
  /// ✅ Quick quality check (fast, for real-time feedback)
  QuickQualityCheck quickCheck(Face? face, img.Image? faceImage) {
    if (face == null) {
      return QuickQualityCheck(
        isGood: false,
        message: "No face detected",
        suggestion: "Position your face in frame",
      );
    }
    
    final faceRect = face.boundingBox;
    
    // Check 1: Face size
    if (faceRect.width < MIN_FACE_SIZE || faceRect.height < MIN_FACE_SIZE) {
      return QuickQualityCheck(
        isGood: false,
        message: "Face too small",
        suggestion: "Move closer to camera",
      );
    }
    
    if (faceImage != null && faceRect.width > faceImage.width * 0.8) {
      return QuickQualityCheck(
        isGood: false,
        message: "Face too close",
        suggestion: "Move back from camera",
      );
    }
    
    // Check 2: Head pose
    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > MAX_HEAD_YAW) {
      return QuickQualityCheck(
        isGood: false,
        message: "Head turned too much",
        suggestion: "Face camera directly",
      );
    }
    
    if (face.headEulerAngleX != null && face.headEulerAngleX!.abs() > MAX_HEAD_PITCH) {
      return QuickQualityCheck(
        isGood: false,
        message: "Head tilted",
        suggestion: "Look straight ahead",
      );
    }
    
    // Check 3: Eyes open
    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      if (face.leftEyeOpenProbability! < MIN_EYE_OPEN_PROB ||
          face.rightEyeOpenProbability! < MIN_EYE_OPEN_PROB) {
        return QuickQualityCheck(
          isGood: false,
          message: "Eyes not fully open",
          suggestion: "Keep eyes open",
        );
      }
    }
    
    // All checks passed
    return QuickQualityCheck(
      isGood: true,
      message: "Face quality good",
      suggestion: "Ready to capture",
    );
  }
  
  // ======================== INDIVIDUAL QUALITY CHECKS ========================
  
  QualityCheck _checkFaceSize(img.Image faceImage, Face? face) {
    double width = faceImage.width.toDouble();
    double height = faceImage.height.toDouble();
    
    if (face != null) {
      width = face.boundingBox.width;
      height = face.boundingBox.height;
    }
    
    double minDimension = min(width, height);
    
    if (minDimension < MIN_FACE_SIZE * 0.7) {
      return QualityCheck(0.2, "Face too small - move closer");
    } else if (minDimension < MIN_FACE_SIZE) {
      return QualityCheck(0.5, "Face slightly small");
    } else if (minDimension > 300) {
      return QualityCheck(1.0, "Face size optimal");
    } else if (minDimension > MIN_FACE_SIZE) {
      return QualityCheck(0.8, "Face size acceptable");
    }
    
    return QualityCheck(0.6, "Face size marginal");
  }
  
  QualityCheck _checkHeadPose(Face? face) {
    if (face == null) {
      return QualityCheck(0.5, "No pose data available");
    }
    
    double yaw = face.headEulerAngleY?.abs() ?? 0.0;
    double pitch = face.headEulerAngleX?.abs() ?? 0.0;
    double roll = face.headEulerAngleZ?.abs() ?? 0.0;
    
    // Calculate pose score (lower angles = better)
    double yawScore = 1.0 - (yaw / MAX_HEAD_YAW).clamp(0.0, 1.0);
    double pitchScore = 1.0 - (pitch / MAX_HEAD_PITCH).clamp(0.0, 1.0);
    double rollScore = 1.0 - (roll / 30.0).clamp(0.0, 1.0);
    
    double avgScore = (yawScore + pitchScore + rollScore) / 3;
    
    if (avgScore > 0.8) {
      return QualityCheck(avgScore, "Head pose frontal");
    } else if (avgScore > 0.6) {
      return QualityCheck(avgScore, "Head pose acceptable");
    } else if (avgScore > 0.4) {
      return QualityCheck(avgScore, "Head turned - face forward");
    } else {
      return QualityCheck(avgScore, "Head pose poor - look straight");
    }
  }
  
  QualityCheck _checkEyeOpenness(Face? face) {
    if (face == null ||
        face.leftEyeOpenProbability == null ||
        face.rightEyeOpenProbability == null) {
      return QualityCheck(0.7, "Eye data unavailable");
    }
    
    double leftEye = face.leftEyeOpenProbability!;
    double rightEye = face.rightEyeOpenProbability!;
    double avgEye = (leftEye + rightEye) / 2;
    
    if (avgEye > 0.8) {
      return QualityCheck(1.0, "Eyes fully open");
    } else if (avgEye > MIN_EYE_OPEN_PROB) {
      return QualityCheck(0.7, "Eyes open");
    } else if (avgEye > 0.3) {
      return QualityCheck(0.4, "Eyes partially closed");
    } else {
      return QualityCheck(0.1, "Eyes closed - open eyes");
    }
  }
  
  QualityCheck _checkBrightness(img.Image faceImage) {
    // Calculate average brightness
    double totalBrightness = 0.0;
    int pixelCount = 0;
    
    // Sample every 4th pixel for speed
    for (int y = 0; y < faceImage.height; y += 4) {
      for (int x = 0; x < faceImage.width; x += 4) {
        final pixel = faceImage.getPixel(x, y);
        // Calculate luminance
        double brightness = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
        totalBrightness += brightness;
        pixelCount++;
      }
    }
    
    double avgBrightness = totalBrightness / pixelCount;
    
    if (avgBrightness < MIN_BRIGHTNESS * 0.7) {
      return QualityCheck(0.2, "Too dark - improve lighting");
    } else if (avgBrightness < MIN_BRIGHTNESS) {
      return QualityCheck(0.5, "Slightly dark");
    } else if (avgBrightness > MAX_BRIGHTNESS * 1.1) {
      return QualityCheck(0.3, "Too bright - reduce lighting");
    } else if (avgBrightness > MAX_BRIGHTNESS) {
      return QualityCheck(0.6, "Slightly bright");
    } else if (avgBrightness > 80 && avgBrightness < 180) {
      return QualityCheck(1.0, "Lighting optimal");
    } else {
      return QualityCheck(0.8, "Lighting acceptable");
    }
  }
  
  QualityCheck _checkSharpness(img.Image faceImage) {
  // Use Laplacian variance to detect blur
  // Higher variance = sharper image
  
  // Convert to grayscale and calculate Laplacian
  double laplacianSum = 0.0;
  int count = 0;
  
  // ✅ IMPROVED: Sample center region (more important than edges)
  int startX = (faceImage.width * 0.2).toInt();
  int endX = (faceImage.width * 0.8).toInt();
  int startY = (faceImage.height * 0.2).toInt();
  int endY = (faceImage.height * 0.8).toInt();
  
  for (int y = startY; y < endY - 1; y++) {
    for (int x = startX; x < endX - 1; x++) {
      // Simple edge detection
      final curr = faceImage.getPixel(x, y);
      final right = faceImage.getPixel(x + 1, y);
      final down = faceImage.getPixel(x, y + 1);
      
      double currGray = 0.299 * curr.r + 0.587 * curr.g + 0.114 * curr.b;
      double rightGray = 0.299 * right.r + 0.587 * right.g + 0.114 * right.b;
      double downGray = 0.299 * down.r + 0.587 * down.g + 0.114 * down.b;
      
      double lap = (rightGray - currGray).abs() + (downGray - currGray).abs();
      laplacianSum += lap;
      count++;
    }
  }
  
  double sharpness = laplacianSum / count;
  
  // ✅ ADJUSTED: More lenient normalization for 5MP cameras
  // Original was: sharpness / 100.0
  // New: sharpness / 50.0 (more lenient)
  double normalizedSharpness = (sharpness / 50.0).clamp(0.0, 1.0);
  
  // ✅ ADJUSTED: More realistic thresholds
  if (normalizedSharpness > 0.4) {
    return QualityCheck(1.0, "Image sharp");
  } else if (normalizedSharpness > 0.20) {  // Changed from 0.3
    return QualityCheck(0.8, "Image acceptable");
  } else if (normalizedSharpness > 0.10) {  // Changed from 0.2
    return QualityCheck(0.6, "Slightly blurry but usable");
  } else {
    return QualityCheck(0.3, "Too blurry - hold steady");
  }
}
}

/// ✅ Quality check result
class QualityCheck {
  final double score;
  final String message;
  
  QualityCheck(this.score, this.message);
}

/// ✅ Quick quality check result
class QuickQualityCheck {
  final bool isGood;
  final String message;
  final String suggestion;
  
  QuickQualityCheck({
    required this.isGood,
    required this.message,
    required this.suggestion,
  });
}

/// ✅ Complete quality assessment result
class FaceQualityResult {
  final double overallScore;
  final QualityLevel qualityLevel;
  final bool isAcceptable;
  final Map<String, double> scores;
  final List<String> issues;
  final List<String> warnings;
  
  FaceQualityResult({
    required this.overallScore,
    required this.qualityLevel,
    required this.isAcceptable,
    required this.scores,
    required this.issues,
    required this.warnings,
  });
  
  String getSummary() {
    if (isAcceptable) {
      return "✅ Quality: ${qualityLevel.name.toUpperCase()}";
    } else {
      return "❌ Issues: ${issues.join(', ')}";
    }
  }
}

/// ✅ Quality level enum
enum QualityLevel {
  excellent,  // >0.8
  good,       // 0.6-0.8
  fair,       // 0.4-0.6
  poor,       // <0.4
}