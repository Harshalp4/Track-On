import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraView extends StatelessWidget {
  final CameraController controller;
  final bool isInitialized;
  final Size size;

  const CameraView({
    required this.controller,
    required this.isInitialized,
    required this.size,
    Key? key,
  }) : super(key: key);

 @override
Widget build(BuildContext context) {
  if (!isInitialized) {
    return const Center(child: CircularProgressIndicator());
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final isTablet = constraints.maxWidth > 600;

      final double top = isTablet ? size.height * 0.05 : size.height * 0.02;
      final double left = isTablet ? size.width * 0.1 : size.width * 0.05;
      final double width = isTablet ? size.width * 0.8 : size.width * 0.9;
      final double height = isTablet ? size.height * 0.7 : size.height * 0.6;

      return Positioned(
        top: top,
        left: left,
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16), // slightly more rounded on tablet
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      );
    },
  );
}
}