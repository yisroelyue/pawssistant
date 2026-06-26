import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/settings.dart';
import '../screens/menu_screen.dart';
import '../services/todo_service.dart';

class TodoPanel extends StatefulWidget {
  const TodoPanel({super.key});

  @override
  State<TodoPanel> createState() => _TodoPanelState();
}

class _TodoPanelState extends State<TodoPanel> {
  List<TodoItem> _normalTodos = [];
  List<TodoItem> _importantTodos = [];
  bool _panelEnabled = true;
  bool _loading = true;
  bool _headerHovered = false;
  bool _addHovered = false;
  String? _hoveredId;
  bool _panelHovered = false;

  @override
  void initState() {
    super.initState();
    _fetch(firstLoad: true);
    MenuScreen.todoRefreshNotifier.addListener(_onRefresh);
  }

  @override
  void dispose() {
    MenuScreen.todoRefreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    _fetch();
  }

  Future<void> _fetch({bool firstLoad = false}) async {
    if (firstLoad) {
      setState(() => _loading = true);
    }
    final settings = await SettingsService.load();
    _panelEnabled = settings.showTodoPanel;
    if (!_panelEnabled) {
      if (!mounted) return;
      if (firstLoad) setState(() => _loading = false);
      return;
    }
    final todos = await TodoService.loadAll();
    if (!mounted) return;
    setState(() {
      final uncompleted = todos.where((t) => !t.completed).toList();
      _normalTodos = uncompleted.where((t) => !t.important).toList();
      _importantTodos = uncompleted.where((t) => t.important).toList();
      _loading = false;
    });
  }

  void _openItemPopup(TodoItem item) {
    MenuScreen.menuChannel.invokeMethod('open_todo_item_popup', {
      'id': item.id,
      'title': item.title,
      'important': item.important,
    });
  }

  void _openAddPopup() {
    MenuScreen.menuChannel.invokeMethod('open_todo_item_popup', {
      'id': '',
      'title': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_panelEnabled && !_loading) {
      return const SizedBox.shrink();
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _panelHovered = true),
      onExit: (_) => setState(() => _panelHovered = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
          color: Colors.white.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 6),
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
            ],
          ),
        ),
      ),
    );
  }

  void _openAllTodos() {
    MenuScreen.menuChannel.invokeMethod('open_todo_editor', {
      'id': '',
      'title': '',
    });
  }

  Widget _buildHeader() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _headerHovered = true),
      onExit: (_) => setState(() => _headerHovered = false),
      child: GestureDetector(
        onTap: _openAllTodos,
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
              GestureDetector(
                onTap: _openAddPopup,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _addHovered = true),
                  onExit: (_) => setState(() => _addHovered = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _addHovered
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.add,
                      color: _addHovered ? Colors.white : Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList() {
    final totalCount = _normalTodos.length + _importantTodos.length;
    if (totalCount == 0) {
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
    final showAll = _panelHovered;
    final normalVisible = showAll
        ? _normalTodos.length
        : (_normalTodos.length > 3 ? 3 : _normalTodos.length);
    final importantVisible = showAll
        ? _importantTodos.length
        : (_importantTodos.length > 3 ? 3 : _importantTodos.length);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            normalVisible,
            (i) => _buildTodoItem(_normalTodos[i]),
          ),
          if (importantVisible > 0 && normalVisible > 0)
            _buildDivider(),
          ...List.generate(
            importantVisible,
            (i) => _buildTodoItem(_importantTodos[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.10),
      ),
    );
  }

  Widget _buildTodoItem(TodoItem item) {
    final isHovered = _hoveredId == item.id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredId = item.id),
      onExit: (_) => setState(() => _hoveredId = null),
      child: GestureDetector(
        onTap: () => _openItemPopup(item),
        child: Container(
          key: ValueKey(item.id),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (item.important)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: isHovered
                        ? Colors.amberAccent
                        : Colors.amberAccent.withValues(alpha: 0.7),
                  ),
                )
              else
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isHovered ? Colors.white : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
