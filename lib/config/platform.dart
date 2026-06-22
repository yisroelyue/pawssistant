class PlatformInfo {
  const PlatformInfo(this.name, this.key, this.asset);
  final String name;
  final String key;
  final String asset;
}

class PlatformConfig {
  PlatformConfig._();

  static const platforms = <String, PlatformInfo>{
    'deepseek': PlatformInfo('DeepSeek', 'deepseek', 'assets/png/plugins/deepseek.png'),
    'openai': PlatformInfo('OpenAI', 'openai', 'assets/png/plugins/openai.png'),
    'anthropic': PlatformInfo('Anthropic', 'anthropic', 'assets/png/plugins/anthropic.png'),
    'doubao': PlatformInfo('豆包', 'doubao', 'assets/png/plugins/doubao.png'),
  };

  static String defaultBalanceUrl(String key) {
    return switch (key) {
      'deepseek' => 'https://api.deepseek.com/user/balance',
      'openai' => 'https://api.openai.com/v1/usage',
      'anthropic' => 'https://api.anthropic.com/v1/usage',
      'doubao' => 'https://ark.cn-beijing.volces.com/api/v3/usage',
      _ => 'https://api.deepseek.com/user/balance',
    };
  }

  static String assetPath(String key) {
    return platforms[key]?.asset ?? 'assets/png/plugins/deepseek.png';
  }
}
