import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'Recognition.dart';

/// ✅ ENHANCED RECOGNIZER with better distance metrics and verification
/// Compatible with both MobileFaceNet (192D) and ArcFace (512D)
class RecognizerV2 {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;
  
  static const int WIDTH = 112;
  static const int HEIGHT = 112;
  
  // ✅ Model configuration - auto-detected from model output
  int embeddingSize = 192; // Will be updated after model loads
  bool isArcFace = false;
  
  // ✅ ADAPTIVE THRESHOLDS based on model type
  double cosineThreshold = 0.18;      // Stricter for ArcFace
  double minConfidenceGap = 0.10;     // Clear separation needed
  double minMatchPercentage = 0.30;   // 30% of embeddings must match
  
  Map<String, List<List<double>>> registered = {};
  
  String get modelName => 'assets/mobile_face_net.tflite';
  // String get modelName => 'assets/models/arcface_mobilefacenet.tflite'; // Uncomment when upgrading
  
  RecognizerV2({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();
    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }
    loadModel();
    loadRegisteredFaces();
  }
  
  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(modelName);
      
      // ✅ AUTO-DETECT embedding size from model
      var outputShape = interpreter.getOutputTensors().first.shape;
      embeddingSize = outputShape.last; // Last dimension is embedding size
      
      // ✅ Detect if this is ArcFace (512D) or MobileFaceNet (192D)
      isArcFace = embeddingSize >= 512;
      
      // ✅ ADAPTIVE THRESHOLDS based on model
      if (isArcFace) {
        cosineThreshold = 0.18;      // ArcFace: stricter threshold
        minConfidenceGap = 0.12;     // ArcFace: needs clear separation
        minMatchPercentage = 0.25;   // ArcFace: 25% is enough
      } else {
        cosineThreshold = 0.20;      // MobileFaceNet: relaxed
        minConfidenceGap = 0.08;     // MobileFaceNet: less strict
        minMatchPercentage = 0.20;   // MobileFaceNet: 20% minimum
      }
      
      print("✅ Model loaded successfully");
      print("📊 Model type: ${isArcFace ? 'ArcFace' : 'MobileFaceNet'}");
      print("📊 Embedding size: $embeddingSize");
      print("📊 Input shape: ${interpreter.getInputTensors().first.shape}");
      print("📊 Output shape: $outputShape");
      print("🎚️ Cosine threshold: $cosineThreshold");
      print("🎚️ Confidence gap: $minConfidenceGap");
      print("🎚️ Match percentage: ${(minMatchPercentage * 100).toInt()}%");
    } catch (e) {
      print('❌ Unable to create interpreter: ${e.toString()}');
      rethrow;
    }
  }
  
  Future<void> loadRegisteredFaces() async {
    registered.clear();
    final box = await Hive.openBox('faces');
    
    print("\n📦 Loading registered faces from Hive...");
    print("📊 Total faces in Hive: ${box.keys.length}");
    
    for (var key in box.keys) {
      final faceData = box.get(key);
      
      List<List<double>> embeddings = [];
      
      if (faceData['embeddings'] != null) {
        for (var emb in faceData['embeddings']) {
          var embList = List<double>.from(emb);
          
          // ✅ CRITICAL: Validate embedding size matches model
          if (embList.length != embeddingSize) {
            print("⚠️  ${faceData['name']}: Embedding size mismatch (${embList.length} vs $embeddingSize) - SKIPPING");
            continue;
          }
          
          embeddings.add(embList);
        }
        
        if (embeddings.isNotEmpty) {
          print("✅ Loaded: ${faceData['name']} (${embeddings.length} embeddings)");
        }
      } else if (faceData['embedding'] != null) {
        var embList = List<double>.from(faceData['embedding']);
        
        if (embList.length == embeddingSize) {
          embeddings.add(embList);
          print("✅ Loaded (legacy): ${faceData['name']} (1 embedding)");
        } else {
          print("⚠️  ${faceData['name']}: Legacy embedding size mismatch - SKIPPING");
        }
      }
      
      if (embeddings.isNotEmpty) {
        registered[faceData['name']] = embeddings;
      }
    }
    
    print("🎯 Total registered faces: ${registered.length}");
    print("⚙️ Distance metric: COSINE\n");
  }
  
  /// ✅ ENHANCED: Register face with quality validation
  Future<void> registerMultipleEmbeddingsInHive(
      String name,
      List<List<double>> embeddings,
      Uint8List faceImage,
      String email,
      String phone,
      String employeeId,
      String facilityId) async {
    
    print("\n📝 REGISTERING: $name");
    print("📊 Embeddings to store: ${embeddings.length}");
    
    // ✅ VALIDATION: Check embedding size
    bool allValid = embeddings.every((emb) => emb.length == embeddingSize);
    if (!allValid) {
      throw Exception("❌ Embedding size mismatch! Expected $embeddingSize");
    }
    
    // ✅ QUALITY CHECK: Analyze self-similarity
    if (embeddings.length > 1) {
      List<double> distances = [];
      for (int i = 0; i < embeddings.length; i++) {
        for (int j = i + 1; j < embeddings.length; j++) {
          double dist = _cosineDistance(
            _normalize(embeddings[i]),
            _normalize(embeddings[j])
          );
          distances.add(dist);
        }
      }
      
      distances.sort();
      double avgDist = distances.reduce((a, b) => a + b) / distances.length;
      double maxDist = distances.last;
      
      print("📊 REGISTRATION QUALITY:");
      print("   Average self-distance: ${avgDist.toStringAsFixed(4)}");
      print("   Max self-distance: ${maxDist.toStringAsFixed(4)}");
      
      String quality;
      if (avgDist < 0.10) {
        quality = "✅ EXCELLENT - Very consistent";
      } else if (avgDist < 0.15) {
        quality = "✅ GOOD - Acceptable";
      } else if (avgDist < 0.20) {
        quality = "⚠️  FAIR - May have recognition issues";
      } else {
        quality = "❌ POOR - Consider re-registering";
        print("⚠️  WARNING: High self-distance detected!");
      }
      
      print("   Quality: $quality");
      
      // ✅ RECOMMENDATION: Suggest threshold
      double recommendedThreshold = avgDist + 0.10;
      print("   Suggested recognition threshold: ${recommendedThreshold.toStringAsFixed(2)}");
    }
    
    final box = await Hive.openBox('faces');
    
    await box.put(name, {
      'name': name,
      'embeddings': embeddings,
      'faceImage': faceImage,
      'email': email,
      'phone': phone,
      'employeeId': employeeId,
      'facilityId': facilityId,
      'embeddingSize': embeddingSize,  // ✅ NEW: Store model info
      'modelType': isArcFace ? 'arcface' : 'mobilefacenet',
      'registrationDate': DateTime.now().toIso8601String(),
    });
    
    print('✅ Successfully registered: $name with ${embeddings.length} embeddings\n');
    
    await loadRegisteredFaces();
  }
  
  /// ✅ ENHANCED: Recognition with multiple verification layers
  Recognition recognize(img.Image image, Rect location) {
    print("\n" + "="*60);
    print("🔍 RECOGNITION START");
    print("="*60);
    
    try {
      // Step 1: Extract embedding
      print("Step 1: Extracting embedding...");
      var input = imageToArray(image);
      
      List output = List.filled(1 * embeddingSize, 0.0).reshape([1, embeddingSize]);
      interpreter.run(input, output);
      List<double> outputArray = output.first.cast<double>();
      
      print("✅ Embedding extracted (${outputArray.length}D)");
      
      // Step 2: Check if anyone registered
      if (registered.isEmpty) {
        print("⚠️  No one registered");
        return Recognition("Unknown", location, outputArray, 1.0);
      }
      
      print("Step 2: Comparing with ${registered.length} registered people...");
      
      // Step 3: Calculate distances with ALL registered faces
      List<double> normalizedEmb = _normalize(outputArray);
      
      List<PersonMatch> allMatches = [];
      
      for (var entry in registered.entries) {
        String personName = entry.key;
        List<List<double>> personEmbeddings = entry.value;
        
        // ✅ ENHANCED: Calculate statistics across all embeddings
        List<double> distances = [];
        
        for (var knownEmb in personEmbeddings) {
          List<double> normalizedKnown = _normalize(knownEmb);
          double dist = _cosineDistance(normalizedEmb, normalizedKnown);
          distances.add(dist);
        }
        
        // ✅ Use MINIMUM distance (best match)
        double minDist = distances.reduce(min);
        
        // ✅ Calculate how many embeddings match
        int matchingCount = distances.where((d) => d <= cosineThreshold).length;
        double matchPercentage = matchingCount / distances.length;
        
        print("  $personName:");
        print("    Min: ${minDist.toStringAsFixed(4)}");
        print("    Matching: $matchingCount/${distances.length} (${(matchPercentage * 100).toStringAsFixed(0)}%)");
        
        allMatches.add(PersonMatch(
          name: personName,
          distance: minDist,
          matchingCount: matchingCount,
          totalEmbeddings: distances.length,
          matchPercentage: matchPercentage,
        ));
      }
      
      // Step 4: Sort by distance
      allMatches.sort((a, b) => a.distance.compareTo(b.distance));
      
      PersonMatch best = allMatches.first;
      PersonMatch? secondBest = allMatches.length > 1 ? allMatches[1] : null;
      
      print("\n🎯 MATCHING RESULTS:");
      print("  1st: ${best.name}");
      print("    Distance: ${best.distance.toStringAsFixed(4)}");
      print("    Matching: ${best.matchingCount}/${best.totalEmbeddings} (${(best.matchPercentage * 100).toStringAsFixed(0)}%)");
      
      if (secondBest != null) {
        print("  2nd: ${secondBest.name}");
        print("    Distance: ${secondBest.distance.toStringAsFixed(4)}");
      }
      
      // ✅ VERIFICATION LAYER 1: Distance threshold
      if (best.distance > cosineThreshold) {
        print("\n❌ REJECTED - Distance too high");
        print("   ${best.distance.toStringAsFixed(4)} > $cosineThreshold");
        print("="*60 + "\n");
        return Recognition("Unknown", location, outputArray, best.distance);
      }
      
      // ✅ VERIFICATION LAYER 2: Confidence gap
      double confidenceGap = 0.0;
      if (secondBest != null && registered.length > 1) {
        confidenceGap = secondBest.distance - best.distance;
        print("\n📊 Confidence gap: ${confidenceGap.toStringAsFixed(4)}");
        
        if (confidenceGap < minConfidenceGap) {
          print("❌ REJECTED - Ambiguous match");
          print("   Gap ${confidenceGap.toStringAsFixed(4)} < $minConfidenceGap");
          print("   Could be ${best.name} or ${secondBest.name}");
          print("="*60 + "\n");
          return Recognition("Unknown", location, outputArray, best.distance);
        }
      }
      
      // ✅ VERIFICATION LAYER 3: Multi-embedding consensus
      if (best.matchPercentage < minMatchPercentage) {
        print("\n❌ REJECTED - Insufficient embedding consensus");
        print("   ${(best.matchPercentage * 100).toStringAsFixed(0)}% < ${(minMatchPercentage * 100).toInt()}%");
        print("="*60 + "\n");
        return Recognition("Unknown", location, outputArray, best.distance);
      }
      
      // ✅ ALL CHECKS PASSED
      print("\n✅ VERIFIED MATCH: ${best.name}");
      print("   Distance: ${best.distance.toStringAsFixed(4)}");
      print("   Confidence: ${((1 - best.distance) * 100).toStringAsFixed(1)}%");
      print("   Consensus: ${(best.matchPercentage * 100).toStringAsFixed(0)}%");
      print("="*60 + "\n");
      
      return Recognition(
        best.name,
        location,
        outputArray,
        best.distance,
        secondBestName: secondBest?.name,
        secondBestDistance: secondBest?.distance,
        confidenceGap: confidenceGap,
      );
      
    } catch (e, stack) {
      print("❌ ERROR: $e");
      print("Stack: $stack");
      print("="*60 + "\n");
      return Recognition("Unknown", location, [], 1.0);
    }
  }
  
  /// ✅ ENHANCED: Image preprocessing with proper normalization
  List<dynamic> imageToArray(img.Image inputImage) {
    img.Image resizedImage = img.copyResize(inputImage, width: WIDTH, height: HEIGHT);
    
    List<double> flattenedList = [];
    
    // ✅ ADAPTIVE NORMALIZATION based on model type
    if (isArcFace) {
      // ArcFace models typically use [0, 1] normalization
      for (int h = 0; h < HEIGHT; h++) {
        for (int w = 0; w < WIDTH; w++) {
          final pixel = resizedImage.getPixel(w, h);
          flattenedList.add(pixel.r.toDouble() / 255.0);
          flattenedList.add(pixel.g.toDouble() / 255.0);
          flattenedList.add(pixel.b.toDouble() / 255.0);
        }
      }
    } else {
      // MobileFaceNet uses [-1, 1] normalization
      for (int h = 0; h < HEIGHT; h++) {
        for (int w = 0; w < WIDTH; w++) {
          final pixel = resizedImage.getPixel(w, h);
          flattenedList.add((pixel.r.toDouble() - 127.5) / 127.5);
          flattenedList.add((pixel.g.toDouble() - 127.5) / 127.5);
          flattenedList.add((pixel.b.toDouble() - 127.5) / 127.5);
        }
      }
    }
    
    Float32List float32Array = Float32List.fromList(flattenedList);
    return float32Array.reshape([1, HEIGHT, WIDTH, 3]);
  }
  
  /// ✅ Extract multiple embeddings from image list
  Future<List<List<double>>> extractMultipleEmbeddings(List<img.Image> images) async {
    print("\n🧠 EXTRACTING MULTIPLE EMBEDDINGS");
    print("📸 Images to process: ${images.length}");
    
    List<List<double>> embeddings = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        final embedding = await extractEmbedding(images[i]);
        embeddings.add(embedding);
        
        if ((i + 1) % 10 == 0) {
          print("  ⏳ Progress: ${i + 1}/${images.length}");
        }
      } catch (e) {
        print("  ⚠️ Failed to extract embedding ${i + 1}: $e");
      }
    }
    
    print("✅ Extraction complete: ${embeddings.length}/${images.length} successful\n");
    return embeddings;
  }
  
  Future<List<double>> extractEmbedding(img.Image image) async {
    var input = imageToArray(image);
    List output = List.filled(1 * embeddingSize, 0.0).reshape([1, embeddingSize]);
    interpreter.run(input, output);
    return output.first.cast<double>();
  }
  
  // ✅ Distance calculation methods
  double _cosineDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return double.infinity;
    
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < e1.length; i++) {
      dot += e1[i] * e2[i];
      normA += e1[i] * e1[i];
      normB += e2[i] * e2[i];
    }
    
    if (normA == 0 || normB == 0) return double.infinity;
    
    double similarity = dot / (sqrt(normA) * sqrt(normB));
    return 1 - similarity;
  }
  
  List<double> _normalize(List<double> embedding) {
    double norm = sqrt(embedding.map((x) => x * x).reduce((a, b) => a + b));
    if (norm == 0) return embedding;
    return embedding.map((x) => x / norm).toList();
  }
  
  void close() {
    interpreter.close();
  }

  // ✅ ADD THIS METHOD to RecognizerV2 class for compatibility
Future<void> registerFetchedFace({
  required Uint8List imageBytes,
  required String name,
  String email = '',
  String phone = '',
  String employeeId = '',
  String facilityId = '',
}) async {
  print("📡 Registering fetched face: $name");

  final decodedImage = img.decodeImage(imageBytes);
  if (decodedImage == null) {
    print("❌ Could not decode image for $name");
    return;
  }

  final processedImage = img.copyResize(decodedImage, width: WIDTH, height: HEIGHT);

  final embedding = await extractEmbedding(processedImage);

  await registerMultipleEmbeddingsInHive(
    name,
    [embedding], // Single embedding for fetched faces
    Uint8List.fromList(img.encodePng(processedImage)),
    email,
    phone,
    employeeId,
    facilityId,
  );

  print("✅ Successfully registered fetched face: $name");
}
}

/// ✅ Enhanced match result with statistics
class PersonMatch {
  final String name;
  final double distance;
  final int matchingCount;
  final int totalEmbeddings;
  final double matchPercentage;
  
  PersonMatch({
    required this.name,
    required this.distance,
    required this.matchingCount,
    required this.totalEmbeddings,
    required this.matchPercentage,
  });
}