import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ✅ ENHANCED: Modern liveness progress with animated icons and better visuals
class LivenessProgressOverlay extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String statusMessage;
  final bool isComplete;

  const LivenessProgressOverlay({
    Key? key,
    required this.progress,
    required this.statusMessage,
    this.isComplete = false,
  }) : super(key: key);

  @override
  State<LivenessProgressOverlay> createState() => _LivenessProgressOverlayState();
}

class _LivenessProgressOverlayState extends State<LivenessProgressOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ ENHANCED: Progress ring with gradient
          _buildProgressRing(),
          
          const SizedBox(height: 20),

          // ✅ ENHANCED: Status card with glassmorphism
          _buildStatusCard(),

          const SizedBox(height: 20),

          // ✅ ENHANCED: Animated checklist with icons
          _buildAnimatedChecklist(),
        ],
      ),
    );
  }

  /// ✅ NEW: Gradient progress ring
  Widget _buildProgressRing() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (widget.isComplete ? Colors.green : Colors.purple)
                    .withOpacity(0.3 + (_pulseController.value * 0.2)),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _GradientCircularProgressPainter(
                    progress: widget.progress,
                    isComplete: widget.isComplete,
                  ),
                ),
              ),
              
              // Center icon with animation
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300),
                tween: Tween(begin: 0.8, end: 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: widget.isComplete 
                          ? Color(0xFF10B981) 
                          : Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isComplete ? Icons.check_rounded : Icons.face_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              // Percentage text
              Positioned(
                bottom: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(widget.progress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ ENHANCED: Glassmorphism status card
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Status icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isComplete 
                ? Color(0xFF10B981).withOpacity(0.2)
                : Color(0xFF8B5CF6).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isComplete ? Icons.verified : Icons.pending,
              color: widget.isComplete ? Color(0xFF10B981) : Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status text
          Flexible(
            child: Text(
              widget.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ ENHANCED: Animated checklist with icons
  Widget _buildAnimatedChecklist() {
    // Parse progress to determine completion
    bool holdSteady = widget.progress >= 0.33;
    bool blink = widget.progress >= 0.66 || widget.statusMessage.contains('✅');
    bool movement = widget.progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildAnimatedChecklistItem(
            icon: Icons.face_retouching_natural,
            text: 'Hold face steady',
            completed: holdSteady,
            delay: 0,
          ),
          const SizedBox(height: 14),
          _buildAnimatedChecklistItem(
            icon: Icons.remove_red_eye_outlined,
            text: 'Keep eyes open',
            completed: blink,
            delay: 100,
          ),
          const SizedBox(height: 14),
          _buildAnimatedChecklistItem(
            icon: Icons.rotate_90_degrees_ccw,
            text: 'Slight head movement',
            completed: movement,
            delay: 200,
          ),
        ],
      ),
    );
  }

  /// ✅ NEW: Individual animated checklist item
  Widget _buildAnimatedChecklistItem({
    required IconData icon,
    required String text,
    required bool completed,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: completed ? 1.0 : 0.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: completed 
                ? Color(0xFF10B981).withOpacity(0.15)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: completed 
                  ? Color(0xFF10B981).withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon with animation
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: completed 
                      ? Color(0xFF10B981) 
                      : Colors.grey.shade700,
                    shape: BoxShape.circle,
                    boxShadow: completed ? [
                      BoxShadow(
                        color: Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : [],
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 14),
                
                // Text
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: completed ? Colors.white : Colors.grey.shade400,
                      fontSize: 15,
                      fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                
                // Checkmark indicator
                if (completed)
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ✅ NEW: Custom painter for gradient circular progress
class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isComplete;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius - 5, backgroundPaint);

    // Gradient progress arc
    final rect = Rect.fromCircle(center: center, radius: radius - 5);
    
    final gradient = SweepGradient(
      colors: isComplete
        ? [Color(0xFF10B981), Color(0xFF059669), Color(0xFF10B981)]
        : [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF8B5CF6)],
      stops: [0.0, 0.5, 1.0],
      startAngle: -math.pi / 2,
      endAngle: (progress * 2 * math.pi) - math.pi / 2,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      progressPaint,
    );

    // Glow effect at the end of progress
    if (progress > 0 && progress < 1.0) {
      final glowPaint = Paint()
        ..color = (isComplete ? Color(0xFF10B981) : Color(0xFF8B5CF6))
            .withOpacity(0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

      final endAngle = (progress * 2 * math.pi) - math.pi / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      canvas.drawCircle(endPoint, 8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isComplete != isComplete;
  }
}