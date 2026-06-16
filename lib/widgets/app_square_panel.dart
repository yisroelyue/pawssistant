import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/settings.dart';
import '../screens/menu_screen.dart';

class AppItem {
  const AppItem({required this.icon, required this.name});
  final IconData icon;
  final String name;
}

const placeholderApps = [
  AppItem(icon: Icons.calculate, name: '计算器'),
  AppItem(icon: Icons.calendar_today, name: '日历'),
  AppItem(icon: Icons.cloud, name: '天气'),
  AppItem(icon: Icons.music_note, name: '音乐'),
  AppItem(icon: Icons.translate, name: '翻译'),
  AppItem(icon: Icons.note, name: '笔记'),
  AppItem(icon: Icons.access_time, name: '时钟'),
  AppItem(icon: Icons.favorite_border, name: '健康'),
];

class AppSquarePanel extends StatefulWidget {
  const AppSquarePanel({super.key});

  @override
  State<AppSquarePanel> createState() => _AppSquarePanelState();
}

class _AppSquarePanelState extends State<AppSquarePanel> {
  bool _panelEnabled = true;
  bool _loading = true;

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
    final settings = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      _panelEnabled = settings.showAppSquarePanel;
      _loading = false;
    });
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
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/svg/应用.svg',
          width: 22,
          height: 22,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '应用广场',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: placeholderApps.length,
      itemBuilder: (_, index) => _buildAppTile(placeholderApps[index]),
    );
  }

  Widget _buildAppTile(AppItem app) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Placeholder — no action yet
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                app.icon,
                color: Colors.white70,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              app.name,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
