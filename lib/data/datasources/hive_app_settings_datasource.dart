import 'package:hive/hive.dart';
import '../models/app_settings.dart';

class HiveAppSettingsDataSource {
  final Box<AppSettings> box;
  static const String _settingsKey = 'settings';

  HiveAppSettingsDataSource(this.box);

  Future<AppSettings> getSettings() async {
    final settings = box.get(_settingsKey);
    if (settings == null) {
      final initial = AppSettings.initial();
      await saveSettings(initial);
      return initial;
    }
    return settings;
  }

  Future<void> saveSettings(AppSettings settings) async {
    await box.put(_settingsKey, settings);
  }
}
