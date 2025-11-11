import 'package:flutter/material.dart';

/// ✅ Displays real-time guidance for face positioning
class FaceGuideOverlay extends StatelessWidget {
  final bool faceDetected;
  final bool faceQualityGood;
  final String? qualityMessage;
  final bool isProcessing;

  const FaceGuideOverlay({
    Key? key,
    required this.faceDetected,
    required this.faceQualityGood,
    this.qualityMessage,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    IconData statusIcon;
    String statusText;
    Color statusBgColor;

    if (isProcessing) {
      borderColor = Colors.blue;
      statusIcon = Icons.hourglass_empty;
      statusText = "Processing...";
      statusBgColor = Colors.blue;
    } else if (!faceDetected) {
      borderColor = Colors.red.withOpacity(0.6);
      statusIcon = Icons.face;
      statusText = "Position your face";
      statusBgColor = Colors.red;
    } else if (!faceQualityGood) {
      borderColor = Colors.orange;
      statusIcon = Icons.warning_amber;
      statusText = qualityMessage ?? "Adjust position";
      statusBgColor = Colors.orange;
    } else {
      borderColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = "Perfect! Hold still...";
      statusBgColor = Colors.green;
    }

    return Stack(
      children: [
        // Face guide frame (oval)
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(200),
              border: Border.all(
                color: borderColor,
                width: 4,
              ),
            ),
          ),
        ),

        // Status indicator at top
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: statusBgColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Corner guides for alignment
        if (faceDetected && faceQualityGood)
          Positioned.fill(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.9,
                child: Stack(
                  children: [
                    // Top-left corner
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildCornerGuide(),
                    ),
                    // Top-right corner
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Transform.rotate(
                        angle: 1.5708,
                        child: _buildCornerGuide(),
                      ),
                    ),
                    // Bottom-left corner
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Transform.rotate(
                        angle: -1.5708,
                        child: _buildCornerGuide(),
                      ),
                    ),
                    // Bottom-right corner
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Transform.rotate(
                        angle: 3.14159,
                        child: _buildCornerGuide(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCornerGuide() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.green, width: 4),
          left: BorderSide(color: Colors.green, width: 4),
        ),
      ),
    );
  }
}