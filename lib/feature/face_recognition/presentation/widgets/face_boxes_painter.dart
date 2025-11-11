import 'package:flutter/material.dart';
import 'package:track_on/core/ML/Recognition.dart';
import 'dart:math' as math;

/// ✅ YOUR ORIGINAL coordinate logic + NEW UI enhancements
class FaceBoxesPainter extends CustomPainter {
  final List<Recognition> recognitions;
  final Size imageSize;
  final Size screenSize;

  FaceBoxesPainter({
    required this.recognitions,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (recognitions.isEmpty) return;

    for (var recognition in recognitions) {
      final rect = recognition.location;
      
      // Determine if this is a known or unknown face
      bool isKnown = recognition.name != "Unknown" && 
                     recognition.name != "Unregister" &&
                     recognition.name.isNotEmpty;
      
      // Choose color based on recognition status
      Color boxColor = isKnown ? Colors.green : Colors.red;
      String displayName = isKnown ? recognition.name : "Unknown";
      
      // ✅ ORIGINAL SCALING LOGIC (your working version)
      final scaleX = screenSize.width / imageSize.width;
      final scaleY = screenSize.height / imageSize.height;
      
      final scaledRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );

      // ✅ NEW: Enhanced visual effects
      // Glow effect
      final glowPaint = Paint()
        ..color = boxColor.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, Radius.circular(8)),
        glowPaint,
      );

      // ✅ NEW: Gradient border instead of solid
      final borderPaint = Paint()
        ..shader = LinearGradient(
          colors: isKnown 
            ? [Color(0xFF10B981), Color(0xFF059669)]
            : [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(scaledRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, Radius.circular(8)),
        borderPaint,
      );

      // ✅ ENHANCED: Better name badge
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Position name above the box
      final nameBackgroundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          scaledRect.left,
          scaledRect.top - 35,
          textPainter.width + 20,
          30,
        ),
        Radius.circular(15),
      );

      // ✅ NEW: Glassmorphism background
      final backgroundPaint = Paint()
        ..color = boxColor.withOpacity(0.95)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(nameBackgroundRect, backgroundPaint);

      // ✅ NEW: Border for badge
      final borderBadgePaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRRect(nameBackgroundRect, borderBadgePaint);

      // Draw name text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 10, scaledRect.top - 31),
      );

      // ✅ ENHANCED: Draw confidence percentage for known faces
      if (isKnown) {
        final confidence = ((1 - recognition.distance) * 100).toStringAsFixed(0);
        final confidenceText = '$confidence%';
        
        // Color code confidence
        Color confidenceColor;
        if (double.parse(confidence) >= 90) {
          confidenceColor = Color(0xFF10B981); // Green
        } else if (double.parse(confidence) >= 75) {
          confidenceColor = Color(0xFF3B82F6); // Blue
        } else if (double.parse(confidence) >= 60) {
          confidenceColor = Color(0xFFFBBF24); // Yellow
        } else {
          confidenceColor = Color(0xFFEF4444); // Red
        }
        
        final confidencePainter = TextPainter(
          text: TextSpan(
            text: confidenceText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        confidencePainter.layout();

        // Draw confidence badge at bottom-right of box
        final confidenceRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            scaledRect.right - confidencePainter.width - 16,
            scaledRect.bottom - 26,
            confidencePainter.width + 12,
            22,
          ),
          Radius.circular(11),
        );

        canvas.drawRRect(
          confidenceRect,
          Paint()..color = confidenceColor.withOpacity(0.95),
        );

        canvas.drawRRect(
          confidenceRect,
          Paint()
            ..color = Colors.white.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        confidencePainter.paint(
          canvas,
          Offset(scaledRect.right - confidencePainter.width - 10, scaledRect.bottom - 24),
        );
      }

      // ✅ ENHANCED: Draw corner brackets with better styling
      _drawCornerBrackets(canvas, scaledRect, boxColor);
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final cornerLength = math.min(rect.width, rect.height) * 0.15;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerLength, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.top + cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right - cornerLength, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerLength, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left, rect.bottom - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right - cornerLength, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLength), paint);
  }

  @override
  bool shouldRepaint(FaceBoxesPainter oldDelegate) {
    return oldDelegate.recognitions != recognitions;
  }
}