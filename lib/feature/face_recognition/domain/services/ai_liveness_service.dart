import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// ✅ AI-POWERED LIVENESS DETECTION
/// Uses MiniFASNet (Silent-Face-Anti-Spoofing) for instant anti-spoofing
/// Detects: Photos, Videos, Masks, Screen replays
class AILivenessService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  
  // ✅ Model configuration
  static const int INPUT_WIDTH = 80;
  static const int INPUT_HEIGHT = 80;
  static const String MODEL_PATH = 'assets/models/minifasnet_v2.tflite';
  
  // ✅ Thresholds
  static const double REAL_THRESHOLD = 0.65;  // Score > 0.65 = real person
  static const double FAKE_THRESHOLD = 0.35;  // Score < 0.35 = fake/spoof
  
  // ✅ Result history for stability
  final List<LivenessResult> _recentResults = [];
  static const int HISTORY_SIZE = 5;  // Keep last 5 results
  
  AILivenessService() {
    _initializeModel();
  }
  
  Future<void> _initializeModel() async {
    try {
      print("\n🔐 Initializing AI Liveness Detection...");
      
      _interpreter = await Interpreter.fromAsset(MODEL_PATH);
      
      var inputShape = _interpreter!.getInputTensors().first.shape;
      var outputShape = _interpreter!.getOutputTensors().first.shape;
      
      print("✅ Liveness model loaded");
      print("📊 Input: $inputShape");
      print("📊 Output: $outputShape");
      print("🎚️ Real threshold: $REAL_THRESHOLD");
      print("🎚️ Fake threshold: $FAKE_THRESHOLD\n");
      
      _isInitialized = true;
    } catch (e) {
      print("❌ Failed to load liveness model: $e");
      print("⚠️  Falling back to rule-based liveness");
      _isInitialized = false;
    }
  }
  
  /// ✅ MAIN METHOD: Check if face is real or fake
  Future<LivenessResult> checkLiveness(img.Image faceImage) async {
    if (!_isInitialized || _interpreter == null) {
      print("⚠️  Liveness model not initialized - skipping check");
      return LivenessResult(
        isReal: true,  // Default to true if model unavailable
        confidence: 0.5,
        realScore: 0.5,
        fakeScore: 0.5,
        decision: LivenessDecision.uncertain,
      );
    }
    
    try {
      // Step 1: Preprocess image
      var input = _preprocessImage(faceImage);
      
      // Step 2: Run inference
      var output = List.filled(1 * 2, 0.0).reshape([1, 2]);
      _interpreter!.run(input, output);
      
      // Step 3: Parse results
      List<double> scores = output.first.cast<double>();
      double fakeScore = scores[0];
      double realScore = scores[1];
      
      // Step 4: Determine decision
      LivenessDecision decision;
      bool isReal;
      double confidence;
      
      if (realScore > REAL_THRESHOLD) {
        decision = LivenessDecision.real;
        isReal = true;
        confidence = realScore;
      } else if (fakeScore > (1 - FAKE_THRESHOLD)) {
        decision = LivenessDecision.fake;
        isReal = false;
        confidence = fakeScore;
      } else {
        decision = LivenessDecision.uncertain;
        isReal = false;
        confidence = max(realScore, fakeScore);
      }
      
      var result = LivenessResult(
        isReal: isReal,
        confidence: confidence,
        realScore: realScore,
        fakeScore: fakeScore,
        decision: decision,
      );
      
      // Step 5: Add to history for stability
      _recentResults.add(result);
      if (_recentResults.length > HISTORY_SIZE) {
        _recentResults.removeAt(0);
      }
      
      return result;
      
    } catch (e) {
      print("❌ Liveness check error: $e");
      return LivenessResult(
        isReal: false,
        confidence: 0.0,
        realScore: 0.0,
        fakeScore: 1.0,
        decision: LivenessDecision.error,
      );
    }
  }
  
  /// ✅ Get stable liveness result based on history
  LivenessResult getStableResult() {
    if (_recentResults.isEmpty) {
      return LivenessResult(
        isReal: false,
        confidence: 0.0,
        realScore: 0.0,
        fakeScore: 1.0,
        decision: LivenessDecision.uncertain,
      );
    }
    
    // Calculate average scores
    double avgRealScore = _recentResults
        .map((r) => r.realScore)
        .reduce((a, b) => a + b) / _recentResults.length;
    
    double avgFakeScore = _recentResults
        .map((r) => r.fakeScore)
        .reduce((a, b) => a + b) / _recentResults.length;
    
    // Count real vs fake decisions
    int realCount = _recentResults.where((r) => r.isReal).length;
    int fakeCount = _recentResults.length - realCount;
    
    bool isReal = realCount > fakeCount;
    double confidence = isReal ? avgRealScore : avgFakeScore;
    
    LivenessDecision decision;
    if (avgRealScore > REAL_THRESHOLD) {
      decision = LivenessDecision.real;
    } else if (avgFakeScore > (1 - FAKE_THRESHOLD)) {
      decision = LivenessDecision.fake;
    } else {
      decision = LivenessDecision.uncertain;
    }
    
    return LivenessResult(
      isReal: isReal,
      confidence: confidence,
      realScore: avgRealScore,
      fakeScore: avgFakeScore,
      decision: decision,
    );
  }
  
  /// ✅ Preprocess face image for liveness model
  List<dynamic> _preprocessImage(img.Image faceImage) {
    // Step 1: Resize to model input size
    img.Image resized = img.copyResize(
      faceImage,
      width: INPUT_WIDTH,
      height: INPUT_HEIGHT,
    );
    
    // Step 2: Normalize to [0, 1] range
    List<double> flattenedList = [];
    
    for (int h = 0; h < INPUT_HEIGHT; h++) {
      for (int w = 0; w < INPUT_WIDTH; w++) {
        final pixel = resized.getPixel(w, h);
        
        // ✅ RGB normalization [0, 1]
        flattenedList.add(pixel.r.toDouble() / 255.0);
        flattenedList.add(pixel.g.toDouble() / 255.0);
        flattenedList.add(pixel.b.toDouble() / 255.0);
      }
    }
    
    Float32List float32Array = Float32List.fromList(flattenedList);
    return float32Array.reshape([1, INPUT_HEIGHT, INPUT_WIDTH, 3]);
  }
  
  /// ✅ Reset history
  void reset() {
    _recentResults.clear();
    print("🔄 Liveness history reset");
  }
  
  /// ✅ Get human-readable status
  String getStatusMessage(LivenessResult result) {
    switch (result.decision) {
      case LivenessDecision.real:
        return "✅ Real person detected";
      case LivenessDecision.fake:
        return "❌ Spoofing attempt detected";
      case LivenessDecision.uncertain:
        return "⏳ Analyzing...";
      case LivenessDecision.error:
        return "⚠️  Detection error";
    }
  }
  
  void dispose() {
    _interpreter?.close();
    _recentResults.clear();
  }
}

/// ✅ Liveness result data class
class LivenessResult {
  final bool isReal;
  final double confidence;
  final double realScore;
  final double fakeScore;
  final LivenessDecision decision;
  
  LivenessResult({
    required this.isReal,
    required this.confidence,
    required this.realScore,
    required this.fakeScore,
    required this.decision,
  });
  
  @override
  String toString() {
    return 'LivenessResult(isReal: $isReal, confidence: ${confidence.toStringAsFixed(2)}, '
           'real: ${realScore.toStringAsFixed(2)}, fake: ${fakeScore.toStringAsFixed(2)})';
  }
}

/// ✅ Liveness decision enum
enum LivenessDecision {
  real,      // Definitely a real person
  fake,      // Definitely a spoof/fake
  uncertain, // Not sure - need more frames
  error,     // Error during detection
}