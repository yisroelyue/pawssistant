import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../config/constants.dart';
import '../config/settings.dart';
import '../screens/todo_edit_screen.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

enum _SnapEdge { top, bottom, left, right }

class _PetScreenState extends State<PetScreen> {
  static const _menuGap = 8.0;
  static const _menuWidth = 400.0;
  static const _menuHeight = 820.0;
  static const _settingsWidth = 800.0;
  static const _settingsHeight = 550.0;
  static const _vibeWidth = 200.0;
  static const _vibeHeight = 36.0;
  static const _todoEditWidth = 800.0;
  static const _todoEditHeight = 620.0;
  static const _menuChannel = WindowMethodChannel(
    'pawssistant_menu_events',
    mode: ChannelMode.unidirectional,
  );
  static const _settingsChannel = WindowMethodChannel(
    'pawssistant_settings_events',
    mode: ChannelMode.unidirectional,
  );

  WindowController? _menuWindow;
  WindowController? _settingsWindow;
  WindowController? _vibeWindow;
  WindowController? _todoEditWindow;
  Timer? _hideTimer;
  bool _isHoveringPet = false;
  bool _isHoveringMenu = false;
  bool _menuLocked = false;

  // 吸附状态
  _SnapEdge _snapEdge = _SnapEdge.right;

  @override
  void initState() {
    super.initState();
    _menuChannel.setMethodCallHandler(_handleMenuEvent);
    _settingsChannel.setMethodCallHandler(_handleSettingsEvent);
    TodoEditScreen.editChannel.setMethodCallHandler(_handleTodoEditEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVibeWindow();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _menuChannel.setMethodCallHandler(null);
    _settingsChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleMenuEvent(MethodCall call) async {
    switch (call.method) {
      case 'menu_enter':
        _isHoveringMenu = true;
        _hideTimer?.cancel();
        return;
      case 'menu_exit':
        _isHoveringMenu = false;
        _scheduleMenuHide();
        return;
      case 'test_action':
        // Placeholder for test button
        return;
      case 'open_settings':
        _showSettings();
        return;
      case 'exit':
        await windowManager.destroy();
        return;
      case 'lock_menu':
        _menuLocked = true;
        _hideTimer?.cancel();
        return;
      case 'unlock_menu':
        _menuLocked = false;
        _scheduleMenuHide();
        return;
      case 'open_todo_editor':
        final args = call.arguments;
        if (args is Map) {
          _showTodoEditor({
            'id': args['id'] as String? ?? '',
            'title': args['title'] as String? ?? '',
          });
        }
        return;
      case 'toggle_vibe_panel':
        _syncVibeWindow();
        return;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  Future<void> _handleSettingsEvent(MethodCall call) async {
    switch (call.method) {
      case 'settings_saved':
        // 设置保存后刷新菜单面板
        if (_menuWindow != null) {
          try {
            await _menuWindow!.invokeMethod('refresh_balance');
          } catch (_) {}
        }
        await _syncVibeWindow();
        return;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  Future<void> _showMenu() async {
    _isHoveringPet = true;
    _menuLocked = false;
    _hideTimer?.cancel();

    final menuBounds = await _calculateMenuBounds();

    // 尝试复用已有 menu 窗口；channel 失效则重建
    if (_menuWindow != null) {
      try {
        await _menuWindow!.invokeMethod('place', {
          'left': menuBounds.left,
          'top': menuBounds.top,
          'width': menuBounds.width,
          'height': menuBounds.height,
        });
        await _menuWindow!.show();
      } catch (_) {
        _menuWindow = null;
      }
    }

    if (_menuWindow == null) {
      final createdWindow = await WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: jsonEncode({
            'type': 'menu',
            'left': menuBounds.left,
            'top': menuBounds.top,
            'width': menuBounds.width,
            'height': menuBounds.height,
          }),
        ),
      );
      _menuWindow = createdWindow;
      if (!_isHoveringPet && !_isHoveringMenu) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await createdWindow.hide();
      }
    }

  }

  Future<void> _showSettings() async {
    // 每次都重建，保证最新尺寸
    try {
      await _settingsWindow?.hide();
    } catch (_) {}
    _settingsWindow = null;

    // 计算居中位置
    final display = await screenRetriever.getPrimaryDisplay();
    final screenSize = display.visibleSize ?? display.size;
    final left = (screenSize.width - _settingsWidth) / 2;
    final top = (screenSize.height - _settingsHeight) / 2;

    final createdWindow = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode({
          'type': 'settings',
          'left': left,
          'top': top,
          'width': _settingsWidth,
          'height': _settingsHeight,
        }),
      ),
    );
    _settingsWindow = createdWindow;
  }

  Future<void> _initVibeWindow() async {
    final settings = await SettingsService.load();
    if (settings.showVibePanel) {
      await _showVibeWindow();
    }
  }

  Future<void> _syncVibeWindow() async {
    final settings = await SettingsService.load();
    if (settings.showVibePanel) {
      await _showVibeWindow();
    } else {
      await _hideVibeWindow();
    }
  }

  Future<void> _showVibeWindow() async {
    if (_vibeWindow != null) {
      try {
        await _vibeWindow!.show();
      } catch (_) {
        _vibeWindow = null;
      }
    }
    if (_vibeWindow != null) return;

    final display = await screenRetriever.getPrimaryDisplay();
    final screenSize = display.visibleSize ?? display.size;
    final left = (screenSize.width - _vibeWidth) / 2;
    const top = 0.0;

    final createdWindow = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode({
          'type': 'vibe_task',
          'left': left,
          'top': top,
          'width': _vibeWidth,
          'height': _vibeHeight,
        }),
      ),
    );
    _vibeWindow = createdWindow;
  }

  Future<void> _hideVibeWindow() async {
    try {
      await _vibeWindow?.hide();
    } catch (_) {}
    _vibeWindow = null;
  }

  Future<void> _handleTodoEditEvent(MethodCall call) async {
    switch (call.method) {
      case 'todo_saved':
        if (_menuWindow != null) {
          try {
            await _menuWindow!.invokeMethod('refresh_todos');
          } catch (_) {}
        }
        return;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  Future<void> _showTodoEditor(Map<String, dynamic> item) async {
    try {
      await _todoEditWindow?.hide();
    } catch (_) {}
    _todoEditWindow = null;

    final display = await screenRetriever.getPrimaryDisplay();
    final screenSize = display.visibleSize ?? display.size;
    final left = (screenSize.width - _todoEditWidth) / 2;
    final top = (screenSize.height - _todoEditHeight) / 2;

    final createdWindow = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode({
          'type': 'todo_edit',
          'focusId': item['id'],
          'left': left,
          'top': top,
          'width': _todoEditWidth,
          'height': _todoEditHeight,
        }),
      ),
    );
    _todoEditWindow = createdWindow;
  }

  void _scheduleMenuHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_isHoveringPet || _isHoveringMenu || _menuLocked) {
        return;
      }
      await _menuWindow?.hide();
    });
  }

  void _hideMenuNow() {
    _hideTimer?.cancel();
    _isHoveringPet = false;
    _isHoveringMenu = false;
    _menuLocked = false;
    unawaited(_menuWindow?.hide() ?? Future<void>.value());
  }

  Future<void> _snapToNearestEdge() async {
    final bounds = await windowManager.getBounds();
    final screenBounds = await _getScreenBoundsFor(bounds);

    final distances = <_SnapEdge, double>{
      _SnapEdge.left: (bounds.left - screenBounds.left).abs(),
      _SnapEdge.right: (screenBounds.right - bounds.right).abs(),
      _SnapEdge.top: (bounds.top - screenBounds.top).abs(),
      _SnapEdge.bottom: (screenBounds.bottom - bounds.bottom).abs(),
    };

    final nearest =
        distances.entries.reduce((a, b) => a.value < b.value ? a : b);

    double x, y;
    switch (nearest.key) {
      case _SnapEdge.left:
        x = screenBounds.left;
        y = bounds.top;
      case _SnapEdge.right:
        x = screenBounds.right - bounds.width;
        y = bounds.top;
      case _SnapEdge.top:
        x = bounds.left;
        y = screenBounds.top;
      case _SnapEdge.bottom:
        x = bounds.left;
        y = screenBounds.bottom - bounds.height;
    }

    await windowManager.setPosition(Offset(x, y));

    if (nearest.key != _snapEdge) {
      setState(() => _snapEdge = nearest.key);
    }
  }

  Future<Rect> _calculateMenuBounds() async {
    final petBounds = await windowManager.getBounds();
    final screenBounds = await _getScreenBoundsFor(petBounds);

    double left, top;

    switch (_snapEdge) {
      case _SnapEdge.top:
        // 平边在上 → 菜单在下方
        left = petBounds.center.dx - _menuWidth / 2;
        top = petBounds.bottom + _menuGap;
        // 下方空间不够则改到上方
        if (top + _menuHeight > screenBounds.bottom) {
          top = petBounds.top - _menuGap - _menuHeight;
        }
      case _SnapEdge.bottom:
        // 平边在下 → 菜单在上方
        left = petBounds.center.dx - _menuWidth / 2;
        top = petBounds.top - _menuGap - _menuHeight;
        // 上方空间不够则改到下方
        if (top < screenBounds.top) {
          top = petBounds.bottom + _menuGap;
        }
      case _SnapEdge.left:
        // 平边在左 → 菜单在右侧
        left = petBounds.right + _menuGap;
        top = petBounds.center.dy - _menuHeight / 2;
        // 右侧空间不够则改到左侧
        if (left + _menuWidth > screenBounds.right) {
          left = petBounds.left - _menuGap - _menuWidth;
        }
      case _SnapEdge.right:
        // 平边在右 → 菜单在左侧
        left = petBounds.left - _menuGap - _menuWidth;
        top = petBounds.center.dy - _menuHeight / 2;
        // 左侧空间不够则改到右侧
        if (left < screenBounds.left) {
          left = petBounds.right + _menuGap;
        }
    }

    // 钳入屏幕边界
    left = left.clamp(screenBounds.left, screenBounds.right - _menuWidth);
    top = top.clamp(screenBounds.top, screenBounds.bottom - _menuHeight);

    return Rect.fromLTWH(left, top, _menuWidth, _menuHeight);
  }

  Future<Rect> _getScreenBoundsFor(Rect windowBounds) async {
    final displays = await screenRetriever.getAllDisplays();
    final center = windowBounds.center;

    for (final display in displays) {
      final bounds = _visibleBoundsFor(display);
      if (bounds.contains(center)) {
        return bounds;
      }
    }

    final display = displays.isNotEmpty
        ? displays.first
        : await screenRetriever.getPrimaryDisplay();
    return _visibleBoundsFor(display);
  }

  Rect _visibleBoundsFor(Display display) {
    final position = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return position & size;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _showMenu();
      },
      onExit: (_) {
        _isHoveringPet = false;
        _scheduleMenuHide();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) async {
          _hideMenuNow();
          // 系统级拖拽，流畅不卡；SendMessage 同步阻塞，完成后即为松手。
          await windowManager.startDragging();
          _snapToNearestEdge();
        },
        child: _PetBody(snapEdge: _snapEdge),
      ),
    );
  }
}

class _PetBody extends StatelessWidget {
  const _PetBody({required this.snapEdge});

  final _SnapEdge snapEdge;

  double get _rotation {
    switch (snapEdge) {
      case _SnapEdge.top:
        return 0;
      case _SnapEdge.bottom:
        return pi;
      case _SnapEdge.left:
        return -pi / 2;
      case _SnapEdge.right:
        return pi / 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // debugPrint(
        //   '窗口: ${constraints.maxWidth.toStringAsFixed(1)}×'
        //   '${constraints.maxHeight.toStringAsFixed(1)}',
        // );
        return SizedBox(
          width: PetConfig.windowWidth,
          height: PetConfig.windowHeight,
          child: Transform.rotate(
            angle: _rotation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 半胶囊 — 平边贴顶(旋转前)，底部圆角
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                    child: Container(
                      color: Colors.grey.shade800.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                // Logo
                Image.asset(
                  PetConfig.logoSprite,
                  fit: BoxFit.contain,
                  width: 25,
                  height: 25,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}