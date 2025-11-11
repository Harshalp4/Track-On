import 'package:flutter/material.dart';
import 'package:track_on/feature/face_recognition/domain/services/advanced_liveness_detector_service.dart';
import 'dart:math' as math;


/// 🎨 ADVANCED LIVENESS CHALLENGE OVERLAY
/// Displays active challenges with animations and visual feedback

class AdvancedLivenessChallengeOverlay extends StatefulWidget {
  final AdvancedLivenessDetectorService livenessService;
  final VoidCallback? onComplete;
  final VoidCallback? onFailed;

  const AdvancedLivenessChallengeOverlay({
    Key? key,
    required this.livenessService,
    this.onComplete,
    this.onFailed,
  }) : super(key: key);

  @override
  State<AdvancedLivenessChallengeOverlay> createState() => 
      _AdvancedLivenessChallengeOverlayState();
}

class _AdvancedLivenessChallengeOverlayState 
    extends State<AdvancedLivenessChallengeOverlay>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  
  LivenessState _previousState = LivenessState.initializing;
  LivenessChallenge? _previousChallenge;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.livenessService;
    
    // Detect state changes
    if (_previousState != service.state) {
      _onStateChanged(service.state);
      _previousState = service.state;
    }
    
    // Detect challenge changes
    if (_previousChallenge != service.currentChallenge && 
        service.currentChallenge != null) {
      _slideController.forward(from: 0);
      _previousChallenge = service.currentChallenge;
    }
    
    return Stack(
      children: [
        // Top progress bar
        _buildProgressBar(),
        
        // Main challenge display
        Center(
          child: _buildChallengeCard(),
        ),
        
        // Bottom status
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: _buildStatusIndicator(),
        ),
      ],
    );
  }

  /// 🎯 State change handler
  void _onStateChanged(LivenessState newState) {
    if (newState == LivenessState.passed) {
      widget.onComplete?.call();
    } else if (newState == LivenessState.failed) {
      widget.onFailed?.call();
    }
  }

  /// 📊 Progress bar at top
  Widget _buildProgressBar() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widget.livenessService.progress,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF6366F1),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎴 Main challenge card
  Widget _buildChallengeCard() {
    final service = widget.livenessService;
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, -0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.elasticOut,
      )),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          double scale = 1.0 + (_pulseController.value * 0.05);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getCardGradientColors(service.state),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Challenge icon/animation
                  _buildChallengeIcon(),
                  
                  SizedBox(height: 20),
                  
                  // Challenge text
                  Text(
                    service.getStatusMessage(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Progress indicator
                  _buildChallengeProgress(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🎭 Challenge icon with animation
  Widget _buildChallengeIcon() {
    final service = widget.livenessService;
    
    if (service.state == LivenessState.passed) {
      return _buildSuccessIcon();
    } else if (service.state == LivenessState.failed) {
      return _buildFailureIcon();
    } else if (service.state == LivenessState.analyzing) {
      return _buildAnalyzingIcon();
    }
    
    // Challenge-specific icon
    if (service.currentChallenge != null) {
      return _buildDirectionalIcon(service.currentChallenge!);
    }
    
    return _buildDefaultIcon();
  }

  /// ✅ Success icon
  Widget _buildSuccessIcon() {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF10B981).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  /// ❌ Failure icon
  Widget _buildFailureIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Color(0xFFEF4444),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.close_rounded,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  /// 🔄 Analyzing icon
  Widget _buildAnalyzingIcon() {
    return RotationTransition(
      turns: _rotateController,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Color(0xFF8B5CF6).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.sync,
          color: Color(0xFF8B5CF6),
          size: 60,
        ),
      ),
    );
  }

  /// 🧭 Directional challenge icon
  Widget _buildDirectionalIcon(LivenessChallenge challenge) {
    IconData icon;
    double rotation = 0.0;
    
    switch (challenge) {
      case LivenessChallenge.turnLeft:
        icon = Icons.arrow_back;
        break;
      case LivenessChallenge.turnRight:
        icon = Icons.arrow_forward;
        break;
      case LivenessChallenge.lookUp:
        icon = Icons.arrow_upward;
        break;
      case LivenessChallenge.lookDown:
        icon = Icons.arrow_downward;
        break;
      case LivenessChallenge.smile:
        icon = Icons.sentiment_satisfied_alt;
        break;
      case LivenessChallenge.blink:
        icon = Icons.remove_red_eye;
        break;
      default:
        icon = Icons.face;
    }
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotation + (_pulseController.value * 0.1),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  /// 👤 Default icon
  Widget _buildDefaultIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.face_retouching_natural,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  /// 📊 Challenge progress text
  Widget _buildChallengeProgress() {
    final service = widget.livenessService;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Challenge ${service.challengesCompleted}/${service.totalChallenges}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 📱 Bottom status indicator
  Widget _buildStatusIndicator() {
    final service = widget.livenessService;
    
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusDot(service.state),
            SizedBox(width: 12),
            Text(
              _getStateDisplayText(service.state),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⚫ Status indicator dot
  Widget _buildStatusDot(LivenessState state) {
    Color color;
    
    switch (state) {
      case LivenessState.passed:
        color = Color(0xFF10B981);
        break;
      case LivenessState.failed:
        color = Color(0xFFEF4444);
        break;
      case LivenessState.analyzing:
        color = Color(0xFFF59E0B);
        break;
      default:
        color = Color(0xFF8B5CF6);
    }
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5 + (_pulseController.value * 0.3)),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🎨 Get card gradient colors based on state
  List<Color> _getCardGradientColors(LivenessState state) {
    switch (state) {
      case LivenessState.passed:
        return [
          Color(0xFF10B981),
          Color(0xFF059669),
        ];
      case LivenessState.failed:
        return [
          Color(0xFFEF4444),
          Color(0xFFDC2626),
        ];
      case LivenessState.analyzing:
        return [
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ];
      default:
        return [
          Color(0xFF8B5CF6),
          Color(0xFF6366F1),
        ];
    }
  }

  /// 📝 Get display text for state
  String _getStateDisplayText(LivenessState state) {
    switch (state) {
      case LivenessState.initializing:
        return "Initializing...";
      case LivenessState.detectingFace:
        return "Detecting face...";
      case LivenessState.generatingChallenge:
        return "Preparing challenge...";
      case LivenessState.waitingForResponse:
        return "Follow instructions";
      case LivenessState.verifyingResponse:
        return "Verifying...";
      case LivenessState.analyzing:
        return "Analyzing results...";
      case LivenessState.passed:
        return "Verification complete!";
      case LivenessState.failed:
        return "Verification failed";
      default:
        return "Processing...";
    }
  }
}