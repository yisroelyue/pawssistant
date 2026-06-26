import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  Future<void> _openUrl(String url) async {
    try {
      await Process.start('cmd', ['/c', 'start', url], mode: ProcessStartMode.detached);
    } catch (_) {}
  }

  static const _features = [
    '🖥️  悬浮球',
    '💰  AI流量管理',
    '🤖  Vibe Coding任务状态监视',
    '🌐  翻译',
    '📋  待办事项',
    '📁  文件收藏',
    '🧩  应用中心',
    '✨  更多功能，敬请期待！',
  ];

  static const _githubUrl = 'https://github.com/yisroelyue/pawssistant';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => windowManager.startDragging(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () => windowManager.hide(),
                      child: const Icon(Icons.close, color: Colors.grey, size: 18),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 悬浮球图标
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/png/logo_out.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pawssistant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '悬浮球 · 多功能助手伴侣',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    // Features
                    ..._features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            f,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // GitHub link
                    RichText(
                      text: TextSpan(
                        text: '🔗 ',
                        style: const TextStyle(color: Colors.black87, fontSize: 11),
                        children: [
                          TextSpan(
                            text: _githubUrl,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 11,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _openUrl(_githubUrl),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
