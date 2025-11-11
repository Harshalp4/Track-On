import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ✅ Gradient border scanner - No center "UNKNOWN" label
class AnimatedBorderScanner extends StatefulWidget {
  final bool faceDetected;
  final bool faceRecognized;
  final bool livenessComplete;
  final String? recognizedName;
  final double? confidence;
  final bool isLowLight; 

  const AnimatedBorderScanner({
    Key? key,
    required this.faceDetected,
    required this.faceRecognized,
    required this.livenessComplete,
    this.recognizedName,
    this.confidence,
     this.isLowLight = false, 
  }) : super(key: key);

  @override
  State<AnimatedBorderScanner> createState() => _AnimatedBorderScannerState();
}

class _AnimatedBorderScannerState extends State<AnimatedBorderScanner>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    _scanController = AnimationController(
      duration: Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// ✅ Get border gradient colors based on status
  List<Color> _getBorderGradient() {
    if (widget.livenessComplete && widget.faceRecognized) {
      // ✅ GREEN - Success
      return [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)];
    } else if (widget.faceRecognized) {
      // ⚠️ YELLOW/ORANGE - Warning (checking liveness)
      return [Color(0xFFFBBF24), Color(0xFFFCD34D), Color(0xFFFDE68A)];
    } else if (widget.faceDetected) {
      // ❌ RED - Unknown/Unregistered
      return [Color(0xFFEF4444), Color(0xFFF87171), Color(0xFFFCA5A5)];
    } else {
      // ⏳ GRAY - Waiting
      return [Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB)];
    }
  }

  /// ✅ Get status text
  String _getStatusText() {
    if (widget.livenessComplete && widget.faceRecognized) {
      return 'Verified: ${widget.recognizedName}';
    } else if (widget.faceRecognized) {
      return 'Verifying Liveness...';
    } else if (widget.faceDetected) {
      return 'Unknown Person';
    } else {
      return 'Position Your Face';
    }
  }

  /// ✅ Get status icon
  IconData _getStatusIcon() {
    if (widget.livenessComplete && widget.faceRecognized) {
      return Icons.check_circle;
    } else if (widget.faceRecognized) {
      return Icons.hourglass_bottom;
    } else if (widget.faceDetected) {
      return Icons.warning_rounded;
    } else {
      return Icons.face;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getBorderGradient();
    
    return Stack(
      children: [
        // ✅ MAIN: Animated gradient border
        AnimatedBuilder(
          animation: Listenable.merge([_scanController, _pulseController]),
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _GradientRunningBorderPainter(
                progress: _scanController.value,
                pulseValue: _pulseController.value,
                gradientColors: gradient,
                isActive: widget.faceDetected,
                isUnknown: widget.faceDetected && !widget.faceRecognized,
              ),
            );
          },
        ),

        // ✅ Corner indicators
        _buildCornerIndicators(gradient),

        // ✅ Status badge at top center
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Center(
            //child: _buildStatusBadge(gradient),
          ),
        ),

        // ✅ Status text at bottom
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: _buildBottomStatusCard(gradient),
          ),
        ),

       

        // ✅ Confidence indicator (when recognized)
        if (widget.confidence != null && widget.faceRecognized)
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(
              child: _buildConfidenceIndicator(gradient),
            ),
          ),

if (widget.isLowLight && !widget.faceRecognized)
  Positioned(
    top: 200,
    left: 0,
    right: 0,
    child: Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.8 + (_pulseController.value * 0.2),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFBBF24).withOpacity(0.95),
                    Color(0xFFF59E0B).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFBBF24).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Low Light Detected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tap 💡 to turn on light',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  ),


      ],
    );
  }

  // Widget _buildStatusBadge(List<Color> gradient) {
  //   return AnimatedContainer(
  //     duration: Duration(milliseconds: 300),
  //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(colors: gradient),
  //       borderRadius: BorderRadius.circular(30),
  //       border: Border.all(
  //         color: Colors.white.withOpacity(0.4),
  //         width: 2,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: gradient.first.withOpacity(0.5),
  //           blurRadius: 20,
  //           spreadRadius: 5,
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       // children: [
  //       //   Icon(_getStatusIcon(), color: Colors.white, size: 20),
  //       //   SizedBox(width: 8),
  //       //   Text(
  //       //     widget.livenessComplete && widget.faceRecognized
  //       //         ? '✓ SUCCESS'
  //       //         : widget.faceRecognized
  //       //         ? '⏳ VERIFYING'
  //       //         : widget.faceDetected
  //       //         ? '⚠ UNKNOWN'
  //       //         : '○ SCANNING',
  //       //     style: TextStyle(
  //       //       color: Colors.white,
  //       //       fontSize: 14,
  //       //       fontWeight: FontWeight.bold,
  //       //       letterSpacing: 1,
  //       //     ),
  //       //   ),
  //       // ],
  //     ),
  //   );
  // }

  Widget _buildBottomStatusCard(List<Color> gradient) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.first.withOpacity(0.95),
            gradient.last.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 500),
            tween: Tween(begin: 0.8, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Icon(_getStatusIcon(), color: Colors.white, size: 24),
              );
            },
          ),
          SizedBox(width: 12),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerIndicators(List<Color> gradient) {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 15,
          left: 15,
          child: _buildCornerMarker(gradient, 0),
        ),
        // Top-right
        Positioned(
          top: 15,
          right: 15,
          child: _buildCornerMarker(gradient, math.pi / 2),
        ),
        // Bottom-left
        Positioned(
          bottom: 15,
          left: 15,
          child: _buildCornerMarker(gradient, -math.pi / 2),
        ),
        // Bottom-right
        Positioned(
          bottom: 15,
          right: 15,
          child: _buildCornerMarker(gradient, math.pi),
        ),
      ],
    );
  }

  Widget _buildCornerMarker(List<Color> gradient, double rotation) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotation,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 5 + (_pulseController.value * 2),
                  color: gradient.first.withOpacity(0.9),
                ),
                left: BorderSide(
                  width: 5 + (_pulseController.value * 2),
                  color: gradient.first.withOpacity(0.9),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfidenceIndicator(List<Color> gradient) {
    final confidence = (widget.confidence! * 100).toInt();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient.first.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Confidence',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$confidence%',
                style: TextStyle(
                  color: gradient.first,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 120,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.confidence,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ✅ Gradient running border painter
class _GradientRunningBorderPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final List<Color> gradientColors;
  final bool isActive;
  final bool isUnknown;

  _GradientRunningBorderPainter({
    required this.progress,
    required this.pulseValue,
    required this.gradientColors,
    required this.isActive,
    required this.isUnknown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final borderPath = Path()..addRect(rect.deflate(15));

    final perimeter = (size.width + size.height) * 2 - 120;
    
    // ✅ THICKER borders: 8-12px
    final baseWidth = 8.0 + (pulseValue * 4);

    // ✅ Multiple running segments
    final segmentCount = isUnknown ? 2 : 3;
    
    for (int i = 0; i < segmentCount; i++) {
      final segmentStart = ((progress + (i / segmentCount)) % 1.0) * perimeter;
      final segmentLength = perimeter * (isUnknown ? 0.25 : 0.18);

      // ✅ Gradient with 3 colors
      final gradient = LinearGradient(
        colors: [
          gradientColors[0].withOpacity(0.0),
          gradientColors[0],
          gradientColors[1],
          gradientColors[2],
          gradientColors[1],
          gradientColors[0],
          gradientColors[0].withOpacity(0.0),
        ],
        stops: [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
      );

      final segmentPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseWidth
        ..strokeCap = StrokeCap.round;

      final pathMetrics = borderPath.computeMetrics().first;
      final extractPath = pathMetrics.extractPath(
        segmentStart,
        (segmentStart + segmentLength) % perimeter,
      );

      canvas.drawPath(extractPath, segmentPaint);
    }

    // ✅ Static gradient border
    final staticGradient = LinearGradient(
      colors: gradientColors.map((c) => c.withOpacity(0.3)).toList(),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final staticPaint = Paint()
      ..shader = staticGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(borderPath, staticPaint);

    // ✅ Glow effect
    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors.map((c) => c.withOpacity(0.4)).toList(),
      ).createShader(rect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 + (pulseValue * 5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;

    canvas.drawPath(borderPath, glowPaint);
  }

  @override
  bool shouldRepaint(_GradientRunningBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.isActive != isActive ||
           oldDelegate.isUnknown != isUnknown;
  }
}