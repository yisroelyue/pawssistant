# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 命令

```bash
flutter pub get
flutter run -d windows          # 主要开发平台
flutter build windows --release
flutter analyze
```

## 架构：多窗口桌面助手

Flutter 桌面应用，宠物图标 50×50px，可拖拽、自动吸附屏幕边缘。每个"页面"都是**独立的原生窗口**（`desktop_multi_window`），通过 `WindowMethodChannel` 通信，不是单窗口路由。

### 窗口关系

`main.dart` 根据 `arguments['type']` 分发窗口。无 `type` 的为首个宠物窗口，其余由 `PetScreen` 通过 `WindowController.create()` 创建。

```
PetScreen（主窗口，50×50，置顶，无边框，吸附边缘）
  ├── MenuScreen（400×880，悬停显示/移出隐藏）
  ├── SettingsScreen（800×550，居中模态）
  ├── TodoEditScreen（800×620，居中模态）
  ├── FavoritesEditScreen（750×600，居中模态）
  ├── AppCenterScreen（720×580，居中模态）
  └── VibeTaskScreen（200×36，顶部状态条，置顶）
```

### 窗口通信

**子→父（单向 `WindowMethodChannel`）**：子窗口发事件给 `PetScreen`（通信枢纽），PetScreen 再通过 `WindowController.invokeMethod()` 调用子窗口方法刷新界面。

**面板刷新**：`MenuScreen` 提供静态 `ValueNotifier<int>`，面板监听变化后自行重新拉取数据。

### Windows 原生层（`windows/runner/flutter_window.cpp`）

- `pawssistant_window_shape`：`setRoundedRegion` 通过 `CreateRoundRectRgn` 给无边框窗口加圆角
- `pawssistant_file_drop`：将拖拽到宠物窗口的文件路径发给 Flutter 层，存入收藏
- `DesktopMultiWindowSetWindowCreatedCallback` 中剥离子窗口的 `WS_CAPTION | WS_THICKFRAME` 等样式，保持无边框以适配毛玻璃效果

## 持久化数据

| 数据 | 路径 |
|------|------|
| 设置 | `~/Documents/pawssistant_settings.json` |
| 待办 | `~/.pawssistant/pawssistant_todos.json` |
| 收藏索引 | `~/.pawssistant/pawssistant_favorites.json` |
| 收藏文件 | `~/.pawssistant/favorites/<id>_<文件名>` |
| Claude 任务状态 | `~/.pawssistant/vibe_task_<sessionId>.json` |
| 自定义应用 | `~/.pawssistant/custom_apps.json` |

## 关键服务

- **`SettingsService`**：读取/保存 `AppSettings`，控制面板显隐、API 平台/密钥、刷新间隔等。面板在初始化时检查 `showXxxPanel`，为 false 时返回 `SizedBox.shrink()`
- **`BalanceService`**：Bearer 认证请求余额接口，解析 DeepSeek 格式响应
- **`TodoService`** / **`FavoritesService`**：静态方法 CRUD，数据存 JSON 文件
- **`VibeTaskService`**（单例）：监视 `~/.pawssistant/` 目录中 `vibe_task_*.json` 文件（150ms 防抖），已完成任务 30 秒后移除，超过 10 分钟未更新的视为过期
- **`ClaudeHookInstaller`**：将 PowerShell 钩子脚本（`assets/scripts/vibe_task_update.ps1`）安装到 `~/.claude/settings.json`，监听 Claude Code 的 SessionStart、UserPromptSubmit、PreToolUse、PostToolUse、Notification、Stop、SubagentStop 事件

## 应用中心

`AppSquarePanel` 展示最多 8 个可启动应用。`AppConfig`（在 `app_square_panel.dart`）从可执行文件目录向上查找包含 `sub_app/` 的项目根目录来解析相对路径。

应用来源：
- 系统应用：`lib/config/apps_config.json`（内置于应用）
- 自定义应用：`~/.pawssistant/custom_apps.json`（通过 AppCenterScreen 添加）
