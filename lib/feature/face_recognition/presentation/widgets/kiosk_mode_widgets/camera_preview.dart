import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CircularCameraPreview extends StatelessWidget {
  final CameraController cameraController;
  final double width;
  final double height;

  const CircularCameraPreview({
    Key? key,
    required this.cameraController,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        // border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CameraPreview(cameraController),
      ),
    );
  }
}