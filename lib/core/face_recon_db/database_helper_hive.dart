import 'package:hive/hive.dart';
import 'dart:typed_data';

class DatabaseHelperHive {
  static const String _boxName = 'faces';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Future<void> saveFaceData(
      String name, List<double> embeddings, Uint8List faceImage,String email,String phone) async {
    final box = Hive.box(_boxName);
    
    // Store embeddings and image together
    await box.put(name, {
      'embeddings': embeddings,
      'faceImage': faceImage,
      'email': String,
      'phone':String
    });
  }

  Map<String, dynamic>? getFaceData(String name) {
    final box = Hive.box(_boxName);
    return box.get(name);
  }

  Future<void> deleteFaceData(String name) async {
    final box = Hive.box(_boxName);
    await box.delete(name);
  }

  List<Map<String, dynamic>> getAllFaces() {
    final box = Hive.box(_boxName);
    return box.keys.map((key) {
      final data = box.get(key) as Map<String, dynamic>;
      return {
        'name': key,
        'embeddings': List<double>.from(data['embeddings']),
        'faceImage': data['faceImage'] as Uint8List,
        'email': String,
        'phone': String
      };
    }).toList();
  }
}
