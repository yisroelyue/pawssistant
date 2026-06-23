import 'package:flutter/material.dart';
import 'package:pawssistant/core/sub_app.dart';
import 'package:pawssistant/core/sub_app_registry.dart';
import 'package:pawssistant_plugin_image_processer/pawssistant_plugin_image_processer.dart';

class ImageHandlerApp extends SubApp {
  @override
  String get id => 'image_handler';

  @override
  String get name => '图像处理器';

  @override
  String get description => '裁剪旋转、格式转换、扩图、背景填充、水印';

  @override
  String get iconAsset => 'assets/logo.svg';

  @override
  String get packageName => 'image_handler_app';

  @override
  Size get preferredWindowSize => const Size(960, 720);

  @override
  Widget buildApp(BuildContext context) {
    return MaterialApp(
      title: 'Pawssistant 图像处理器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}

void registerImageHandlerApp() {
  SubAppRegistry.register(() => ImageHandlerApp());
}
