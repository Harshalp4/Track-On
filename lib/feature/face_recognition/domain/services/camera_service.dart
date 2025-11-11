import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:track_on/main.dart';

class CameraService {
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  CameraLensDirection _cameraDirection = CameraLensDirection.front;
  Function(CameraImage)? _imageStreamCallback;

  bool get isInitialized => _cameraController?.value.isInitialized ?? false;
  CameraController? get cameraController => _cameraController;
  CameraLensDirection get cameraDirection => _cameraDirection;
  CameraDescription? get cameraDescription => _cameraDescription;

  Future<void> initialize(Function(CameraImage) onImage) async {
    _imageStreamCallback = onImage;
    _cameraDescription = cameras[1]; // Front camera by default
    await _initializeController();
  }

  Future<void> _initializeController() async {
    _cameraController = CameraController(
      _cameraDescription!,
      ResolutionPreset.medium,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_imageStreamCallback!);
  }

  Future<void> toggleCameraDirection() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();

    // Toggle camera direction
    if (_cameraDirection == CameraLensDirection.back) {
      _cameraDirection = CameraLensDirection.front;
      _cameraDescription = cameras[1];
    } else {
      _cameraDirection = CameraLensDirection.back;
      _cameraDescription = cameras[0];
    }

    await _initializeController();
  }

  Future<XFile> takePicture() async {
    return await _cameraController!.takePicture();
  }

  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
  }
}