import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/expense_sheet.dart';

Future<Uint8List> buildExpenseSheetPdf(
  PdfPageFormat format,
  ExpenseSheet sheet,
) async {
  final doc = pw.Document();
  
  // 日本語フォントを取得
  final fontData = await rootBundle.load("assets/fonts/NotoSansJP-Regular.ttf");
  final fontBoldData = await rootBundle.load("assets/fonts/NotoSansJP-Bold.ttf");
  
  final font = pw.Font.ttf(fontData);
  final fontBold = pw.Font.ttf(fontBoldData);

  final dateFormat = DateFormat('yyyy/MM/dd');
  final numberFormat = NumberFormat('#,###');

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: format,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        margin: const pw.EdgeInsets.all(25 * PdfPageFormat.mm),
      ),
      header: (context) {
        return pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('申請者: ${sheet.applicantName}'),
                pw.Text('作成日: ${dateFormat.format(sheet.createdAt)}'),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                '精算書',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 20),
          ],
        );
      },
      build: (context) {
        return [
          pw.Table.fromTextArray(
            headers: ['支払日', '支払い先', '目的・用途', '決済手段', '金額'],
            data: sheet.items.map((item) {
              return [
                dateFormat.format(item.date),
                item.payee,
                item.purpose,
                item.paymentMethod,
                '${numberFormat.format(item.amount)} 円',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                '合計: ${numberFormat.format(sheet.totalAmount)} 円',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ];
      },
    ),
  );

  return doc.save();
}