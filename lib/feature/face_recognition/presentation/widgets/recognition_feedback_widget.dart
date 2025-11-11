import 'package:flutter/material.dart';

/// ✅ Shows success/error feedback with animations
class RecognitionFeedbackWidget extends StatefulWidget {
  final String name;
  final bool isSuccess;
  final String message;
  final VoidCallback? onDismiss;

  const RecognitionFeedbackWidget({
    Key? key,
    required this.name,
    required this.isSuccess,
    required this.message,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<RecognitionFeedbackWidget> createState() => _RecognitionFeedbackWidgetState();
}

class _RecognitionFeedbackWidgetState extends State<RecognitionFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isSuccess ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.isSuccess ? Colors.green : Colors.red)
                    .withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                widget.isSuccess ? Icons.check_circle : Icons.error,
                size: 80,
                color: Colors.white,
              ),

              const SizedBox(height: 16),

              // Name/Title
              Text(
                widget.isSuccess ? 'Welcome, ${widget.name}!' : widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),

              // Loading indicator for API call
              if (widget.isSuccess) ...[
                const SizedBox(height: 16),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}