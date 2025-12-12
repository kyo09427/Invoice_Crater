import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/providers/expense_sheet_list_provider.dart';
import '../../core/utils/formatting_utils.dart';
import '../../data/models/expense_sheet.dart';
import 'expense_sheet_edit_screen.dart';

class ExpenseSheetListScreen extends ConsumerWidget {
  static const routeName = '/';

  const ExpenseSheetListScreen({super.key});

  /// 精算書削除の確認ダイアログ
  Future<bool?> _confirmDeleteSheet(
    BuildContext context,
    ExpenseSheet sheet,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('精算書を削除'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('この精算書を削除してもよろしいですか？'),
              const SizedBox(height: 8),
              const Text(
                '削除すると、すべての明細データも失われます。',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sheet.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '作成日: ${FormattingUtils.formatDate(sheet.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${sheet.items.length}件',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormattingUtils.formatCurrency(sheet.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  /// 精算書削除実行
  Future<void> _onDismissed(
    BuildContext context,
    WidgetRef ref,
    ExpenseSheet sheet,
  ) async {
    try {
      await ref.read(expenseSheetListProvider.notifier).deleteSheet(sheet.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${sheet.title}」を削除しました'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '元に戻す',
              onPressed: () {
                // TODO: v1.2で実装予定 - 削除の取り消し
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 新規精算書作成
  Future<void> _onCreateNewSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    const uuid = Uuid();
    final newSheet = ExpenseSheet(
      id: uuid.v4(),
      title: '未命名の精算書',
      applicantName: '',
      createdAt: DateTime.now(),
      items: [],
    );

    try {
      await ref.read(expenseSheetListProvider.notifier).addSheet(newSheet);

      if (context.mounted) {
        Navigator.pushNamed(
          context,
          ExpenseSheetEditScreen.routeName,
          arguments: newSheet.id,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('作成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
            tooltip: '設定',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: expenseSheetListAsync.when(
        data: (expenseSheets) {
          if (expenseSheets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '精算書がありません',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '右下のボタンから作成してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
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
                child: Dismissible(
                  key: Key(sheet.id),
                  direction: DismissDirection.endToStart,
                  
                  // 削除確認ダイアログ
                  confirmDismiss: (direction) async {
                    return await _confirmDeleteSheet(context, sheet);
                  },
                  
                  // 削除実行
                  onDismissed: (direction) async {
                    await _onDismissed(context, ref, sheet);
                  },
                  
                  // スワイプ時の背景
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 36,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '削除',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 精算書カード
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
                          // アイコン
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF1D4ED8).withOpacity(0.4)
                                  : const Color(0xFFD3E3FD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              size: 28,
                              color: Color(0xFF0B57D0),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // タイトルと情報
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sheet.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : const Color(0xFF1F1F1F),
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 4),
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
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.description,
                                      size: 14,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${sheet.items.length}件',
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // 金額
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                FormattingUtils.formatCurrency(
                                  sheet.totalAmount,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF1F1F1F),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  sheet.applicantName.isEmpty
                                      ? '未設定'
                                      : sheet.applicantName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'エラーが発生しました',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(expenseSheetListProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onCreateNewSheet(context, ref),
        backgroundColor: const Color(0xFF0B57D0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新規作成'),
      ),
    );
  }
}