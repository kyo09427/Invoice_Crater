import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_settings.dart';
import 'core_providers.dart';

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final dataSource = ref.watch(appSettingsDataSourceProvider);
    return dataSource.getSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    final dataSource = ref.read(appSettingsDataSourceProvider);
    await dataSource.saveSettings(settings);
    
    // Invalidate self to reload
    ref.invalidateSelf();
    await future;
  }
}
