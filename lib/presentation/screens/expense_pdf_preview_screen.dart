import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:hive/hive.dart';

import '../../application/providers/expense_sheet_provider.dart';
import '../../data/models/expense_sheet.dart';
import '../../data/models/expense_item.dart';
import '../../pdf/expense_sheet_pdf_builder.dart';

/// PDFソート種別
enum PdfSortType {
  dateAsc('支払日 (古い順)', Icons.calendar_today),
  dateDesc('支払日 (新しい順)', Icons.calendar_today),
  payeeAsc('支払先 (A→Z)', Icons.store),
  payeeDesc('支払先 (Z→A)', Icons.store),
  amountAsc('金額 (安い順)', Icons.attach_money),
  amountDesc('金額 (高い順)', Icons.attach_money),
  purposeAsc('用途 (A→Z)', Icons.description),
  purposeDesc('用途 (Z→A)', Icons.description);

  const PdfSortType(this.label, this.icon);
  final String label;
  final IconData icon;

  /// 表示用の短いラベル
  String get shortLabel {
    switch (this) {
      case PdfSortType.dateAsc:
        return '支払日↑';
      case PdfSortType.dateDesc:
        return '支払日↓';
      case PdfSortType.payeeAsc:
        return '支払先↑';
      case PdfSortType.payeeDesc:
        return '支払先↓';
      case PdfSortType.amountAsc:
        return '金額↑';
      case PdfSortType.amountDesc:
        return '金額↓';
      case PdfSortType.purposeAsc:
        return '用途↑';
      case PdfSortType.purposeDesc:
        return '用途↓';
    }
  }
}

/// ソート設定を永続化するためのプロバイダー
final pdfSortTypeProvider = StateProvider<PdfSortType>((ref) {
  // Hiveから前回のソート設定を読み込む
  final box = Hive.box('app_settings');
  final savedSortIndex = box.get('pdf_sort_type', defaultValue: 0) as int;
  
  if (savedSortIndex >= 0 && savedSortIndex < PdfSortType.values.length) {
    return PdfSortType.values[savedSortIndex];
  }
  
  return PdfSortType.dateAsc;
});

class ExpensePdfPreviewScreen extends ConsumerStatefulWidget {
  static const routeName = '/pdf_preview';
  final String sheetId;

  const ExpensePdfPreviewScreen({super.key, required this.sheetId});

  @override
  ConsumerState<ExpensePdfPreviewScreen> createState() =>
      _ExpensePdfPreviewScreenState();
}

class _ExpensePdfPreviewScreenState
    extends ConsumerState<ExpensePdfPreviewScreen> {
  
  /// 明細をソート
  List<ExpenseItem> _sortItems(List<ExpenseItem> items, PdfSortType sortType) {
    final sortedItems = List<ExpenseItem>.from(items);

    switch (sortType) {
      case PdfSortType.dateAsc:
        sortedItems.sort((a, b) => a.date.compareTo(b.date));
        break;
      case PdfSortType.dateDesc:
        sortedItems.sort((a, b) => b.date.compareTo(a.date));
        break;
      case PdfSortType.payeeAsc:
        sortedItems.sort((a, b) => a.payee.compareTo(b.payee));
        break;
      case PdfSortType.payeeDesc:
        sortedItems.sort((a, b) => b.payee.compareTo(a.payee));
        break;
      case PdfSortType.amountAsc:
        sortedItems.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case PdfSortType.amountDesc:
        sortedItems.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case PdfSortType.purposeAsc:
        sortedItems.sort((a, b) => a.purpose.compareTo(b.purpose));
        break;
      case PdfSortType.purposeDesc:
        sortedItems.sort((a, b) => b.purpose.compareTo(a.purpose));
        break;
    }

    return sortedItems;
  }

  /// ソート選択ダイアログ
  Future<void> _showSortDialog() async {
    final currentSortType = ref.read(pdfSortTypeProvider);
    
    final selected = await showDialog<PdfSortType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('明細の並び順を選択'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: PdfSortType.values.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sortType = PdfSortType.values[index];
                final isSelected = sortType == currentSortType;

                return ListTile(
                  leading: Icon(
                    sortType.icon,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    sortType.label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, sortType),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );

    if (selected != null && selected != currentSortType) {
      // ソート設定を更新
      ref.read(pdfSortTypeProvider.notifier).state = selected;
      
      // Hiveに保存
      final box = Hive.box('app_settings');
      await box.put('pdf_sort_type', selected.index);

      // ソート変更のフィードバック
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('並び順を「${selected.label}」に変更しました'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetAsync = ref.watch(expenseSheetProvider(widget.sheetId));
    final currentSortType = ref.watch(pdfSortTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFプレビュー'),
        actions: [
          // ソートボタン
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '並び替え',
            onPressed: _showSortDialog,
          ),
          // ヘルプボタン
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'ヘルプ',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('PDFプレビュー'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📄 右上の共有アイコンからPDFを保存・共有できます'),
                      SizedBox(height: 8),
                      Text('🖨️ プリンターアイコンから印刷できます'),
                      SizedBox(height: 8),
                      Text('🔄 並び替えボタンで明細の順序を変更できます'),
                      SizedBox(height: 8),
                      Text('💾 並び順は次回も保持されます'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: sheetAsync.when(
        data: (sheet) {
          if (sheet == null) {
            return const Center(child: Text('精算書が見つかりません'));
          }

          // 最終バリデーション
          if (sheet.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '明細が登録されていません',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '先に明細を追加してください',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('編集画面に戻る'),
                  ),
                ],
              ),
            );
          }

          // ソートされた明細で新しい精算書を作成
          final sortedSheet = sheet.copyWith(
            items: _sortItems(sheet.items, currentSortType),
          );

          return Column(
            children: [
              // ソート状態表示バー
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      currentSortType.icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '並び順: ${currentSortType.label}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${sortedSheet.items.length}件)',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: const Text(
                        '保存済み',
                        style: TextStyle(fontSize: 11),
                      ),
                      avatar: const Icon(Icons.bookmark, size: 14),
                      backgroundColor: Colors.green.withOpacity(0.2),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _showSortDialog,
                      icon: const Icon(Icons.swap_vert, size: 16),
                      label: const Text('変更'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PDFプレビュー
              Expanded(
                child: PdfPreview(
                  build: (format) async {
                    try {
                      return await buildExpenseSheetPdf(format, sortedSheet);
                    } catch (e) {
                      // エラーが発生した場合はスナックバーで通知
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PDF生成エラー: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                      rethrow;
                    }
                  },
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  initialPageFormat: PdfPageFormat.a4,
                  pdfFileName: '${sheet.title}_${currentSortType.shortLabel}.pdf',
                  allowPrinting: true,
                  allowSharing: true,
                  maxPageWidth: 700,
                  onError: (context, error) {
                    return Center(
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
                              'PDF生成エラー',
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
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('編集画面に戻る'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                // 再試行
                                ref.invalidate(
                                    expenseSheetProvider(widget.sheetId));
                              },
                              child: const Text('再試行'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('PDFを生成中...'),
            ],
          ),
        ),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('戻る'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}