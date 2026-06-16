import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'config/constants.dart';
import 'config/settings.dart';
import 'screens/menu_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/todo_edit_screen.dart';
import 'screens/vibe_task_screen.dart';

const _menuCornerRadius = 24.0;
const _settingsCornerRadius = 24.0;
const _windowShapeChannel = MethodChannel('pawssistant_window_shape');

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final windowController = await WindowController.fromCurrentEngine();
  final windowArguments = _parseWindowArguments(windowController.arguments);
  if (windowArguments['type'] == 'menu') {
    await Window.initialize();
    await _configureMenuWindow(windowController, windowArguments);
    runApp(const MenuScreen());
    return;
  }
  if (windowArguments['type'] == 'settings') {
    await Window.initialize();
    await _configureSettingsWindow(windowController, windowArguments);
    runApp(const SettingsScreen());
    return;
  }
  if (windowArguments['type'] == 'vibe_task') {
    await _configureVibeTaskWindow(windowController, windowArguments);
    runApp(const VibeTaskScreen());
    return;
  }
  if (windowArguments['type'] == 'todo_edit') {
    await Window.initialize();
    await _configureTodoEditWindow(windowController, windowArguments);
    runApp(const TodoEditScreen());
    return;
  }

  await _configurePetWindow();
  await _ensureSettingsFile();
  await _initSystemTray();
  runApp(const PawssistantApp());
}

Future<void> _initSystemTray() async {
  final tmpDir = await getTemporaryDirectory();
  final icoFile = File('${tmpDir.path}/pawssistant_tray.ico');
  final data = await rootBundle.load('assets/logo_out.ico');
  await icoFile.writeAsBytes(data.buffer.asUint8List());

  final systemTray = SystemTray();
  await systemTray.initSystemTray(
    iconPath: icoFile.path,
    toolTip: 'Pawssistant',
  );

  final menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(
      label: '退出',
      onClicked: (menuItem) => windowManager.destroy(),
    ),
  ]);
  await systemTray.setContextMenu(menu);
}

Future<void> _ensureSettingsFile() async {
  final settings = await SettingsService.load();
  await SettingsService.save(settings);
}

Map<String, dynamic> _parseWindowArguments(String arguments) {
  if (arguments.isEmpty) {
    return const {};
  }

  final decoded = jsonDecode(arguments);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  return const {};
}

Future<void> _configurePetWindow() async {
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: const Size(PetConfig.windowWidth, PetConfig.windowHeight),
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      alwaysOnTop: true,
    ),
    () async {
      const size = Size(PetConfig.windowWidth, PetConfig.windowHeight);

      // Windows runner 已用 WS_POPUP 创建原生无边框窗口，这里只同步插件状态。
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);

      // 锁死窗口尺寸为精确正方形。
      await windowManager.setMinimumSize(size);
      await windowManager.setMaximumSize(size);
      await windowManager.setSize(size);

      // 初始位置：贴右侧，垂直居中
      final display = await screenRetriever.getPrimaryDisplay();
      final screenSize = display.visibleSize ?? display.size;
      final x = screenSize.width - PetConfig.windowWidth;
      final y = (screenSize.height - PetConfig.windowHeight) / 2;
      await windowManager.setPosition(Offset(x, y));

      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setPreventClose(true);
      await windowManager.setTitle('Pawssistant');
    },
  );
}

Future<void> _configureMenuWindow(
  WindowController windowController,
  Map<String, dynamic> arguments,
) async {
  final bounds = _boundsFromArguments(arguments);
  await windowController.setWindowMethodHandler((call) async {
    switch (call.method) {
      case 'place':
        final args = call.arguments as Map;
        await _placeMenuWindow(_boundsFromArguments(args));
        return;
      case 'refresh_balance':
        MenuScreen.triggerRefresh();
        return;
      case 'refresh_todos':
        MenuScreen.triggerTodoRefresh();
        return;
      default:
        throw UnimplementedError('Not implemented: ${call.method}');
    }
  });

  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: bounds.size,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: true,
    ),
    () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setMinimumSize(bounds.size);
      await windowManager.setMaximumSize(bounds.size);
      await windowManager.setBounds(bounds);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setTitle('Pawssistant Menu');
      await windowManager.show(inactive: true);
      await _applyMenuWindowEffects();
    },
  );
}

Future<void> _configureSettingsWindow(
  WindowController windowController,
  Map<String, dynamic> arguments,
) async {
  final bounds = _boundsFromArguments(arguments);
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: bounds.size,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: true,
    ),
    () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setMinimumSize(bounds.size);
      await windowManager.setMaximumSize(bounds.size);
      await windowManager.setBounds(bounds);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setTitle('Pawssistant Settings');
      await windowManager.show();
      await _applySettingsWindowEffects();
    },
  );
}

Future<void> _configureVibeTaskWindow(
  WindowController windowController,
  Map<String, dynamic> arguments,
) async {
  final bounds = _boundsFromArguments(arguments);
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: bounds.size,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: true,
    ),
    () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setMinimumSize(bounds.size);
      await windowManager.setMaximumSize(bounds.size);
      await windowManager.setBounds(bounds);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setTitle('Pawssistant Vibe Task');
      await windowManager.show();
    },
  );
}

Future<void> _configureTodoEditWindow(
  WindowController windowController,
  Map<String, dynamic> arguments,
) async {
  final bounds = _boundsFromArguments(arguments);
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: bounds.size,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: false,
    ),
    () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setMinimumSize(bounds.size);
      await windowManager.setMaximumSize(bounds.size);
      await windowManager.setBounds(bounds);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setTitle('Pawssistant Todo Edit');
      await windowManager.show();
      await _applySettingsWindowEffects();
    },
  );
}

Future<void> _applySettingsWindowEffects() async {
  await _applyAcrylic();
  if (Platform.isWindows) {
    await _windowShapeChannel.invokeMethod('setRoundedRegion', {
      'radius': _settingsCornerRadius,
    });
  }
}

Future<void> _applyAcrylic() async {
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: const Color(0x38BFBFBF),
  );
}

Future<void> _applyMenuWindowEffects() async {
  await _applyAcrylic();
  if (Platform.isWindows) {
    await _windowShapeChannel.invokeMethod('setRoundedRegion', {
      'radius': _menuCornerRadius,
    });
  }
}

Future<void> _placeMenuWindow(Rect bounds) async {
  await windowManager.setMinimumSize(bounds.size);
  await windowManager.setMaximumSize(bounds.size);
  await windowManager.setBounds(bounds);
  await windowManager.show(inactive: true);
  await windowManager.setAlwaysOnTop(true);
  // Re-apply acrylic after repositioning — windowManager.show() may reset it.
  await _applyMenuWindowEffects();
}

Rect _boundsFromArguments(Map arguments) {
  final left = _asDouble(arguments['left']);
  final top = _asDouble(arguments['top']);
  final width = _asDouble(arguments['width']);
  final height = _asDouble(arguments['height']);
  return Rect.fromLTWH(left, top, width, height);
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return 0.0;
}
