import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/datasources/hive_app_settings_datasource.dart';
import '../../data/datasources/hive_expense_sheet_datasource.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/expense_sheet.dart';

// Hive Box Providers - will be overridden in main.dart
final expenseSheetBoxProvider = Provider<Box<ExpenseSheet>>((ref) {
  throw UnimplementedError('box must be overridden');
});

final appSettingsBoxProvider = Provider<Box<AppSettings>>((ref) {
  throw UnimplementedError('box must be overridden');
});

// DataSource Providers
final expenseSheetDataSourceProvider = Provider<HiveExpenseSheetDataSource>((ref) {
  final box = ref.watch(expenseSheetBoxProvider);
  return HiveExpenseSheetDataSource(box);
});

final appSettingsDataSourceProvider = Provider<HiveAppSettingsDataSource>((ref) {
  final box = ref.watch(appSettingsBoxProvider);
  return HiveAppSettingsDataSource(box);
});
