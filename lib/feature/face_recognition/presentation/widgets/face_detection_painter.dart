// import 'package:flutter/material.dart';
// import 'package:track_on/core/ML/Recognition.dart';

// class FaceBoxesPainter extends CustomPainter {
//   final List<Recognition> recognitions;
//   final Size imageSize;
//   final Size screenSize;

//   FaceBoxesPainter({
//     required this.recognitions,
//     required this.imageSize,
//     required this.screenSize,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (recognitions.isEmpty) return;

//     for (var recognition in recognitions) {
//       final rect = recognition.location;
      
//       // Determine if this is a known or unknown face
//       bool isKnown = recognition.name != "Unknown" && 
//                      recognition.name != "Unregister" &&
//                      recognition.name.isNotEmpty;
      
//       // Choose color based on recognition status
//       Color boxColor = isKnown ? Colors.green : Colors.red;
//       String displayName = isKnown ? recognition.name : "Unknown";
      
//       // Scale the rectangle from image coordinates to screen coordinates
//       final scaleX = screenSize.width / imageSize.width;
//       final scaleY = screenSize.height / imageSize.height;
      
//       final scaledRect = Rect.fromLTRB(
//         rect.left * scaleX,
//         rect.top * scaleY,
//         rect.right * scaleX,
//         rect.bottom * scaleY,
//       );

//       // Draw the bounding box
//       final paint = Paint()
//         ..color = boxColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 3.0;

//       canvas.drawRect(scaledRect, paint);

//       // Draw semi-transparent background for name
//       final textPainter = TextPainter(
//         text: TextSpan(
//           text: displayName,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       textPainter.layout();

//       // Position name above the box
//       final nameBackgroundRect = Rect.fromLTWH(
//         scaledRect.left,
//         scaledRect.top - 30,
//         textPainter.width + 16,
//         28,
//       );

//       // Draw name background
//       final backgroundPaint = Paint()
//         ..color = boxColor.withOpacity(0.9)
//         ..style = PaintingStyle.fill;

//       canvas.drawRRect(
//         RRect.fromRectAndRadius(nameBackgroundRect, Radius.circular(6)),
//         backgroundPaint,
//       );

//       // Draw name text
//       textPainter.paint(
//         canvas,
//         Offset(scaledRect.left + 8, scaledRect.top - 26),
//       );

//       // Draw confidence percentage for known faces
//       if (isKnown) {
//         final confidence = ((1 - recognition.distance) * 100).toStringAsFixed(0);
//         final confidenceText = '$confidence%';
        
//         final confidencePainter = TextPainter(
//           text: TextSpan(
//             text: confidenceText,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           textDirection: TextDirection.ltr,
//         );
//         confidencePainter.layout();

//         // Draw confidence badge at bottom-right of box
//         final confidenceRect = Rect.fromLTWH(
//           scaledRect.right - confidencePainter.width - 12,
//           scaledRect.bottom - 24,
//           confidencePainter.width + 8,
//           20,
//         );

//         canvas.drawRRect(
//           RRect.fromRectAndRadius(confidenceRect, Radius.circular(4)),
//           backgroundPaint,
//         );

//         confidencePainter.paint(
//           canvas,
//           Offset(scaledRect.right - confidencePainter.width - 8, scaledRect.bottom - 22),
//         );
//       }

//       // Draw corner brackets for extra style
//       _drawCornerBrackets(canvas, scaledRect, boxColor);
//     }
//   }

//   void _drawCornerBrackets(Canvas canvas, Rect rect, Color color) {
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.0
//       ..strokeCap = StrokeCap.round;

//     final cornerLength = 20.0;

//     // Top-left
//     canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerLength, rect.top), paint);
//     canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.top + cornerLength), paint);

//     // Top-right
//     canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right - cornerLength, rect.top), paint);
//     canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLength), paint);

//     // Bottom-left
//     canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerLength, rect.bottom), paint);
//     canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left, rect.bottom - cornerLength), paint);

//     // Bottom-right
//     canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right - cornerLength, rect.bottom), paint);
//     canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLength), paint);
//   }

//   @override
//   bool shouldRepaint(FaceBoxesPainter oldDelegate) {
//     return oldDelegate.recognitions != recognitions;
//   }
// }