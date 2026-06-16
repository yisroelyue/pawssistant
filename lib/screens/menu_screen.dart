import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import '../config/constants.dart';
import '../widgets/app_square_panel.dart';
import '../widgets/balance_panel.dart';
import '../widgets/frosted_panel.dart';
import '../widgets/interactive_icon.dart';
import '../widgets/todo_panel.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const menuChannel = WindowMethodChannel(
    'pawssistant_menu_events',
    mode: ChannelMode.unidirectional,
  );

  /// 外部触发余额刷新
  static final refreshNotifier = ValueNotifier<int>(0);
  static void triggerRefresh() => refreshNotifier.value++;

  /// 仅刷新笔记，不触发余额请求
  static final todoRefreshNotifier = ValueNotifier<int>(0);
  static void triggerTodoRefresh() => todoRefreshNotifier.value++;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => menuChannel.invokeMethod('menu_enter'),
      onExit: (_) => menuChannel.invokeMethod('menu_exit'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: FrostedPanel(
            color: Colors.white12.withValues(alpha: 0.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              child: Column(
                children: [
                  // 顶行
                  _buildTopRow(),
                  // 面板区域
                  Expanded(child: _buildPanelList()),
                  // 底部功能按钮
                  _buildBottomRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(PetConfig.logoSprite, width: 25, height: 25),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Pawssistant',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          InteractiveIcon(
            onTap: () => menuChannel.invokeMethod('open_settings'),
            child: SvgPicture.asset(
              'assets/svg/设置.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          ],
        ),
    );
  }

  Widget _buildPanelList() {
    return ListView.separated(
      primary: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        if (index == 0) {
          return const BalancePanel();
        }
        if (index == 1) {
          return const TodoPanel();
        }
        return const AppSquarePanel();
      },
    );
  }

  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          InteractiveIcon(
            size: 36,
            onTap: _openClaudeTerminal,
            child: const Icon(
              Icons.terminal_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const Spacer(),
          InteractiveIcon(
            size: 36,
            onTap: () async {
              await menuChannel.invokeMethod('exit');
              await windowManager.destroy();
            },
            child: SvgPicture.asset(
              'assets/svg/退出.svg',
              width: 25,
              height: 25,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openClaudeTerminal() {
    if (Platform.isWindows) {
      Process.start('cmd', ['/c', 'start', 'cmd', '/k', 'claude'],
        mode: ProcessStartMode.detached);
    } else if (Platform.isMacOS) {
      Process.start('osascript', [
        '-e', 'tell application "Terminal" to do script "claude"',
      ], mode: ProcessStartMode.detached);
    } else if (Platform.isLinux) {
      Process.start('x-terminal-emulator', ['-e', 'bash -c "claude; exec bash"'],
        mode: ProcessStartMode.detached);
    }
  }
}
