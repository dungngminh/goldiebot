import 'dart:convert';
import 'dart:io';

class AppConfig {
  final Uri sourceUrl;
  final int intervalHours;
  final bool notifyOnFirstRun;

  const AppConfig({
    required this.sourceUrl,
    required this.intervalHours,
    required this.notifyOnFirstRun,
  });

  static AppConfig defaults() => AppConfig(
        sourceUrl: Uri.parse('https://kimkhanhviethung.vn/tra-cuu-gia-vang.html'),
        intervalHours: 1,
        notifyOnFirstRun: false,
      );

  static Future<AppConfig> load(String configPath) async {
    final file = File(configPath);
    if (!await file.exists()) return defaults();

    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;

    return AppConfig(
      sourceUrl: Uri.parse((json['sourceUrl'] as String?) ??
          defaults().sourceUrl.toString()),
      intervalHours: (json['intervalHours'] as num?)?.toInt() ??
          defaults().intervalHours,
      notifyOnFirstRun:
          (json['notifyOnFirstRun'] as bool?) ?? defaults().notifyOnFirstRun,
    );
  }
}

