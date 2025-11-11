import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ✅ ENHANCED: Professional recognition overlay with particle effects
class AnimatedRecognitionOverlay extends StatefulWidget {
  final String? recognizedName;
  final double confidence;
  final bool isProcessing;
  final bool isSuccess;

  const AnimatedRecognitionOverlay({
    Key? key,
    this.recognizedName,
    required this.confidence,
    required this.isProcessing,
    required this.isSuccess,
  }) : super(key: key);

  @override
  State<AnimatedRecognitionOverlay> createState() => _AnimatedRecognitionOverlayState();
}

class _AnimatedRecognitionOverlayState extends State<AnimatedRecognitionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    
    _scanController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _successController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AnimatedRecognitionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _successController.forward(from: 0);
      _particleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // ✅ ENHANCED: Gradient scanning circle with glow
        if (widget.isProcessing)
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_scanController, _pulseController]),
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size.width * 0.7, size.width * 0.7),
                    painter: _EnhancedScanningPainter(
                      progress: _scanController.value,
                      pulseValue: _pulseController.value,
                      color: Color(0xFF8B5CF6),
                    ),
                  );
                },
              ),
            ),
          ),
        
        // ✅ NEW: Particle effects on success
        if (widget.isSuccess)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticleEffectPainter(
                    progress: _particleController.value,
                    screenSize: size,
                  ),
                );
              },
            ),
          ),
        
        // ✅ ENHANCED: Success checkmark with glow and scale
        if (widget.isSuccess)
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _successController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: Curves.elasticOut.transform(_successController.value),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981).withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        
        // ✅ ENHANCED: Name and confidence display with glassmorphism
        if (widget.recognizedName != null)
          Positioned(
            bottom: size.height * 0.15,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 500),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 50),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 40),
                      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.black.withOpacity(0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.isSuccess 
                            ? Color(0xFF10B981) 
                            : Color(0xFF8B5CF6),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isSuccess 
                              ? Color(0xFF10B981) 
                              : Color(0xFF8B5CF6)
                            ).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ Status icon
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (widget.isSuccess 
                                ? Color(0xFF10B981) 
                                : Color(0xFF8B5CF6)
                              ).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isSuccess ? Icons.verified : Icons.face,
                              color: widget.isSuccess 
                                ? Color(0xFF10B981) 
                                : Color(0xFF8B5CF6),
                              size: 24,
                            ),
                          ),
                          
                          SizedBox(height: 12),
                          
                          // Name
                          Text(
                            widget.recognizedName!,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 10),
                          
                          // ✅ ENHANCED: Confidence bar with gradient
                          _buildConfidenceBar(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// ✅ NEW: Animated confidence bar
  Widget _buildConfidenceBar() {
    Color confidenceColor;
    String confidenceLevel;
    
    if (widget.confidence >= 0.90) {
      confidenceColor = Color(0xFF10B981);
      confidenceLevel = 'Excellent';
    } else if (widget.confidence >= 0.75) {
      confidenceColor = Color(0xFF3B82F6);
      confidenceLevel = 'Good';
    } else if (widget.confidence >= 0.60) {
      confidenceColor = Color(0xFFFBBF24);
      confidenceLevel = 'Fair';
    } else {
      confidenceColor = Color(0xFFEF4444);
      confidenceLevel = 'Low';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              confidenceLevel,
              style: TextStyle(
                color: confidenceColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(widget.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            width: double.infinity,
            color: Colors.white.withOpacity(0.2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.confidence,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      confidenceColor,
                      confidenceColor.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: confidenceColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ✅ ENHANCED: Gradient scanning circle painter with glow
class _EnhancedScanningPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final Color color;

  _EnhancedScanningPainter({
    required this.progress,
    required this.pulseValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ✅ Outer glow with pulse
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2 + (pulseValue * 0.1))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 + (pulseValue * 10));

    canvas.drawCircle(center, radius + 10, glowPaint);

    // ✅ Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.5),
        color,
        color.withOpacity(0.5),
        color.withOpacity(0.0),
      ],
      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
      startAngle: progress * 2 * math.pi,
      endAngle: (progress + 0.5) * 2 * math.pi,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 5.0 + (pulseValue * 2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      progress * 2 * math.pi,
      math.pi,
      false,
      paint,
    );

    // ✅ Leading dot
    final dotAngle = (progress * 2 * math.pi) + (math.pi / 2);
    final dotPosition = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );

    final dotPaint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(dotPosition, 6 + (pulseValue * 2), dotPaint);
  }

  @override
  bool shouldRepaint(_EnhancedScanningPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulseValue != pulseValue;
  }
}

/// ✅ NEW: Particle effect painter for success animation
class _ParticleEffectPainter extends CustomPainter {
  final double progress;
  final Size screenSize;
  final List<_Particle> particles;

  _ParticleEffectPainter({
    required this.progress,
    required this.screenSize,
  }) : particles = List.generate(20, (index) {
          final angle = (index / 20) * 2 * math.pi;
          final speed = 100 + (math.Random().nextDouble() * 100);
          return _Particle(
            angle: angle,
            speed: speed,
            color: index % 2 == 0 ? Color(0xFF10B981) : Color(0xFF059669),
            size: 4 + (math.Random().nextDouble() * 4),
          );
        });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    for (var particle in particles) {
      final distance = particle.speed * progress;
      final x = center.dx + math.cos(particle.angle) * distance;
      final y = center.dy + math.sin(particle.angle) * distance;

      final opacity = 1.0 - progress;
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticleEffectPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Particle data class
class _Particle {
  final double angle;
  final double speed;
  final Color color;
  final double size;

  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}