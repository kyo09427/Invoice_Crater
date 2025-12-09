import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'application/providers/core_providers.dart';
import 'data/models/app_settings.dart';
import 'data/models/expense_item.dart';
import 'data/models/expense_sheet.dart';
import 'presentation/screens/expense_sheet_list_screen.dart';
import 'presentation/screens/expense_sheet_edit_screen.dart';
import 'presentation/screens/expense_pdf_preview_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(ExpenseItemAdapter());
  Hive.registerAdapter(ExpenseSheetAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  
  // Open Boxes
  final expenseSheetBox = await Hive.openBox<ExpenseSheet>('expense_sheets');
  final appSettingsBox = await Hive.openBox<AppSettings>('app_settings');

  runApp(
    ProviderScope(
      overrides: [
        expenseSheetBoxProvider.overrideWithValue(expenseSheetBox),
        appSettingsBoxProvider.overrideWithValue(appSettingsBox),
      ],
      child: const InvoiceCreatorApp(),
    ),
  );
}

class InvoiceCreatorApp extends StatelessWidget {
  const InvoiceCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Creator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'NotoSansJP', // Assuming Japanese font usually
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ExpenseSheetListScreen(),
        '/settings': (context) => const SettingsScreen(),
        // Dynamic routes with arguments will need onGenerateRoute or managing arguments manually in build
      },
      onGenerateRoute: (settings) {
        if (settings.name == ExpenseSheetEditScreen.routeName) {
          final sheetId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ExpenseSheetEditScreen(sheetId: sheetId),
          );
        }
        if (settings.name == ExpensePdfPreviewScreen.routeName) {
          final sheetId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ExpensePdfPreviewScreen(sheetId: sheetId),
          );
        }
        return null; // Let unknown routes fail or go to home
      },
    );
  }
}
