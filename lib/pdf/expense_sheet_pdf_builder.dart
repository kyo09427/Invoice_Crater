import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/expense_sheet.dart';

/// 精算書PDFを生成する関数（決済手段セルを「セル全体の背景色」で色分け）
Future<Uint8List> buildExpenseSheetPdf(
  PdfPageFormat format,
  ExpenseSheet sheet,
) async {
  final doc = pw.Document();

  try {
    // 日本語フォントの読み込み
    pw.Font font;
    pw.Font fontBold;

    try {
      final fontData =
          await rootBundle.load("assets/fonts/NotoSansJP-Regular.ttf");
      final fontBoldData =
          await rootBundle.load("assets/fonts/NotoSansJP-Bold.ttf");
      font = pw.Font.ttf(fontData);
      fontBold = pw.Font.ttf(fontBoldData);
    } catch (e) {
      print('Warning: Custom font not found. Using default font. Error: $e');
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final dateFormat = DateFormat('yyyy/MM/dd');
    final numberFormat = NumberFormat('#,###');

    // ===== HTML側テーマに寄せた色 =====
    final primary = PdfColor.fromInt(0xFF2563EB); // #2563EB
    final bgPaper = PdfColors.white;
    final textLight = PdfColor.fromInt(0xFF1F2937); // gray-800
    final textMuted = PdfColor.fromInt(0xFF6B7280); // gray-500/600相当
    final borderLight = PdfColor.fromInt(0xFFE5E7EB); // gray-200
    final tableHeaderLight = PdfColor.fromInt(0xFFF9FAFB); // gray-50
    final totalCardBg = PdfColor.fromInt(0xFFF9FAFB); // gray-50

    // HTMLの padding: 12mm 相当
    final pageMargin = 12 * PdfPageFormat.mm;

    // ===== 決済手段ごとの色割り当て（登場順で自動追加）=====
    final Map<String, int> methodIndex = <String, int>{};
    var nextIdx = 0;
    for (final item in sheet.items) {
      final key = item.paymentMethod.trim();
      if (key.isEmpty) continue;
      methodIndex.putIfAbsent(key, () => nextIdx++);
    }

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.all(pageMargin),
        build: (context) {
          return pw.Container(
            color: bgPaper,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ===== Header (申請者 / 日付) =====
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildHeaderMeta(
                      iconMarkColor: primary,
                      label: '申請者：',
                      value: sheet.applicantName,
                      font: font,
                      fontBold: fontBold,
                      labelColor: textMuted,
                      valueColor: textLight,
                    ),
                    _buildHeaderMeta(
                      iconMarkColor: primary,
                      label: '日付：',
                      value: dateFormat.format(sheet.createdAt),
                      font: font,
                      fontBold: fontBold,
                      labelColor: textMuted,
                      valueColor: textLight,
                    ),
                  ],
                ),

                pw.SizedBox(height: 18),

                // ===== Title (下線付き) =====
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: primary, width: 2),
                      ),
                    ),
                    child: pw.Text(
                      '精算書',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        color: textLight,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 18),

                // ===== 明細 =====
                if (sheet.items.isEmpty)
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 12),
                      child: pw.Text(
                        '明細がありません',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  )
                else ...[
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderLight, width: 1),
                      borderRadius: pw.BorderRadius.circular(6),
                      color: bgPaper,
                    ),
                    child: pw.Table(
                      border: pw.TableBorder(
                        horizontalInside:
                            pw.BorderSide(color: borderLight, width: 0.8),
                        verticalInside:
                            pw.BorderSide(color: borderLight, width: 0.8),
                      ),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(84), // 支払日
                        1: const pw.FlexColumnWidth(1.8), // 支払い先
                        2: const pw.FlexColumnWidth(2.5), // 目的・用途
                        3: const pw.FixedColumnWidth(60), // 決済手段
                        4: const pw.FixedColumnWidth(65), // 金額
                      },
                      children: [
                        // ヘッダー行（縦幅詰め）
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: tableHeaderLight),
                          children: [
                            _buildHeaderCell(
                              '支払日',
                              fontBold,
                              textMuted,
                              alignment: pw.Alignment.centerLeft,
                            ),
                            _buildHeaderCell(
                              '支払い先',
                              fontBold,
                              textMuted,
                              alignment: pw.Alignment.centerLeft,
                            ),
                            _buildHeaderCell(
                              '目的・用途',
                              fontBold,
                              textMuted,
                              alignment: pw.Alignment.centerLeft,
                            ),
                            _buildHeaderCell(
                              '決済手段',
                              fontBold,
                              textMuted,
                              alignment: pw.Alignment.center,
                            ),
                            _buildHeaderCell(
                              '金額',
                              fontBold,
                              textMuted,
                              alignment: pw.Alignment.centerRight,
                            ),
                          ],
                        ),

                        // データ行
                        ...sheet.items.map((item) {
                          final methodKey = item.paymentMethod.trim();
                          final idx = methodIndex[methodKey] ?? 0;
                          final cellColors = _paymentCellColors(idx);

                          return pw.TableRow(
                            children: [
                              _buildDataCell(
                                dateFormat.format(item.date),
                                font: fontBold,
                                fontSize: 10,
                                color: textLight,
                                alignment: pw.Alignment.center,
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                              ),
                              _buildDataCell(
                                item.payee,
                                font: font,
                                fontSize: 10,
                                color: PdfColor.fromInt(0xFF374151),
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                alignment: pw.Alignment.centerLeft,
                              ),
                              _buildDataCell(
                                item.purpose,
                                font: font,
                                fontSize: 10,
                                color: PdfColor.fromInt(0xFF374151),
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                alignment: pw.Alignment.centerLeft,
                              ),

                              // ★決済手段：セル全体を着色（支払方法ごとに自動で色追加）
                              pw.Container(
                                // ここで “セル全体” の背景色を塗る
                                color: cellColors.bg,
                                alignment: pw.Alignment.center,
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: pw.Text(
                                  methodKey.isEmpty ? '-' : methodKey,
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8.8,
                                    color: cellColors.fg,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),

                              _buildDataCell(
                                '¥${numberFormat.format(item.amount)}',
                                font: fontBold,
                                fontSize: 10,
                                color: textLight,
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                alignment: pw.Alignment.centerRight,
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // ===== 合計カード（右下） =====
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 210,
                        padding: const pw.EdgeInsets.all(14),
                        decoration: pw.BoxDecoration(
                          color: totalCardBg,
                          border: pw.Border.all(color: borderLight, width: 1),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              '合計金額',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 12,
                                color: PdfColor.fromInt(0xFF1F2937),
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '¥${numberFormat.format(sheet.totalAmount)}',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 16,
                                color: primary,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  } catch (e) {
    print('Error generating PDF: $e');
    rethrow;
  }
}

/// ヘッダーの「申請者/日付」ブロック
pw.Widget _buildHeaderMeta({
  required PdfColor iconMarkColor,
  required String label,
  required String value,
  required pw.Font font,
  required pw.Font fontBold,
  required PdfColor labelColor,
  required PdfColor valueColor,
}) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(
        width: 12,
        height: 12,
        decoration: pw.BoxDecoration(
          color: iconMarkColor,
          borderRadius: pw.BorderRadius.circular(3),
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Text(
        label,
        style: pw.TextStyle(
          font: font,
          fontSize: 11,
          color: labelColor,
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 11,
          color: valueColor,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ],
  );
}

/// テーブルヘッダーセル
pw.Widget _buildHeaderCell(
  String text,
  pw.Font fontBold,
  PdfColor color, {
  pw.Alignment alignment = pw.Alignment.centerLeft,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    alignment: alignment,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: fontBold,
        fontSize: 9,
        color: color,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

/// テーブルデータセル
pw.Widget _buildDataCell(
  String text, {
  required pw.Font font,
  double fontSize = 9,
  PdfColor? color,
  pw.EdgeInsets? padding,
  pw.Alignment alignment = pw.Alignment.centerLeft,
}) {
  return pw.Container(
    padding: padding ?? const pw.EdgeInsets.all(8),
    alignment: alignment,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: fontSize,
        color: color ?? PdfColors.black,
      ),
    ),
  );
}

/// 決済手段セル用の色を index から無限生成（支払方法が増えるほど色も増える）
_PaymentCellColors _paymentCellColors(int index) {
  // 黄金角で色相をずらす（増えても被りにくい）
  final hue = (index * 137.508) % 360.0;

  // セル背景：薄め（読みやすい）
  final bgRgb = _hslToRgb(hue, 0.55, 0.92);
  // 文字色：同色相で濃いめ
  final fgRgb = _hslToRgb(hue, 0.65, 0.22);

  return _PaymentCellColors(
    bg: PdfColor(bgRgb.r, bgRgb.g, bgRgb.b),
    fg: PdfColor(fgRgb.r, fgRgb.g, fgRgb.b),
  );
}

/// HSL -> RGB（0..1）
_RGB _hslToRgb(double h, double s, double l) {
  final hh = (h % 360) / 360.0;

  double r, g, b;

  if (s == 0) {
    r = g = b = l;
  } else {
    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;

    r = _hueToRgb(p, q, hh + 1 / 3);
    g = _hueToRgb(p, q, hh);
    b = _hueToRgb(p, q, hh - 1 / 3);
  }

  return _RGB(r, g, b);
}

double _hueToRgb(double p, double q, double t) {
  var tt = t;
  if (tt < 0) tt += 1;
  if (tt > 1) tt -= 1;
  if (tt < 1 / 6) return p + (q - p) * 6 * tt;
  if (tt < 1 / 2) return q;
  if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
  return p;
}

class _PaymentCellColors {
  final PdfColor bg;
  final PdfColor fg;
  const _PaymentCellColors({required this.bg, required this.fg});
}

class _RGB {
  final double r;
  final double g;
  final double b;
  const _RGB(this.r, this.g, this.b);
}
