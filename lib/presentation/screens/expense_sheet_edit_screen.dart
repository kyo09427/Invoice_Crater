import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_settings_provider.dart';
import '../../application/providers/expense_sheet_provider.dart';
import '../../core/utils/formatting_utils.dart';
import '../../data/models/expense_item.dart';
import '../../data/models/expense_sheet.dart';
import '../widgets/expense_item_edit_bottom_sheet.dart';
import 'expense_pdf_preview_screen.dart';

class ExpenseSheetEditScreen extends ConsumerStatefulWidget {
  static const routeName = '/sheet';
  final String sheetId;

  const ExpenseSheetEditScreen({super.key, required this.sheetId});

  @override
  ConsumerState<ExpenseSheetEditScreen> createState() =>
      _ExpenseSheetEditScreenState();
}

class _ExpenseSheetEditScreenState
    extends ConsumerState<ExpenseSheetEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _applicantController;
  DateTime? _createdAt;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _applicantController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _applicantController.dispose();
    super.dispose();
  }

  void _initializeControllers(ExpenseSheet sheet) {
    if (_initialized) return;
    _titleController.text = sheet.title;
    _applicantController.text = sheet.applicantName;
    _createdAt = sheet.createdAt;
    _initialized = true;

    // デフォルト申請者名の設定
    if (sheet.applicantName.isEmpty) {
      final settings = ref.read(appSettingsProvider).asData?.value;
      if (settings != null && settings.defaultApplicantName.isNotEmpty) {
        _applicantController.text = settings.defaultApplicantName;
      }
    }
  }

  Future<void> _updateSheet(ExpenseSheet newSheet) async {
    await ref
        .read(expenseSheetProvider(widget.sheetId).notifier)
        .updateSheet(newSheet);
  }

  void _onSaveHeader() {
    final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
    if (sheet == null) return;

    final newSheet = sheet.copyWith(
      title: _titleController.text.trim(),
      applicantName: _applicantController.text.trim(),
      createdAt: _createdAt,
    );
    _updateSheet(newSheet);
  }

  Future<void> _onAddItem() async {
    final newItem = await showModalBottomSheet<ExpenseItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const ExpenseItemEditBottomSheet(),
    );

    if (newItem != null) {
      final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
      if (sheet != null) {
        final newItems = List<ExpenseItem>.from(sheet.items)..add(newItem);
        final newSheet = sheet.copyWith(items: newItems);
        await _updateSheet(newSheet);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('明細を追加しました'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// スワイプ削除の確認ダイアログ
  Future<bool?> _confirmDismiss(
    BuildContext context,
    DismissDirection direction,
    ExpenseItem item,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('明細を削除'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('この明細を削除してもよろしいですか？'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.payee,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.purpose,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          FormattingUtils.formatDate(item.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.paymentMethod,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          FormattingUtils.formatCurrency(item.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                '削除する',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDismissed(
    DismissDirection direction,
    ExpenseItem item,
  ) async {
    final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
    if (sheet != null) {
      final newItems = List<ExpenseItem>.from(sheet.items)
        ..removeWhere((e) => e.id == item.id);
      final newSheet = sheet.copyWith(items: newItems);
      await _updateSheet(newSheet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.payee}を削除しました'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '元に戻す',
              onPressed: () async {
                final restoredItems = List<ExpenseItem>.from(newItems)
                  ..add(item);
                final restoredSheet =
                    newSheet.copyWith(items: restoredItems);
                await _updateSheet(restoredSheet);
              },
            ),
          ),
        );
      }
    }
  }

  void _onNavigateToPdf() {
    final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;

    // バリデーション
    if (sheet == null) return;

    if (sheet.title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('タイトルを入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (sheet.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('明細を1件以上追加してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ヘッダー情報を保存してから遷移
    _onSaveHeader();

    Navigator.pushNamed(
      context,
      ExpensePdfPreviewScreen.routeName,
      arguments: sheet.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetAsync = ref.watch(expenseSheetProvider(widget.sheetId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Material Design 3 風のカラーパレット（HTMLに合わせた見た目）
    const primaryColor = Color(0xFF0061A4);
    const surfaceLight = Color(0xFFFDFCFF);
    const surfaceDark = Color(0xFF1A1C1E);
    const surfaceContainerLight = Color(0xFFF0F4F9);
    const surfaceContainerDark = Color(0xFF1E2227);
    const onSurface = Color(0xFF1A1C1E);
    const onSurfaceVariant = Color(0xFF43474E);

    final surfaceColor = isDark ? surfaceDark : surfaceLight;
    final surfaceContainerColor =
        isDark ? surfaceContainerDark : surfaceContainerLight;
    final textPrimaryColor = isDark ? Colors.white : onSurface;
    final textSecondaryColor =
        isDark ? Colors.grey[300]! : onSurfaceVariant;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          '精算書編集',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _onSaveHeader,
            child: const Text('保存'),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDFプレビュー',
            onPressed: _onNavigateToPdf,
          ),
        ],
      ),
      body: sheetAsync.when(
        data: (sheet) {
          if (sheet == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '精算書が見つかりません',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
          _initializeControllers(sheet);

          return Column(
            children: [
              // 合計カード
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceContainerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '合計金額',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              FormattingUtils.formatCurrency(
                                sheet.totalAmount,
                              ),
                              style: TextStyle(
                                fontSize: 28,
                                color: textPrimaryColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1E4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Color(0xFF001D36),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ヘッダー情報（タイトル・申請者名・作成日）
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: '精算書タイトル',
                          hintText: '例: 11月度 生徒会精算書',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: '',
                          suffixIcon: _titleController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _titleController.clear();
                                    _onSaveHeader();
                                  },
                                )
                              : null,
                        ),
                        maxLength: 100,
                        onChanged: (_) => _onSaveHeader(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _applicantController,
                        decoration: InputDecoration(
                          labelText: '申請者名',
                          hintText: '例: 山田 太郎',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: '',
                          suffixIcon: _applicantController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _applicantController.clear();
                                    _onSaveHeader();
                                  },
                                )
                              : null,
                        ),
                        maxLength: 50,
                        onChanged: (_) => _onSaveHeader(),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _createdAt ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            locale: const Locale('ja', 'JP'),
                          );
                          if (picked != null) {
                            setState(() {
                              _createdAt = picked;
                            });
                            _onSaveHeader();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '作成日',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                FormattingUtils.formatDate(
                                  _createdAt ?? DateTime.now(),
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 明細一覧ヘッダー
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '明細 (${sheet.items.length}件)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 明細一覧
              Expanded(
                child: sheet.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '明細がありません',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '下のボタンから明細を追加してください',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: sheet.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = sheet.items[index];

                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) =>
                                _confirmDismiss(context, direction, item),
                            onDismissed: (direction) =>
                                _onDismissed(direction, item),
                            background: Container(
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.only(right: 20),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '削除',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: surfaceContainerColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      item.payee.isNotEmpty
                                          ? item.payee[0]
                                          : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.payee,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: textPrimaryColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              FormattingUtils.formatCurrency(
                                                item.amount,
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.date.month}/${item.date.day} • ${item.purpose} • ${item.paymentMethod}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // フッター（追加ボタンのみ）
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _onAddItem,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      '明細を追加',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
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
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('戻る'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () {
                        ref.invalidate(expenseSheetProvider(widget.sheetId));
                      },
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
