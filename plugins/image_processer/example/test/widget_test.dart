import 'package:flutter_test/flutter_test.dart';

import 'package:pawssistant_plugin_image_processer_example/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PawssistantApp());

    expect(find.text('Pawssistant 图像处理器'), findsOneWidget);
    expect(find.text('选择图片'), findsOneWidget);
  });
}
