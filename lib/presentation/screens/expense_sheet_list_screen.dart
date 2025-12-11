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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF101418)
          : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1C1E)
            : const Color(0xFFFDFBFF),
        elevation: 1,
        titleSpacing: 16,
        title: const Text(
          'ホーム',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1F1F1F),
          ),
        ),
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
              child: Text(
                '精算書がありません。\n右下のボタンから作成してください。',
                textAlign: TextAlign.center,
              ),
            );
          }
          // Sort by createdAt descending
          final sortedSheets = List<ExpenseSheet>.from(expenseSheets)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            itemCount: sortedSheets.length,
            itemBuilder: (context, index) {
              final sheet = sortedSheets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      ExpenseSheetEditScreen.routeName,
                      arguments: sheet.id,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E2B36)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Theme.of(context).brightness == Brightness.dark
                          ? Border.all(color: const Color(0xFF374151))
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? const Color(0xFF1D4ED8).withOpacity(0.4)
                                : const Color(0xFFD3E3FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.train,
                            size: 24,
                            color: Color(0xFF0B57D0),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sheet.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : const Color(0xFF1F1F1F),
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      FormattingUtils.formatDate(
                                        sheet.createdAt,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF6B7280),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                FormattingUtils.formatCurrency(
                                  sheet.totalAmount,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : const Color(0xFF1F1F1F),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
            applicantName:
                '', // Will be filled with default in EditScreen logic or here?
            // Doc says: "空の場合、appSettings.defaultApplicantName をプレースホルダー等に利用"
            // So empty is fine initially. Or we can prepopulate.
            // Let's keep it empty and let EditScreen handle defaults.
            createdAt: DateTime.now(),
            items: [],
          );

          await ref
              .read(expenseSheetListProvider.notifier)
              .addSheet(newSheet);

          if (context.mounted) {
            Navigator.pushNamed(
              context,
              ExpenseSheetEditScreen.routeName,
              arguments: newSheet.id,
            );
          }
        },
        backgroundColor: const Color(0xFF0B57D0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
