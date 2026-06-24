import 'package:flutter_test/flutter_test.dart';
import 'package:pawssistant_plugin_image_processer/pawssistant_plugin_image_processer.dart';

void main() {
  test('ProcessResult creation', () {
    final result = ProcessResult(outputPath: '/test/path.png', width: 100, height: 200);
    expect(result.outputPath, '/test/path.png');
    expect(result.width, 100);
    expect(result.height, 200);
  });

  test('CropRect creation', () {
    final rect = CropRect(x: 10, y: 20, width: 100, height: 200);
    expect(rect.x, 10);
    expect(rect.y, 20);
    expect(rect.width, 100);
    expect(rect.height, 200);
  });

  test('parseHexColor', () {
    final color = ImageProcessor.parseHexColor('#FF0000');
    expect(color.r, 255);
    expect(color.g, 0);
    expect(color.b, 0);
  });
}
