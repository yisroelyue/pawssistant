import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/settings.dart';
import '../screens/menu_screen.dart';
import '../services/todo_service.dart';
import 'interactive_icon.dart';

class TodoPanel extends StatefulWidget {
  const TodoPanel({super.key});

  @override
  State<TodoPanel> createState() => _TodoPanelState();
}

class _TodoPanelState extends State<TodoPanel> {
  List<TodoItem> _todos = [];
  bool _panelEnabled = true;
  bool _loading = true;
  final _addController = TextEditingController();
  final _addFocus = FocusNode();
  bool _inputFocused = false;
  String? _hoveredId;

  @override
  void initState() {
    super.initState();
    _fetch();
    MenuScreen.todoRefreshNotifier.addListener(_onRefresh);
    _addFocus.addListener(_onInputFocusChanged);
  }

  @override
  void dispose() {
    MenuScreen.todoRefreshNotifier.removeListener(_onRefresh);
    _addFocus.removeListener(_onInputFocusChanged);
    _addController.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _fetch();
  }

  void _onInputFocusChanged() {
    final focused = _addFocus.hasFocus;
    if (focused && !_inputFocused) {
      _inputFocused = true;
      MenuScreen.menuChannel.invokeMethod('lock_menu');
    } else if (!focused && _inputFocused) {
      _inputFocused = false;
      MenuScreen.menuChannel.invokeMethod('unlock_menu');
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final settings = await SettingsService.load();
    _panelEnabled = settings.showTodoPanel;
    if (!_panelEnabled) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    final todos = await TodoService.loadAll();
    if (!mounted) return;
    setState(() {
      _todos = todos.where((t) => !t.completed).toList();
      _loading = false;
    });
  }

  Future<void> _addTodo() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    _addController.clear();
    await TodoService.add(text);
    await _fetch();
  }

  Future<void> _toggleTodo(String id) async {
    await TodoService.toggle(id);
    await _fetch();
  }

  void _openEditWindow(TodoItem item) {
    MenuScreen.menuChannel.invokeMethod('open_todo_editor', {
      'id': item.id,
      'title': item.title,
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
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                ),
              )
            else
              _buildTodoList(),
            const SizedBox(height: 8),
            _buildAddRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = _todos.length;
    return Row(
      children: [
        SvgPicture.asset(
          'assets/svg/笔记.svg',
          width: 22,
          height: 22,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '我的笔记',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (total > 0)
          Text(
            '$total',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildTodoList() {
    if (_todos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            '暂无笔记，添加一个吧',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }
    return SizedBox(
      height: 150,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _todos.length,
        itemBuilder: (_, index) => _buildTodoItem(_todos[index]),
      ),
    );
  }

  Widget _buildTodoItem(TodoItem item) {
    final isHovered = _hoveredId == item.id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredId = item.id),
      onExit: (_) => setState(() => _hoveredId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: isHovered
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTodo(item.id),
              child: const Icon(
                Icons.check_box_outline_blank,
                size: 18,
                color: Colors.white38,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _openEditWindow(item),
                child: Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRow() {
    return Row(
      children: [
        const Icon(Icons.add, color: Colors.white38, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _addController,
            focusNode: _addFocus,
            cursorColor: Colors.white70,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: '添加新笔记...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _addTodo(),
          ),
        ),
        InteractiveIcon(
          size: 26,
          onTap: _addTodo,
          child: const Icon(Icons.send_rounded, color: Colors.white54, size: 14),
        ),
      ],
    );
  }
}
