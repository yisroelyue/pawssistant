import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../config/platform.dart';
import '../config/settings.dart';
import '../services/claude_hook_installer.dart';
import '../widgets/frosted_panel.dart';
import '../widgets/interactive_icon.dart';

enum _SettingCategory { api, display, general }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const settingsChannel = WindowMethodChannel(
    'pawssistant_settings_events',
    mode: ChannelMode.unidirectional,
  );

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _detailScrollController = ScrollController();
  _SettingCategory _selected = _SettingCategory.display;

  late final TextEditingController _apiKeyController;
  late final TextEditingController _balanceUrlController;
  String _platform = 'deepseek';
  bool _obscureApiKey = true;
  String _currencySymbol = '¥';
  int _refreshInterval = 30;
  bool _autoStart = false;
  String _language = 'zh';
  bool _showBalancePanel = true;
  bool _showTodoPanel = true;
  bool _showFavoritesPanel = true;
  bool _showAppSquarePanel = true;
  bool _showVibePanel = true;
  bool _claudeHookInstalled = false;
  bool _installingClaudeHooks = false;
  bool _loading = true;

  static const _currencies = ['¥', '\$', '€', '£'];
  static const _intervals = [15, 30, 60, 120, 300];
  static const _languages = {'zh': '中文', 'en': 'English'};

  static const _categoryItems = <(_SettingCategory, IconData, String)>[
    (_SettingCategory.display, Icons.palette_outlined, '显示设置'),
    (_SettingCategory.api, Icons.api_rounded, 'API 配置'),
    (_SettingCategory.general, Icons.tune_rounded, '通用设置'),
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _balanceUrlController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await SettingsService.load();
    final claudeHookInstalled = await ClaudeHookInstaller.isGlobalHookInstalled();
    if (!mounted) return;
    setState(() {
      _platform = s.platform;
      _apiKeyController.text = s.apiKey;
      _balanceUrlController.text = s.balanceUrl;
      _currencySymbol = s.currencySymbol;
      _refreshInterval = s.refreshInterval;
      _autoStart = s.autoStart;
      _language = s.language;
      _showBalancePanel = s.showBalancePanel;
      _showTodoPanel = s.showTodoPanel;
      _showFavoritesPanel = s.showFavoritesPanel;
      _showAppSquarePanel = s.showAppSquarePanel;
      _showVibePanel = s.showVibePanel;
      _claudeHookInstalled = claudeHookInstalled;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _balanceUrlController.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: MaterialApp(
        scaffoldMessengerKey: _messengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: FrostedPanel(
            color: Colors.white12.withValues(alpha: 0.0),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                  )
                : Column(
                    children: [
                      _buildTitleBar(),
                      const SizedBox(height: 4),
                      Expanded(child: _buildBody()),
                      _buildBottomBar(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(
        children: [
          const Icon(Icons.settings, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '系统设置',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InteractiveIcon(
            onTap: () => windowManager.hide(),
            child: const Icon(Icons.close, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Row(
      children: [
        _buildSidebar(),
        _buildDivider(),
        Expanded(child: _buildDetailPanel()),
      ],
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 120,
      child: ListView(
        primary: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _categoryItems.map((item) {
          final (cat, icon, label) = item;
          final isActive = _selected == cat;
          return _SidebarItem(
            icon: icon,
            label: label,
            active: isActive,
            onTap: () => setState(() => _selected = cat),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildDetailPanel() {
    return Scrollbar(
      controller: _detailScrollController,
      child: ListView(
        controller: _detailScrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        children: switch (_selected) {
          _SettingCategory.api     => _buildApiSettings(),
          _SettingCategory.display => _buildDisplaySettings(),
          _SettingCategory.general => _buildGeneralSettings(),
        },
      ),
    );
  }

  List<Widget> _buildApiSettings() {
    return [
      _buildPlatformDropdown(),
      const SizedBox(height: 14),
      _buildApiKeyField(),
      const SizedBox(height: 14),
      _buildBalanceUrlField(),
    ];
  }

  List<Widget> _buildDisplaySettings() {
    return [
      _buildSectionTitle('首页面板'),
      const SizedBox(height: 8),
      _buildPanelToggle('AI流量管理', _showBalancePanel, (v) => setState(() => _showBalancePanel = v)),
      const SizedBox(height: 8),
      _buildPanelToggle('Vibe任务监控', _showVibePanel, (v) => setState(() => _showVibePanel = v), compact: true),
      const SizedBox(height: 12),
      _buildPanelToggle('我的笔记', _showTodoPanel, (v) => setState(() => _showTodoPanel = v)),
      const SizedBox(height: 8),
      _buildPanelToggle('我的收藏', _showFavoritesPanel, (v) => setState(() => _showFavoritesPanel = v)),
      const SizedBox(height: 8),
      _buildPanelToggle('应用中心', _showAppSquarePanel, (v) => setState(() => _showAppSquarePanel = v)),
      const SizedBox(height: 20),
      _buildCurrencyDropdown(),
      const SizedBox(height: 14),
      _buildRefreshIntervalDropdown(),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildPanelToggle(String label, bool value, ValueChanged<bool> onChanged, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 12,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: compact ? 0.04 : 0.06),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: compact ? 12 : 14)),
          Transform.scale(
            scale: compact ? 0.78 : 1.0,
            child: Switch(
              value: value,
              activeColor: Colors.greenAccent,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGeneralSettings() {
    return [
      _buildLanguageDropdown(),
      const SizedBox(height: 14),
      _buildAutoStartToggle(),
      const SizedBox(height: 20),
      _buildSectionTitle('CLAUDE CODE 监控'),
      const SizedBox(height: 8),
      _buildClaudeHookInstaller(),
    ];
  }

  Widget _buildApiKeyField() {
    return _FieldWrapper(
      label: 'API Key',
      child: TextField(
        controller: _apiKeyController,
        obscureText: _obscureApiKey,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'sk-...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureApiKey ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: Colors.white54,
            ),
            onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformDropdown() {
    final items = PlatformConfig.platforms.keys.toList();
    return _FieldWrapper(
      label: 'AI平台',
      child: _buildDropdown<String>(
        value: _platform,
        items: items,
        itemBuilder: (k) {
          return DropdownMenuItem(
            value: k,
            child: Text(PlatformConfig.platforms[k]?.name ?? k),
          );
        },
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _platform = v;
            _balanceUrlController.text = PlatformConfig.defaultBalanceUrl(v);
          });
        },
      ),
    );
  }

  Widget _buildBalanceUrlField() {
    return _FieldWrapper(
      label: '余额接口',
      child: TextField(
        controller: _balanceUrlController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'https://api.deepseek.com/user/balance',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return _FieldWrapper(
      label: '货币符号',
      child: _buildDropdown<String>(
        value: _currencySymbol,
        items: _currencies,
        itemBuilder: (c) => DropdownMenuItem(value: c, child: Text(c)),
        onChanged: (v) => setState(() => _currencySymbol = v!),
      ),
    );
  }

  Widget _buildRefreshIntervalDropdown() {
    return _FieldWrapper(
      label: '刷新间隔（秒）',
      child: _buildDropdown<int>(
        value: _refreshInterval,
        items: _intervals,
        itemBuilder: (i) => DropdownMenuItem(value: i, child: Text('${i}s')),
        onChanged: (v) => setState(() => _refreshInterval = v!),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return _FieldWrapper(
      label: '语言',
      child: _buildDropdown<String>(
        value: _language,
        items: _languages.keys.toList(),
        itemBuilder: (k) => DropdownMenuItem(value: k, child: Text(_languages[k]!)),
        onChanged: (v) => setState(() => _language = v!),
      ),
    );
  }

  Widget _buildAutoStartToggle() {
    return _FieldWrapper(
      label: '开机自启',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Switch(
          value: _autoStart,
          activeColor: Colors.greenAccent,
          onChanged: (v) => setState(() => _autoStart = v),
        ),
      ),
    );
  }

  Widget _buildClaudeHookInstaller() {
    final statusText = _claudeHookInstalled ? '已安装全局 Hook' : '未安装';
    final statusColor =
        _claudeHookInstalled ? Colors.greenAccent : Colors.white38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            _claudeHookInstalled
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 14),
            ),
          ),
          TextButton.icon(
            onPressed: _installingClaudeHooks ? null : _installClaudeHooks,
            icon: _installingClaudeHooks
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : const Icon(Icons.download_done_rounded, size: 16),
            label: Text(_claudeHookInstalled ? '重新安装' : '安装'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.greenAccent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _installClaudeHooks() async {
    setState(() => _installingClaudeHooks = true);
    try {
      final result = await ClaudeHookInstaller.installGlobalHooks();
      if (!mounted) return;
      setState(() {
        _claudeHookInstalled = true;
        _installingClaudeHooks = false;
      });
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('全局 Hook 已安装：${result.settingsPath}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _installingClaudeHooks = false);
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('安装失败：$error'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    DropdownMenuItem<T> Function(T)? itemBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF2D2D2D),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          items: itemBuilder != null
              ? items.map(itemBuilder).toList()
              : items.map((e) {
                  return DropdownMenuItem<T>(
                    value: e,
                    child: Text(e.toString()),
                  );
                }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => windowManager.hide(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('取消', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.withValues(alpha: 0.85),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('保存', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    final settings = AppSettings(
      platform: _platform,
      apiKey: _apiKeyController.text.trim(),
      balanceUrl: _balanceUrlController.text.trim(),
      currencySymbol: _currencySymbol,
      refreshInterval: _refreshInterval,
      autoStart: _autoStart,
      language: _language,
      showBalancePanel: _showBalancePanel,
      showTodoPanel: _showTodoPanel,
      showFavoritesPanel: _showFavoritesPanel,
      showAppSquarePanel: _showAppSquarePanel,
      showVibePanel: _showVibePanel,
    );
    SettingsService.save(settings);
    SettingsScreen.settingsChannel.invokeMethod('settings_saved');
    _messengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('设置已保存'),
        duration: Duration(seconds: 1),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      windowManager.hide();
    });
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? Colors.white.withValues(alpha: 0.14)
        : _hovering
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.active ? Colors.white : Colors.white54,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.active ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: widget.active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldWrapper extends StatelessWidget {
  const _FieldWrapper({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),
        child,
      ],
    );
  }
}
