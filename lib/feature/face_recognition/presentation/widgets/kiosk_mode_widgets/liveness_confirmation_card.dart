import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hive/hive.dart';
import '../../../domain/services/network_monitor_api_call.dart';
import '../../../domain/services/tts_service.dart';
import 'camera_preview.dart';
import 'custom_elevated_button.dart';
import 'last_out_time_card.dart';

class LivenessConfirmationCard extends StatefulWidget {
  final String recognizedName;
  final CameraController cameraController;
  final VoidCallback onRetry;
  final VoidCallback onClockIn;
  final String lastClockOutTime;
  final Uint8List faceImage;

  const LivenessConfirmationCard({
    Key? key,
    required this.recognizedName,
    required this.cameraController,
    required this.onRetry,
    required this.onClockIn,
    required this.lastClockOutTime,
    required this.faceImage,
  }) : super(key: key);

  @override
  State<LivenessConfirmationCard> createState() => _LivenessConfirmationCardState();
}

class _LivenessConfirmationCardState extends State<LivenessConfirmationCard> {
  // ✅ NEW: TTS Service
  final TTSService _ttsService = TTSService();
  bool _hasSpoken = false;
  bool _ttsEnabled = true;


  @override
  void initState() {
    super.initState();
    _loadTTSSettings();
    _speakGreeting();
  }

Future<void> _loadTTSSettings() async {
    final settingsBox = await Hive.openBox('settingsBox');
    setState(() {
      _ttsEnabled = settingsBox.get('enableTTS', defaultValue: true);
    });
  }
  
  // ✅ FIXED: More aggressive TTS call with debugging
Future<void> _speakGreeting() async {
  print("\n🔊 _speakGreeting called");
  print("🔊 _hasSpoken: $_hasSpoken");
  
  if (_hasSpoken) {
    print("⚠️ Already spoken, skipping");
    return;
  }
  
  _hasSpoken = true;
  
  print("🔊 Waiting 300ms before speaking...");
  await Future.delayed(Duration(milliseconds: 300));
  
  print("🔊 Now calling TTS service...");
  print("🔊 Name to speak: ${widget.recognizedName}");
  
  try {
    await _ttsService.initialize(); // Ensure initialized
    print("🔊 TTS initialized, calling speakClockIn...");
    
    await _ttsService.speakClockIn(widget.recognizedName);
    
    print("✅ TTS speakClockIn completed");
  } catch (e) {
    print("❌ TTS error in _speakGreeting: $e");
  }
}

  // ✅ UPDATED: Clock-in with TTS confirmation
  void _handleClockIn() async {
    print("🔊 Clock-in confirmed for: ${widget.recognizedName}");
    
    // Send API call
    sendDataToApi(
      type: 'clockIn',
      faceImage: widget.faceImage,
      employeeId: '',
    );
    
    // Call parent callback
    widget.onClockIn();
  }

  // ✅ NEW: Retry with TTS stop
  void _handleRetry() {
    print("🔄 User clicked retry");
    
    // Stop any ongoing speech
    _ttsService.stop();
    
    // Call parent callback
    widget.onRetry();
  }

  @override
  void dispose() {
    // ✅ NEW: Stop TTS when leaving
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isTablet = size.width > 600;
    final isTabletLandscape = isTablet && orientation == Orientation.landscape;

    if (isTabletLandscape) {
      return Row(
        children: [
          // Left side: camera preview only
          Expanded(
            flex: 1,
            child: Center(
              child: CircularCameraPreview(
                cameraController: widget.cameraController,
                width: size.width * 0.4,
                height: size.width * 0.45,
              ),
            ),
          ),

          // Right side: card with retry and text above
          Expanded(
            flex: 1,
            child: Center(
              child: SizedBox(
                width: size.width * 0.4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "Not ${widget.recognizedName}?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 150,
                      child: CustomElevatedButton(
                        onPressed: _handleRetry, // ✅ UPDATED
                        label: 'Retry',
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ NEW: Welcome icon
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                widget.recognizedName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ✅ NEW: Status message
                            Text(
                              "Welcome! Ready to clock in?",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CustomElevatedButton(
                              onPressed: _handleClockIn, // ✅ UPDATED
                              label: 'Clock in',
                              icon: Icons.play_arrow,
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.purple,
                            ),
                          ],
                        ),
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

    // ✅ UPDATED: Portrait layout with TTS and better UX
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: size.height * 0.05),
          
          // ✅ NEW: Success indicator
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 40,
            ),
          ),
          
          SizedBox(height: size.height * 0.02),
          
          CircularCameraPreview(
            cameraController: widget.cameraController,
            width: size.width * 0.7,
            height: size.width * 0.7,
          ),
          
          SizedBox(height: size.height * 0.02),
          
          // ✅ NEW: Welcome message
          Text(
            "Welcome, ${widget.recognizedName}!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: size.height * 0.01),
          
          Text(
            "Not ${widget.recognizedName}?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
          ),
          
          SizedBox(height: size.height * 0.02),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.28),
            child: CustomElevatedButton(
              onPressed: _handleRetry, // ✅ UPDATED
              label: 'Retry',
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
          ),
          
          SizedBox(height: size.height * 0.03),
          
          Card(
            margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ✅ NEW: Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Identity Verified",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.02),
                  
                  Text(
                    "Ready to clock in?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.02),
                  
                  CustomElevatedButton(
                    onPressed: _handleClockIn, // ✅ UPDATED
                    label: 'Clock in',
                    icon: Icons.play_arrow,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: size.height * 0.04),
        ],
      ),
    );
  }
}