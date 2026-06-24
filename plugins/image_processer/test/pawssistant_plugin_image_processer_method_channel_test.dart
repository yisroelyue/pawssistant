import 'package:flutter_test/flutter_test.dart';
import 'package:pawssistant_plugin_image_processer/pawssistant_plugin_image_processer.dart';

void main() {
  test('ImageProcessor is available', () {
    expect(ImageProcessor, isNotNull);
  });

  test('CropRect with zero values', () {
    final rect = CropRect(x: 0, y: 0, width: 0, height: 0);
    expect(rect.x, 0);
    expect(rect.y, 0);
    expect(rect.width, 0);
    expect(rect.height, 0);
  });

  test('parseHexColor with alpha', () {
    final color = ImageProcessor.parseHexColor('#80FF0000');
    // R=255, G=0, B=0, A=128
    expect(color.r, 255);
    expect(color.g, 0);
    expect(color.b, 0);
    expect(color.a.toInt(), 128);
  });
}
