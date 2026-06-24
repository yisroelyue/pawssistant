import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/settings.dart';
import '../screens/menu_screen.dart';
import '../services/translate_service.dart';
import 'interactive_icon.dart';

class TranslatePanel extends StatefulWidget {
  const TranslatePanel({super.key});

  @override
  State<TranslatePanel> createState() => _TranslatePanelState();
}

class _TranslatePanelState extends State<TranslatePanel> {
  bool _panelEnabled = true;
  bool _loading = true;
  bool _isTranslating = false;
  bool _isError = false;
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  bool _inputFocused = false;
  bool _headerHovered = false;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _fetch();
    MenuScreen.refreshNotifier.addListener(_onRefresh);
    _inputFocus.addListener(_onInputFocusChanged);
  }

  @override
  void dispose() {
    MenuScreen.refreshNotifier.removeListener(_onRefresh);
    _inputFocus.removeListener(_onInputFocusChanged);
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _fetch();
  }

  void _onInputFocusChanged() {
    final focused = _inputFocus.hasFocus;
    if (focused && !_inputFocused) {
      _inputFocused = true;
      MenuScreen.menuChannel.invokeMethod('lock_menu');
    } else if (!focused && _inputFocused) {
      _inputFocused = false;
      MenuScreen.menuChannel.invokeMethod('unlock_menu');
    }
  }

  Future<void> _performTranslation() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _resultText = '请输入要翻译的文本';
        _isError = true;
      });
      return;
    }
    setState(() => _isTranslating = true);
    try {
      final result = await TranslateService.translate(text);
      if (!mounted) return;
      setState(() {
        _resultText = result;
        _isError = false;
        _inputController.clear();
      });
    } on TranslateException catch (e) {
      if (!mounted) return;
      setState(() {
        _resultText = e.message;
        _isError = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultText = '翻译失败: $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final settings = await SettingsService.load();
    _panelEnabled = settings.showTranslatePanel;
    if (!mounted) return;
    setState(() => _loading = false);
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
            const SizedBox(height: 10),
            _buildInputRow(),
            _buildAnswerArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _headerHovered = true),
      onExit: (_) => setState(() => _headerHovered = false),
      child: GestureDetector(
        onTap: () {
          // TODO: open full translate window
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _headerHovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.translate_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '翻译',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _headerHovered ? 1.0 : 0.0,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 2, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              cursorColor: Colors.white70,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!_isTranslating) _performTranslation();
              },
              decoration: InputDecoration(
                hintText: '粘贴要翻译的文本...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          InteractiveIcon(
            size: 32,
            onTap: () {
              if (_isTranslating) return;
              _performTranslation();
            },
            child: _isTranslating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/svg/翻译.svg',
                    width: 22,
                    height: 22,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea() {
    if (_resultText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isError ? '错误' : '翻译结果',
                style: TextStyle(
                  color: _isError ? Colors.redAccent : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InteractiveIcon(
                size: 24,
                onTap: () => setState(() => _resultText = ''),
                child: const Icon(Icons.close, color: Colors.white38, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            _resultText,
            style: TextStyle(
              color: _isError ? Colors.redAccent : Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
