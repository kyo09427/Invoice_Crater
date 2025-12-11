import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../application/providers/expense_sheet_provider.dart';
import '../../pdf/expense_sheet_pdf_builder.dart';

class ExpensePdfPreviewScreen extends ConsumerWidget {
  static const routeName = '/pdf_preview';
  final String sheetId;

  const ExpensePdfPreviewScreen({super.key, required this.sheetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetAsync = ref.watch(expenseSheetProvider(sheetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFプレビュー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'ヘルプ',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('PDFプレビュー'),
                  content: const Text(
                    '右上の共有アイコンからPDFを保存・共有できます。\n'
                    'プリンターアイコンから印刷できます。',
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

          return PdfPreview(
            build: (format) async {
              try {
                return await buildExpenseSheetPdf(format, sheet);
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
            pdfFileName: '${sheet.title}.pdf',
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
                          ref.invalidate(expenseSheetProvider(sheetId));
                        },
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              );
            },
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