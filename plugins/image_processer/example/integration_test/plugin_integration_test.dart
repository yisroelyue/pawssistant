import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pawssistant_plugin_image_processer/pawssistant_plugin_image_processer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ImageProcessor basic test', (WidgetTester tester) async {
    // Verify the ImageProcessor class is available
    expect(ImageProcessor, isNotNull);
  });
}
