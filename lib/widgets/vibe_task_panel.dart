import 'package:flutter/material.dart';

import '../services/vibe_task_service.dart';

class VibeTaskPanel extends StatefulWidget {
  const VibeTaskPanel({super.key});

  @override
  State<VibeTaskPanel> createState() => _VibeTaskPanelState();
}

class _VibeTaskPanelState extends State<VibeTaskPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    VibeTaskService.instance.notifier.addListener(_onTasksChanged);
    VibeTaskService.instance.start();
  }

  @override
  void dispose() {
    VibeTaskService.instance.notifier.removeListener(_onTasksChanged);
    VibeTaskService.instance.stop();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTasksChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = VibeTaskService.instance.tasks;
    final activeCount = tasks
        .where((t) =>
            t.status == VibeTaskStatus.working ||
            t.status == VibeTaskStatus.needsApproval ||
            t.status == VibeTaskStatus.needsInput)
        .length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white.withValues(alpha: 0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(activeCount),
            const SizedBox(height: 12),
            if (tasks.isEmpty) _buildEmptyState() else _buildTaskList(tasks),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Row(
      children: [
        const Icon(Icons.sensors, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Vibe Coding 任务监控',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (activeCount > 0) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF64FFDA),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$activeCount 活跃',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: Colors.white38, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '等待 Claude Code hook 事件...',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(VibeTaskList tasks) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _buildTaskCard(tasks[index]),
    );
  }

  Widget _buildTaskCard(VibeTask task) {
    final (color, label) = _statusAppearance(task.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatusDot(task.status, color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.projectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ],
                ),
                if (task.actionLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.actionLabel,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(VibeTaskStatus status, Color color) {
    if (status == VibeTaskStatus.working ||
        status == VibeTaskStatus.needsApproval) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) {
          return Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color.withValues(alpha: _pulseAnimation.value),
              shape: BoxShape.circle,
            ),
          );
        },
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  (Color, String) _statusAppearance(VibeTaskStatus status) {
    switch (status) {
      case VibeTaskStatus.working:
        return (const Color(0xFF64FFDA), status.label);
      case VibeTaskStatus.needsApproval:
        return (Colors.redAccent, status.label);
      case VibeTaskStatus.needsInput:
        return (Colors.amber, status.label);
      case VibeTaskStatus.idle:
        return (Colors.white38, status.label);
      case VibeTaskStatus.completed:
        return (Colors.greenAccent, status.label);
      case VibeTaskStatus.failed:
        return (Colors.redAccent, status.label);
      case VibeTaskStatus.stopped:
        return (Colors.grey, status.label);
    }
  }
}
