import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClockInSuccessScreen extends StatefulWidget {
  final String employeeName;
  final String? profileImage;
  final VoidCallback onDismiss;

  const ClockInSuccessScreen({
    Key? key,
    required this.employeeName,
    this.profileImage,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<ClockInSuccessScreen> createState() => _ClockInSuccessScreenState();
}

class _ClockInSuccessScreenState extends State<ClockInSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    // ✅ Auto dismiss after 3 seconds
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        print("⏱️ Auto-closing success screen after 1 seconds");
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeString = DateFormat('hh:mm a').format(now);
    final dateString = DateFormat('EEEE, MMMM d, yyyy').format(now);
    
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _scaleController,
                curve: Curves.elasticOut,
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 40),
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 30,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Success message
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    
                    SizedBox(height: 10),
                    
                    // Employee name
                    Text(
                      widget.employeeName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B46C1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Clock in time
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF6B46C1),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Clocked In',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            dateString,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF10B981).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Attendance recorded successfully',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // ✅ Updated: Auto-closing text
                    Text(
                      'Auto-closing in 3 seconds...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // ✅ Optional: Remove or keep close button
          // Uncomment to keep the close button:
          /*
          Positioned(
            top: 60,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: widget.onDismiss,
            ),
          ),
          */
        ],
      ),
    );
  }
}