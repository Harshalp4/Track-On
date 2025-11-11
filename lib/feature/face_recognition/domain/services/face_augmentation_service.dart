import 'dart:math';
import 'package:image/image.dart' as img;

class FaceAugmentationService {
  
  /// ✅ Main method - generates minimal, safe augmentations
 static List<img.Image> generateFromMultiplePhotos(List<img.Image> photos) {
  List<img.Image> augmented = [];
  
  print("\n🎨 Starting IMPROVED augmentation...");
  print("📸 Input photos: ${photos.length}");
  
  for (int i = 0; i < photos.length; i++) {
    var photo = photos[i];
    print("  Processing photo ${i + 1}/${photos.length}");
    
    // ✅ 1. Original (most important)
    augmented.add(_resize(photo));
    
    // ✅ 2-3. Slight brightness (reduced from ±10% to ±7%)
    augmented.add(_changeBrightness(photo, 1.07));
    augmented.add(_changeBrightness(photo, 0.93));
    
    // ✅ 4-5. Gamma correction (better than linear brightness)
    augmented.add(_adjustGamma(photo, 1.15));
    augmented.add(_adjustGamma(photo, 0.85));
    
    // ✅ 6-7. Slight contrast (reduced from ±10% to ±7%)
    augmented.add(_changeContrast(photo, 1.07));
    augmented.add(_changeContrast(photo, 0.93));
    
    // ✅ 8-9. Small random crops (simulate distance variation)
    augmented.add(_randomCrop(photo, 0.95));
    augmented.add(_randomCrop(photo, 0.90));
    
    // ✅ 10. Slight blur (simulates motion)
    augmented.add(_slightBlur(photo));
    
    // REMOVED: Horizontal flip (creates unnatural mirror faces)
  }
  
  print("✅ Generated ${augmented.length} images from ${photos.length} photos");
  print("📊 Expected: ${photos.length * 10} embeddings\n");
  
  return augmented;
}

// ADD these new methods:

static img.Image _adjustGamma(img.Image src, double gamma) {
  var resized = _resize(src);
  var result = img.Image.from(resized);
  
  for (int y = 0; y < result.height; y++) {
    for (int x = 0; x < result.width; x++) {
      var pixel = result.getPixel(x, y);
      
      // Gamma correction formula
      int r = (255 * pow(pixel.r / 255.0, gamma)).clamp(0, 255).toInt();
      int g = (255 * pow(pixel.g / 255.0, gamma)).clamp(0, 255).toInt();
      int b = (255 * pow(pixel.b / 255.0, gamma)).clamp(0, 255).toInt();
      
      result.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
    }
  }
  
  return result;
}

static img.Image _randomCrop(img.Image src, double scaleFactor) {
  var resized = _resize(src);
  
  int newWidth = (resized.width * scaleFactor).toInt();
  int newHeight = (resized.height * scaleFactor).toInt();
  
  int offsetX = ((resized.width - newWidth) / 2).toInt();
  int offsetY = ((resized.height - newHeight) / 2).toInt();
  
  var cropped = img.copyCrop(
    resized,
    x: offsetX,
    y: offsetY,
    width: newWidth,
    height: newHeight,
  );
  
  return img.copyResize(cropped, width: 112, height: 112);
}

static img.Image _slightBlur(img.Image src) {
  var resized = _resize(src);
  return img.gaussianBlur(resized, radius: 1);
}

 /// Resize to standard MobileFaceNet input size
  static img.Image _resize(img.Image src) {
    return img.copyResize(src, width: 112, height: 112);
  }
  
  /// Manual brightness adjustment using pixel manipulation
  static img.Image _changeBrightness(img.Image src, double factor) {
    var resized = _resize(src);
    var result = img.Image.from(resized);
    
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        var pixel = result.getPixel(x, y);
        
        // Apply brightness factor and clamp to valid range
        int r = (pixel.r * factor).clamp(0, 255).toInt();
        int g = (pixel.g * factor).clamp(0, 255).toInt();
        int b = (pixel.b * factor).clamp(0, 255).toInt();
        
        // ✅ Fixed: setPixel with proper ColorRgba8
        result.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
      }
    }
    
    return result;
  }
  
  /// Manual contrast adjustment using pixel manipulation
  static img.Image _changeContrast(img.Image src, double factor) {
    var resized = _resize(src);
    var result = img.Image.from(resized);
    
    // Contrast formula: new = (old - 128) * factor + 128
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        var pixel = result.getPixel(x, y);
        
        // Apply contrast adjustment around midpoint (128)
        int r = (((pixel.r - 128) * factor) + 128).clamp(0, 255).toInt();
        int g = (((pixel.g - 128) * factor) + 128).clamp(0, 255).toInt();
        int b = (((pixel.b - 128) * factor) + 128).clamp(0, 255).toInt();
        
        // ✅ Fixed: setPixel with proper ColorRgba8
        result.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
      }
    }
    
    return result;
  }
}