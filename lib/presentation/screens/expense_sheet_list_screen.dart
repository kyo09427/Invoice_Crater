import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/providers/expense_sheet_list_provider.dart';
import '../../core/utils/formatting_utils.dart';
import '../../data/models/expense_sheet.dart';
import 'expense_sheet_edit_screen.dart';
import 'settings_screen.dart'; // Import for settings route if needed or use named route

class ExpenseSheetListScreen extends ConsumerWidget {
  static const routeName = '/';

  const ExpenseSheetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseSheetListAsync = ref.watch(expenseSheetListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('精算書一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: expenseSheetListAsync.when(
        data: (expenseSheets) {
          if (expenseSheets.isEmpty) {
            return const Center(
              child: Text('精算書がありません。\n右下のボタンから作成してください。'),
            );
          }
          // Sort by createdAt descending
          final sortedSheets = List<ExpenseSheet>.from(expenseSheets)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            itemCount: sortedSheets.length,
            itemBuilder: (context, index) {
              final sheet = sortedSheets[index];
              return ListTile(
                title: Text(sheet.title),
                subtitle: Text(FormattingUtils.formatDate(sheet.createdAt)),
                trailing: Text(FormattingUtils.formatCurrency(sheet.totalAmount)),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    ExpenseSheetEditScreen.routeName,
                    arguments: sheet.id,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Create new sheet
          const uuid = Uuid();
          final newSheet = ExpenseSheet(
            id: uuid.v4(),
            title: '未命名の精算書',
            applicantName: '', // Will be filled with default in EditScreen logic or here?
            // Doc says: "空の場合、appSettings.defaultApplicantName をプレースホルダー等に利用"
            // So empty is fine initially. Or we can prepopulate.
            // Let's keep it empty and let EditScreen handle defaults.
            createdAt: DateTime.now(),
            items: [],
          );
          
          await ref.read(expenseSheetListProvider.notifier).addSheet(newSheet);
          
          if (context.mounted) {
             Navigator.pushNamed(
              context,
              ExpenseSheetEditScreen.routeName,
              arguments: newSheet.id,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
