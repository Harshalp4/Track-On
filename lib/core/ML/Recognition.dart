import 'dart:ui';

class Recognition {
  String name;
  Rect location;
  List<double> embeddings;
  double distance;
  
  // ✅ Confidence metrics
  String? secondBestName;
  double? secondBestDistance;
  double? confidenceGap;
  
  Recognition(
    this.name, 
    this.location,
    this.embeddings,
    this.distance, {
    this.secondBestName,
    this.secondBestDistance,
    this.confidenceGap,
  });
}