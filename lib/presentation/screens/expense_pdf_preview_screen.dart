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
      appBar: AppBar(title: const Text('PDFプレビュー')),
      body: sheetAsync.when(
        data: (sheet) {
          if (sheet == null) {
            return const Center(child: Text('精算書が見つかりません'));
          }

          return PdfPreview(
            build: (format) => buildExpenseSheetPdf(format, sheet),
            canChangeOrientation: false,
            canChangePageFormat: false,
            initialPageFormat: PdfPageFormat.a4,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
