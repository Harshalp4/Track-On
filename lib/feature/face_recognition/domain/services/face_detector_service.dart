import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';

class FaceDetectionService {
  late FaceDetector _faceDetector;
  
  FaceDetectionService() {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<List<Face>> detectFaces(InputImage inputImage) async {
    try {
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      print('Error detecting faces: $e');
      return [];
    }
  }

  InputImage? getInputImageFromFrame(
    CameraImage cameraImage, 
    CameraDescription cameraDescription,
    CameraLensDirection cameraDirection
  ) {
    final sensorOrientation = cameraDescription.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };

      var rotationCompensation = orientations[DeviceOrientation.portraitUp];
      if (rotationCompensation == null) return null;

      if (cameraDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (cameraImage.planes.length != 1) return null;
    final plane = cameraImage.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void dispose() {
    _faceDetector.close();
  }
}