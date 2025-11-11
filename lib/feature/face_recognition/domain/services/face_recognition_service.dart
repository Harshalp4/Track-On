import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:track_on/core/ML/Recognition.dart';
import 'package:track_on/core/ML/RecognizerV2.dart';

/// ✅ ORIGINAL VERSION - No coordinate transformation
class FaceRecognitionService {
  final RecognizerV2 _recognizer = RecognizerV2();

  /// ✅ MAIN METHOD: Recognize faces (ORIGINAL WORKING VERSION)
  List<Recognition> recognizeFaces(List<Face> faces, img.Image processedImage) {
    print("\n═══════════════════════════════════════");
    print("🔍 FACE RECOGNITION");
    print("═══════════════════════════════════════");
    print("📊 Faces detected: ${faces.length}");
    print("🖼️ Image: ${processedImage.width}x${processedImage.height}");

    List<Recognition> recognitions = [];

    for (int i = 0; i < faces.length; i++) {
      Face face = faces[i];
      final faceRect = face.boundingBox;

      print("\n👤 Face ${i + 1}:");

      // Ensure crop coordinates are within bounds
      int left = faceRect.left.toInt().clamp(0, processedImage.width - 1);
      int top = faceRect.top.toInt().clamp(0, processedImage.height - 1);
      int width = faceRect.width.toInt().clamp(1, processedImage.width - left);
      int height = faceRect.height.toInt().clamp(1, processedImage.height - top);

      try {
        print("  📐 Crop bounds: ($left, $top, $width, $height)");
        
        final croppedFace = img.copyCrop(
          processedImage,
          x: left,
          y: top,
          width: width,
          height: height,
        );

        print("  📏 Cropped size: ${croppedFace.width}x${croppedFace.height}");
        
        // ✅ RESIZE to 112x112 BEFORE recognition
        final resizedFace = img.copyResize(croppedFace, width: 112, height: 112);
        print("  📏 Resized to: 112x112");

        // ✅ Call enhanced recognizer
        final recognition = _recognizer.recognize(resizedFace, faceRect);

        print("  🎯 Primary Result: ${recognition.name}");
        print("  📏 Distance: ${recognition.distance.toStringAsFixed(4)}");
        
        if (recognition.secondBestName != null) {
          print("  📊 Runner-up: ${recognition.secondBestName} (${recognition.secondBestDistance!.toStringAsFixed(4)})");
          print("  📈 Confidence Gap: ${recognition.confidenceGap!.toStringAsFixed(4)}");
        }

        // Mark unknowns as "Unregister" for UI
        if (recognition.name == "Unknown") {
          print("  ❌ Marking as Unregister");
          recognition.name = "Unregister";
        } else {
          double confidence = (1 - recognition.distance) * 100;
          print("  ✅ VERIFIED MATCH: ${recognition.name}");
          print("  🎯 Confidence: ${confidence.toStringAsFixed(1)}%");
        }

        recognitions.add(recognition);
      } catch (e) {
        print("  ❌ ERROR: $e");
        final defaultRecognition = Recognition(
          "Unregister", 
          faceRect, 
          [0.0], 
          1.0,
        );
        recognitions.add(defaultRecognition);
      }
    }

    print("\n═══════════════════════════════════════");
    print("✅ RECOGNITION COMPLETE");
    final recognized = recognitions.where((r) => r.name != "Unregister").length;
    print("📊 ${recognized}/${recognitions.length} faces recognized");
    print("═══════════════════════════════════════\n");
    
    return recognitions;
  }
 
  /// ✅ Crop face from image
  img.Image cropFaceFromImage(img.Image image, Face face) {
    final faceRect = face.boundingBox;

    int left = faceRect.left.toInt().clamp(0, image.width - 1);
    int top = faceRect.top.toInt().clamp(0, image.height - 1);
    int width = faceRect.width.toInt().clamp(1, image.width - left);
    int height = faceRect.height.toInt().clamp(1, image.height - top);

    return img.copyCrop(
      image,
      x: left,
      y: top,
      width: width,
      height: height,
    );
  }
  
  /// ✅ Get recognizer instance (for registration)
  RecognizerV2 get recognizer => _recognizer;
}