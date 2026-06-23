import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/constants.dart';
import '../config/settings.dart';
import '../widgets/app_square_panel.dart';
import '../widgets/balance_panel.dart';
import '../widgets/favorites_panel.dart';
import '../widgets/frosted_panel.dart';
import '../widgets/interactive_icon.dart';
import '../widgets/todo_panel.dart';

class MenuScreen extends StatefulWidget {
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

  /// 刷新收藏面板
  static final favoritesRefreshNotifier = ValueNotifier<int>(0);
  static void triggerFavoritesRefresh() => favoritesRefreshNotifier.value++;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _balanceHidden = false;
  bool _todoHidden = false;
  bool _favoritesHidden = false;
  bool _appsHidden = false;

  @override
  void initState() {
    super.initState();
    _loadHiddenPanels();
    MenuScreen.refreshNotifier.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    MenuScreen.refreshNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _loadHiddenPanels();
  }

  Future<void> _loadHiddenPanels() async {
    final s = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      _balanceHidden = !s.showBalancePanel;
      _todoHidden = !s.showTodoPanel;
      _favoritesHidden = !s.showFavoritesPanel;
      _appsHidden = !s.showAppSquarePanel;
    });
  }

  void _openPanelDetail(String key) {
    switch (key) {
      case 'balance':
        MenuScreen.menuChannel.invokeMethod('open_settings');
      case 'todo':
        MenuScreen.menuChannel.invokeMethod('open_todo_editor', {
          'id': '',
          'title': '',
        });
      case 'favorites':
        MenuScreen.menuChannel.invokeMethod('open_favorites_editor', {
          'folderId': '',
        });
      case 'apps':
        MenuScreen.menuChannel.invokeMethod('open_app_center');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => MenuScreen.menuChannel.invokeMethod('menu_enter'),
      onExit: (_) => MenuScreen.menuChannel.invokeMethod('menu_exit'),
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
            onTap: () => MenuScreen.menuChannel.invokeMethod('open_settings'),
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
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        if (index == 0) {
          return const BalancePanel();
        }
        if (index == 1) {
          return const TodoPanel();
        }
        if (index == 2) {
          return const FavoritesPanel();
        }
        return const AppSquarePanel();
      },
    );
  }

  Widget _buildBottomRow() {
    final hiddenIcons = <Widget>[];

    if (_balanceHidden) {
      hiddenIcons.add(_buildPanelToggleIcon('balance', Icons.account_balance_wallet_rounded));
    }
    if (_todoHidden) {
      hiddenIcons.add(_buildPanelToggleSvg('todo', 'assets/svg/笔记.svg'));
    }
    if (_favoritesHidden) {
      hiddenIcons.add(_buildPanelToggleSvg('favorites', 'assets/svg/收藏.svg'));
    }
    if (_appsHidden) {
      hiddenIcons.add(_buildPanelToggleSvg('apps', 'assets/svg/应用.svg'));
    }

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
          ...hiddenIcons,
        ],
      ),
    );
  }

  Widget _buildPanelToggleIcon(String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InteractiveIcon(
        size: 32,
        onTap: () => _openPanelDetail(key),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildPanelToggleSvg(String key, String assetPath) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InteractiveIcon(
        size: 32,
        onTap: () => _openPanelDetail(key),
        child: SvgPicture.asset(
          assetPath,
          width: 20,
          height: 20,
        ),
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
