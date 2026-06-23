import 'package:image_handler_app/image_handler_app.dart';

/// 统一引导：导入所有子应用 package 并调用其注册函数。
/// 新增子应用时在此添加 import 和 register 调用。
void bootstrapSubApps() {
  registerImageHandlerApp();
}
