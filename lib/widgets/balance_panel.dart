import 'package:flutter/material.dart';

import '../config/platform.dart';
import '../config/settings.dart';
import '../screens/menu_screen.dart';
import '../services/balance_service.dart';
import 'interactive_icon.dart';

class BalancePanel extends StatefulWidget {
  const BalancePanel({super.key});

  @override
  State<BalancePanel> createState() => BalancePanelState();
}

class BalancePanelState extends State<BalancePanel> {
  BalanceInfo? _balance;
  String _platform = 'deepseek';
  bool _panelEnabled = true;
  bool _notConfigured = false;
  bool _fetchFailed = false;
  bool _loading = true;
  bool _showVibePanel = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    MenuScreen.refreshNotifier.addListener(_onRefresh);
  }

  @override
  void dispose() {
    MenuScreen.refreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _notConfigured = false;
      _fetchFailed = false;
    });

    final settings = await SettingsService.load();
    _platform = settings.platform;
    _panelEnabled = settings.showBalancePanel;
    _showVibePanel = settings.showVibePanel;
    if (!_panelEnabled) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    if (settings.apiKey.isEmpty || settings.balanceUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _notConfigured = true;
        _loading = false;
      });
      return;
    }

    try {
      final balance = await BalanceService.fetchBalance();
      if (!mounted) return;

      if (!mounted) return;
      setState(() {
        _balance = balance;
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('━━━ 余额获取失败 ━━━');
      debugPrint('$e');
      debugPrint('$stack');
      debugPrint('━━━━━━━━━━━━━━━━━━');
      if (!mounted) return;
      if (!mounted) return;
      setState(() {
        _fetchFailed = true;
        _loading = false;
      });
    }
  }

  Future<void> _toggleVibePanel() async {
    final settings = await SettingsService.load();
    settings.showVibePanel = !settings.showVibePanel;
    await SettingsService.save(settings);
    if (!mounted) return;
    setState(() => _showVibePanel = settings.showVibePanel);
    MenuScreen.menuChannel.invokeMethod('toggle_vibe_panel');
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InteractiveIcon(
          size: 32,
          onTap: _fetch,
          child: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
        ),
        const SizedBox(width: 4),
        InteractiveIcon(
          size: 32,
          onTap: _toggleVibePanel,
          child: Icon(
            _showVibePanel ? Icons.tv : Icons.tv_off,
            color: _showVibePanel ? Colors.white54 : Colors.white30,
            size: 18,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_panelEnabled && !_loading) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white.withValues(alpha: 0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildBalance(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color statusColor;
    String statusText;
    if (_notConfigured) {
      statusColor = Colors.grey;
      statusText = '未配置';
    } else if (_fetchFailed) {
      statusColor = Colors.orangeAccent;
      statusText = '异常';
    } else if (_balance?.isAvailable == true) {
      statusColor = Colors.greenAccent;
      statusText = '可用';
    } else {
      statusColor = Colors.grey;
      statusText = '...';
    }

    return Row(
      children: [
        if (_loading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          )
        else
          Image.asset(
            PlatformConfig.assetPath(_platform),
            width: 22,
            height: 22,
          ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '账户余额',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBalance() {
    if (_loading) {
      return const Text(
        '加载中...',
        style: TextStyle(color: Colors.white38, fontSize: 16),
      );
    }
    if (_notConfigured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '请配置 API Key 和余额接口',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _fetch,
            child: const Text(
              '点击重试',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      );
    }
    if (_fetchFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '获取失败',
            style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _fetch,
            child: const Text(
              '点击重试',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      );
    }
    final b = _balance!;
    final symbol = b.currency == 'USD' ? '\$' : '¥';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$symbol ${b.totalBalance.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

}
