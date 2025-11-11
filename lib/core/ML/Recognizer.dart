import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'Recognition.dart';

class Recognizer {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;
  static const int WIDTH = 112;
  static const int HEIGHT = 112;

  bool useCosine = true;
  
  // ✅ RELAXED SETTINGS for testing
  double cosineThreshold = 0.22; // Stricter 
  double euclideanThreshold = 1.0;
  double minConfidenceGap = 0.08; //

  Map<String, List<List<double>>> registered = {};

  @override
  String get modelName => 'assets/mobile_face_net.tflite';

  Recognizer({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }
    loadModel();
    loadRegisteredFaces();
  }

  Future<void> loadRegisteredFaces() async {
    registered.clear();
    final box = await Hive.openBox('faces');

    print("📦 Loading registered faces from Hive...");
    print("📊 Total faces in Hive: ${box.keys.length}");

    for (var key in box.keys) {
      final faceData = box.get(key);
      
      List<List<double>> embeddings = [];
      
      if (faceData['embeddings'] != null) {
        for (var emb in faceData['embeddings']) {
          embeddings.add(List<double>.from(emb));
        }
        print("✅ Loaded: ${faceData['name']} (${embeddings.length} embeddings)");
      } else if (faceData['embedding'] != null) {
        embeddings.add(List<double>.from(faceData['embedding']));
        print("✅ Loaded (legacy): ${faceData['name']} (1 embedding)");
      }
      
      if (embeddings.isNotEmpty) {
        registered[faceData['name']] = embeddings;
      }
    }
    print("🎯 Total registered faces: ${registered.length}");
    print("⚙️ Distance metric: ${useCosine ? 'COSINE' : 'EUCLIDEAN'}");
    print("🎚️ Distance threshold: ${useCosine ? cosineThreshold : euclideanThreshold}");
    print("📊 Confidence gap threshold: $minConfidenceGap");
  }

  Future<void> registerFaceInHive(
      String name,
      List<double> embedding,
      Uint8List faceImage,
      String email,
      String phone,
      String employeeId,
      String facilityId) async {
    
    await registerMultipleEmbeddingsInHive(
      name,
      [embedding],
      faceImage,
      email,
      phone,
      employeeId,
      facilityId,
    );
  }

  Future<void> registerMultipleEmbeddingsInHive(
      String name,
      List<List<double>> embeddings,
      Uint8List faceImage,
      String email,
      String phone,
      String employeeId,
      String facilityId) async {
    final box = await Hive.openBox('faces');

    await box.put(name, {
  'name': name,
  'embeddings': embeddings,
  'faceImage': faceImage,
  'email': email,
  'phone': phone,
  'employeeId': employeeId,
  'facilityId': facilityId,
});

print('✅ Successfully registered: $name with ${embeddings.length} embeddings\n');

// ✅ ADD THIS ANALYSIS:
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
  
  print("📊 REGISTRATION QUALITY:");
  print("   Average self-distance: ${avgDist.toStringAsFixed(4)}");
  
  if (avgDist < 0.10) {
    print("   ✅ EXCELLENT - Very consistent");
  } else if (avgDist < 0.15) {
    print("   ✅ GOOD - Acceptable");
  } else if (avgDist < 0.20) {
    print("   ⚠️ FAIR - May have issues");
  } else {
    print("   ❌ POOR - Consider re-registering");
  }
  print("");
}

await loadRegisteredFaces();
  }

  Future<List<List<double>>> extractMultipleEmbeddings(List<img.Image> images) async {
    print("\n🧠 EXTRACTING MULTIPLE EMBEDDINGS");
    print("📸 Images to process: ${images.length}");
    
    List<List<double>> embeddings = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        final embedding = await extractEmbedding(images[i]);
        embeddings.add(embedding);
        
        if ((i + 1) % 10 == 0) {
          print("  ⏳ Progress: ${i + 1}/${images.length} embeddings extracted");
        }
      } catch (e) {
        print("  ⚠️ Failed to extract embedding ${i + 1}: $e");
      }
    }
    
    print("✅ Extraction complete: ${embeddings.length}/${images.length} successful\n");
    return embeddings;
  }

 Future<List<double>> extractEmbedding(img.Image image) async {
  return extractEmbeddingFromCroppedFace(image, verbose: false);
}

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

    final processedImage =
        img.copyResize(decodedImage, width: WIDTH, height: HEIGHT);

    final embedding = await extractEmbedding(processedImage);

    await registerFaceInHive(
      name,
      embedding,
      Uint8List.fromList(img.encodePng(processedImage)),
      email,
      phone,
      employeeId,
      facilityId,
    );

    print("✅ Successfully registered fetched face: $name");
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(modelName);
      print("✅ Model loaded successfully");
      print("📊 Input shape: ${interpreter.getInputTensors().first.shape}");
      print("📊 Output shape: ${interpreter.getOutputTensors().first.shape}");
    } catch (e) {
      print('❌ Unable to create interpreter: ${e.toString()}');
    }
  } 

  // ✅ CRITICAL FIX: Proper image preprocessing for MobileFaceNet
  List<dynamic> imageToArray(img.Image inputImage) {
    // Resize to model input size
    img.Image resizedImage = img.copyResize(inputImage, width: WIDTH, height: HEIGHT);

    // ✅ CRITICAL FIX: Keep channel-last format (HWC) for MobileFaceNet
    List<double> flattenedList = [];
    
    for (int h = 0; h < HEIGHT; h++) {
      for (int w = 0; w < WIDTH; w++) {
        final pixel = resizedImage.getPixel(w, h);
        
        // Normalize to [-1, 1] range (standard for MobileFaceNet)
        flattenedList.add((pixel.r.toDouble() - 127.5) / 127.5);
        flattenedList.add((pixel.g.toDouble() - 127.5) / 127.5);
        flattenedList.add((pixel.b.toDouble() - 127.5) / 127.5);
      }
    }

    Float32List float32Array = Float32List.fromList(flattenedList);
    
    // ✅ Return in HWC format: [1, HEIGHT, WIDTH, CHANNELS]
    return float32Array.reshape([1, HEIGHT, WIDTH, 3]);
  }

  // Recognition logic
Recognition recognize(img.Image image, Rect location) {
  print("\n" + "="*50);
  print("🔍 RECOGNITION START");
  print("="*50);
  
  try {
    // Step 1: Convert image
    print("Step 1: Converting image...");
    var input = imageToArray(image);  // ✅ Synchronous
    print("✅ Image converted");

    // Step 2: Run model
    print("Step 2: Running model...");
    List output = List.filled(1 * 192, 0).reshape([1, 192]);
    interpreter.run(input, output);  // ✅ Synchronous
    List<double> outputArray = output.first.cast<double>();
    print("✅ Model ran, got embedding");

    // Step 3: Check if anyone registered
    if (registered.isEmpty) {
      print("⚠️  No one registered");
      return Recognition("Unknown", location, outputArray, 1.0);
    }

    print("Step 3: Finding matches from ${registered.length} people...");

    // Step 4: Calculate distances to ALL registered people
    List<double> normalizedEmb = _normalize(outputArray);
    
    String bestName = "Unknown";
    double bestDistance = double.infinity;
    String secondBestName = "Unknown";
    double secondBestDistance = double.infinity;

    for (var entry in registered.entries) {
      String personName = entry.key;
      List<List<double>> personEmbeddings = entry.value;
      
      print("  Checking: $personName");
      
      double minDist = double.infinity;
      
      for (var knownEmb in personEmbeddings) {
        List<double> normalizedKnown = _normalize(knownEmb);
        double dist = _cosineDistance(normalizedEmb, normalizedKnown);
        
        if (dist < minDist) {
          minDist = dist;
        }
      }
      
      print("    Min distance: ${minDist.toStringAsFixed(4)}");
      
      if (minDist < bestDistance) {
        secondBestDistance = bestDistance;
        secondBestName = bestName;
        
        bestDistance = minDist;
        bestName = personName;
      } else if (minDist < secondBestDistance) {
        secondBestDistance = minDist;
        secondBestName = personName;
      }
    }

    print("\n🎯 MATCHING RESULTS:");
    print("  1st: $bestName - ${bestDistance.toStringAsFixed(4)}");
    print("  2nd: $secondBestName - ${secondBestDistance.toStringAsFixed(4)}");
    
    // ✅ Check 1: Distance threshold (RELAXED to 0.22)
    if (bestDistance > cosineThreshold) {
      print("  ❌ REJECTED - Distance too high (${bestDistance.toStringAsFixed(4)} > $cosineThreshold)");
      print("="*50 + "\n");
      return Recognition("Unknown", location, outputArray, bestDistance);
    }
    
    // ✅ Check 2: Confidence gap (RELAXED to 0.08)
    double confidenceGap = secondBestDistance - bestDistance;
    print("  📊 Confidence gap: ${confidenceGap.toStringAsFixed(4)}");
    
    if (registered.length > 1 && confidenceGap < minConfidenceGap) {
      print("  ❌ REJECTED - Ambiguous match (gap ${confidenceGap.toStringAsFixed(4)} < $minConfidenceGap)");
      print("  ⚠️  Could be either $bestName or $secondBestName");
      print("="*50 + "\n");
      return Recognition("Unknown", location, outputArray, bestDistance);
    }
    
    // ✅ Check 3: Multiple embedding verification (RELAXED to 20%)
    int matchingEmbeddings = 0;
    int totalEmbeddings = registered[bestName]!.length;
    
    for (var knownEmb in registered[bestName]!) {
      List<double> normalizedKnown = _normalize(knownEmb);
      double dist = _cosineDistance(normalizedEmb, normalizedKnown);
      
      if (dist <= cosineThreshold) {
        matchingEmbeddings++;
      }
    }
    
    double matchPercentage = (matchingEmbeddings / totalEmbeddings) * 100;
    print("  📊 Matching embeddings: $matchingEmbeddings/$totalEmbeddings (${matchPercentage.toStringAsFixed(1)}%)");
    
    if (matchPercentage < 20) {  // ✅ RELAXED from 30% to 20%
      print("  ❌ REJECTED - Too few embeddings match (${matchPercentage.toStringAsFixed(0)}% < 20%)");
      print("="*50 + "\n");
      return Recognition("Unknown", location, outputArray, bestDistance);
    }

    print("  ✅ ACCEPTED - All checks passed");
    print("="*50 + "\n");
    
    return Recognition(
      bestName, 
      location, 
      outputArray, 
      bestDistance,
      secondBestName: secondBestName,
      secondBestDistance: secondBestDistance,
      confidenceGap: confidenceGap,
    );

  } catch (e, stack) {
    print("❌ ERROR: $e");
    print("Stack: $stack");
    print("="*50 + "\n");
    return Recognition("Unknown", location, [], 1.0);
  }
}



  double _euclideanDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return double.infinity;
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      double diff = e1[i] - e2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

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

  // ✅ NEW: Test registration quality
  Future<void> testRegistrationQuality(String name) async {
    final embeddings = registered[name];
    if (embeddings == null || embeddings.length < 2) {
      print("⚠️ Not enough embeddings to test ($name)");
      return;
    }
    
    print("\n🧪 TESTING REGISTRATION QUALITY for $name");
    print("=" * 50);
    
    List<double> distances = [];
    
    // Compare all pairs of embeddings
    for (int i = 0; i < embeddings.length; i++) {
      for (int j = i + 1; j < embeddings.length; j++) {
        double dist = _cosineDistance(
          _normalize(embeddings[i]),
          _normalize(embeddings[j])
        );
        distances.add(dist);
      }
    }
    
    if (distances.isEmpty) {
      print("❌ No distance calculations possible");
      return;
    }
    
    distances.sort();
    double avgDist = distances.reduce((a, b) => a + b) / distances.length;
    double minDist = distances.first;
    double maxDist = distances.last;
    
    print("📊 Self-similarity analysis:");
    print("  Total embeddings: ${embeddings.length}");
    print("  Total comparisons: ${distances.length}");
    print("  Min distance: ${minDist.toStringAsFixed(4)}");
    print("  Avg distance: ${avgDist.toStringAsFixed(4)}");
    print("  Max distance: ${maxDist.toStringAsFixed(4)}");
    
    // Quality assessment
    String quality;
    if (avgDist < 0.10) {
      quality = "✅ EXCELLENT - Very consistent embeddings";
    } else if (avgDist < 0.15) {
      quality = "✅ GOOD - Acceptable consistency";
    } else if (avgDist < 0.20) {
      quality = "⚠️ FAIR - Some inconsistency detected";
    } else {
      quality = "❌ POOR - High inconsistency, consider re-registering";
    }
    
    print("  Quality: $quality");
    print("  Recommended threshold: ${(avgDist + 0.08).toStringAsFixed(2)}");
    print("=" * 50 + "\n");
  }

  void close() {
    interpreter.close();
  }

  // ADD THIS METHOD to Recognizer class:
Future<void> debugCompareRegistrationVsLive(
  img.Image registeredImage,
  img.Image liveImage,
  String personName
) async {
  print("\n" + "🔬 DIAGNOSTIC TEST: Registration vs Live" + "\n");
  print("Testing: $personName");
  
  // Extract embedding from registered image (same as registration flow)
  print("\n1️⃣ REGISTRATION PATH:");
  var regEmb = await extractEmbedding(registeredImage);
  print("   Embedding sample: [${regEmb.take(5).join(', ')}...]");
  print("   Norm: ${sqrt(regEmb.map((x) => x * x).reduce((a, b) => a + b))}");
  
  // Extract embedding from live image (same as recognition flow)
  print("\n2️⃣ LIVE RECOGNITION PATH:");
  var liveEmb = await extractEmbedding(liveImage);
  print("   Embedding sample: [${liveEmb.take(5).join(', ')}...]");
  print("   Norm: ${sqrt(liveEmb.map((x) => x * x).reduce((a, b) => a + b))}");
  
  // Compare
  double dist = _cosineDistance(_normalize(regEmb), _normalize(liveEmb));
  print("\n3️⃣ COMPARISON:");
  print("   Distance: ${dist.toStringAsFixed(4)}");
  print("   Expected: < 0.15 for same person");
  
  if (dist > 0.30) {
    print("   ❌ CRITICAL: Embeddings are COMPLETELY different!");
    print("   This indicates preprocessing mismatch");
  } else if (dist > 0.20) {
    print("   ⚠️  WARNING: High distance, but might work with relaxed threshold");
  } else {
    print("   ✅ GOOD: Embeddings are similar");
  }
  
  // Get stored embeddings
  if (registered[personName] != null) {
    print("\n4️⃣ STORED EMBEDDINGS:");
    var stored = registered[personName]!;
    print("   Count: ${stored.length}");
    
    double minDistToStored = double.infinity;
    for (var storedEmb in stored) {
      double d = _cosineDistance(_normalize(liveEmb), _normalize(storedEmb));
      if (d < minDistToStored) minDistToStored = d;
    }
    
    print("   Min distance to stored: ${minDistToStored.toStringAsFixed(4)}");
    print("   This should be < 0.20 for recognition to work");
  }
  
  print("\n" + "="*60 + "\n");
}

// ADD THIS METHOD to Recognizer class:
Future<List<double>> extractEmbeddingFromCroppedFace(
  img.Image croppedFace,
  {bool verbose = false}
) async {
  if (verbose) {
    print("  🔧 Input: ${croppedFace.width}x${croppedFace.height}");
  }
  
  // Step 1: Resize to model input
  final resized = img.copyResize(croppedFace, width: WIDTH, height: HEIGHT);
  
  if (verbose) {
    print("  🔧 Resized: ${resized.width}x${resized.height}");
  }
  
  // Step 2: Convert to array (normalized)
  final input = imageToArray(resized);
  
  // Step 3: Run model
  List output = List.filled(1 * 192, 0).reshape([1, 192]);
  interpreter.run(input, output);
  
  List<double> embedding = output.first.cast<double>();
  
  if (verbose) {
    print("  🔧 Embedding: [${embedding.take(3).join(', ')}...]");
    print("  🔧 Norm: ${sqrt(embedding.map((x) => x * x).reduce((a, b) => a + b)).toStringAsFixed(4)}");
  }
  
  return embedding;
}
}

// Keep these for compatibility
class MatchResult {
  String bestName;
  double bestDistance;
  String? secondBestName;
  double? secondBestDistance;
  double confidenceGap;
  
  MatchResult({
    required this.bestName,
    required this.bestDistance,
    this.secondBestName,
    this.secondBestDistance,
    required this.confidenceGap,
  });
}

class PersonMatch {
  String name;
  double distance;
  PersonMatch(this.name, this.distance);
}

class Pair {
  String name;
  double distance;
  Pair(this.name, this.distance);
}