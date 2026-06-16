import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppSettings {
  AppSettings({
    this.platform = 'deepseek',
    this.apiKey = '',
    this.balanceUrl = 'https://api.deepseek.com/user/balance',
    this.currencySymbol = '¥',
    this.refreshInterval = 30,
    this.autoStart = false,
    this.language = 'zh',
    this.showBalancePanel = true,
    this.showTodoPanel = true,
    this.showAppSquarePanel = true,
    this.showVibePanel = true,
  });

  String platform;
  String apiKey;
  String balanceUrl;
  String currencySymbol;
  int refreshInterval;
  bool autoStart;
  String language;
  bool showBalancePanel;
  bool showTodoPanel;
  bool showAppSquarePanel;
  bool showVibePanel;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      platform: json['platform'] as String? ?? 'deepseek',
      apiKey: json['apiKey'] as String? ?? '',
      balanceUrl: json['balanceUrl'] as String? ?? 'https://api.deepseek.com/user/balance',
      currencySymbol: json['currencySymbol'] as String? ?? '¥',
      refreshInterval: json['refreshInterval'] as int? ?? 30,
      autoStart: json['autoStart'] as bool? ?? false,
      language: json['language'] as String? ?? 'zh',
      showBalancePanel: json['showBalancePanel'] as bool? ?? true,
      showTodoPanel: json['showTodoPanel'] as bool? ?? true,
      showAppSquarePanel: json['showAppSquarePanel'] as bool? ?? true,
      showVibePanel: json['showVibePanel'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'apiKey': apiKey,
        'balanceUrl': balanceUrl,
        'currencySymbol': currencySymbol,
        'refreshInterval': refreshInterval,
        'autoStart': autoStart,
        'language': language,
        'showBalancePanel': showBalancePanel,
        'showTodoPanel': showTodoPanel,
        'showAppSquarePanel': showAppSquarePanel,
        'showVibePanel': showVibePanel,
      };
}

class SettingsService {
  SettingsService._();

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/pawssistant_settings.json');
  }

  static Future<AppSettings> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return AppSettings();
      final json = jsonDecode(await file.readAsString());
      return AppSettings.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  static Future<void> save(AppSettings settings) async {
    final file = await _file();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
    );
  }
}
