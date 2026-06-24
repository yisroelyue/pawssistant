import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pawssistant_plugin_image_processer/pawssistant_plugin_image_processer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('addImageWatermark draws a visible scaled image', () async {
    final dir = await Directory.systemTemp.createTemp('watermark_image_test_');
    addTearDown(() => dir.delete(recursive: true));

    final basePath = '${dir.path}/base.png';
    final watermarkPath = '${dir.path}/watermark.png';
    final base = img.Image(width: 100, height: 100)
      ..clear(img.ColorUint8.rgba(255, 255, 255, 255));
    final watermark = img.Image(width: 20, height: 10)
      ..clear(img.ColorUint8.rgba(255, 0, 0, 255));
    await File(basePath).writeAsBytes(img.encodePng(base));
    await File(watermarkPath).writeAsBytes(img.encodePng(watermark));

    final result = await ImageProcessor.addImageWatermark(
      inputPath: basePath,
      outputDir: dir.path,
      watermarkPath: watermarkPath,
      scale: 0.2,
      opacity: 1,
      position: 8,
      margin: 0,
    );

    final output = img.decodeImage(
      await File(result.outputPath).readAsBytes(),
    )!;
    final redPixels = output.where((pixel) {
      return pixel.r > 200 && pixel.g < 40 && pixel.b < 40;
    }).length;

    expect(redPixels, greaterThan(100));
  });

  test('addTextWatermark draws visible latin text', () async {
    final dir = await Directory.systemTemp.createTemp('watermark_text_test_');
    addTearDown(() => dir.delete(recursive: true));

    final basePath = '${dir.path}/base.png';
    final base = img.Image(width: 160, height: 80)
      ..clear(img.ColorUint8.rgba(255, 255, 255, 255));
    await File(basePath).writeAsBytes(img.encodePng(base));

    final result = await ImageProcessor.addTextWatermark(
      inputPath: basePath,
      outputDir: dir.path,
      text: 'TEST',
      fontSize: 36,
      textColor: img.ColorUint8.rgba(255, 0, 0, 255),
      opacity: 1,
      position: 4,
      margin: 0,
    );

    final output = img.decodeImage(
      await File(result.outputPath).readAsBytes(),
    )!;
    final redPixels = output.where((pixel) {
      return pixel.r > 200 && pixel.g < 80 && pixel.b < 80;
    }).length;

    expect(redPixels, greaterThan(20));
  });

  test('addTextWatermark draws visible non-latin text', () async {
    final dir = await Directory.systemTemp.createTemp('watermark_cjk_test_');
    addTearDown(() => dir.delete(recursive: true));

    final basePath = '${dir.path}/base.png';
    final base = img.Image(width: 160, height: 80)
      ..clear(img.ColorUint8.rgba(255, 255, 255, 255));
    await File(basePath).writeAsBytes(img.encodePng(base));

    final result = await ImageProcessor.addTextWatermark(
      inputPath: basePath,
      outputDir: dir.path,
      text: '水印',
      fontSize: 36,
      textColor: img.ColorUint8.rgba(255, 0, 0, 255),
      opacity: 1,
      position: 4,
      margin: 0,
    );

    final output = img.decodeImage(
      await File(result.outputPath).readAsBytes(),
    )!;
    final redPixels = output.where((pixel) {
      return pixel.r > 200 && pixel.g < 80 && pixel.b < 80;
    }).length;

    expect(redPixels, greaterThan(20));
  });
}
