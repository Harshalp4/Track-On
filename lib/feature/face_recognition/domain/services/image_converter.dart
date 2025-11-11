import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageConverter {
  static img.Image convertBGRA8888ToImage(CameraImage cameraImage) {
    final plane = cameraImage.planes[0];
    const bytesOffset = 28; // iOS bytes offset

    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: plane.bytes.buffer,
      rowStride: plane.bytesPerRow,
      bytesOffset: bytesOffset,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image convertNV21ToImage(CameraImage image) {
    final width = image.width.toInt();
    final height = image.height.toInt();
    final outImg = img.Image(height: height, width: width);
    final Uint8List yuv420sp = image.planes[0].bytes;
    final int frameSize = width * height;

    for (int j = 0, yp = 0; j < height; j++) {
      int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & yuv420sp[yp]) - 16;
        if (y < 0) y = 0;

        if ((i & 1) == 0) {
          v = (0xff & yuv420sp[uvp++]) - 128;
          u = (0xff & yuv420sp[uvp++]) - 128;
        }

        int y1192 = 1192 * y;
        int r = (y1192 + 1634 * v);
        int g = (y1192 - 833 * v - 400 * u);
        int b = (y1192 + 2066 * u);

        // Clamp values
        r = r.clamp(0, 262143);
        g = g.clamp(0, 262143);
        b = b.clamp(0, 262143);

        outImg.setPixelRgb(i, j, ((r << 6) & 0xff0000) >> 16,
            ((g >> 2) & 0xff00) >> 8, (b >> 10) & 0xff);
      }
    }
    return outImg;
  }

  // Fixed method with proper rotation handling
  static img.Image convertCameraImageToImage(CameraImage image, bool isIOS, {bool needsRotation = false}) {
    var convertedImage = isIOS ? convertBGRA8888ToImage(image) : convertNV21ToImage(image);
    
    // Apply rotation if needed (for landscape orientation)
    if (needsRotation) {
      convertedImage = img.copyRotate(convertedImage, angle: 90);
    }
    
    return convertedImage;
  }
}