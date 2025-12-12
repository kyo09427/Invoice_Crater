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

  Future<void> _updateSheet(ExpenseSheet sheet) async {
    try {
      await ref
          .read(expenseSheetProvider(widget.sheetId).notifier)
          .updateSheet(sheet);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _onEditItem(ExpenseItem item) async {
    final updatedItem = await showModalBottomSheet<ExpenseItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ExpenseItemEditBottomSheet(item: item),
    );

    if (updatedItem != null) {
      final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
      if (sheet != null) {
        final newItems = sheet.items.map((e) {
          return e.id == updatedItem.id ? updatedItem : e;
        }).toList();
        final newSheet = sheet.copyWith(items: newItems);
        await _updateSheet(newSheet);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('明細を更新しました'),
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormattingUtils.formatCurrency(item.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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

  /// スワイプ削除実行
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
              onPressed: () {
                // 元に戻す処理（将来実装）
                // TODO: 削除の取り消し機能
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

    if (sheet.applicantName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('申請者名を入力してください'),
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
      arguments: widget.sheetId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetAsync = ref.watch(expenseSheetProvider(widget.sheetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('精算書編集'),
        actions: [
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
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '精算書が見つかりません',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('一覧に戻る'),
                  ),
                ],
              ),
            );
          }
          _initializeControllers(sheet);

          return Column(
            children: [
              // ヘッダー情報入力
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: '精算書タイトル',
                        hintText: '例: 11月度 生徒会精算書',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.title),
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
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
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
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '作成日',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              FormattingUtils.formatDate(
                                  _createdAt ?? DateTime.now()),
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
              const Divider(height: 1),

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
                        itemCount: sheet.items.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 72,
                        ),
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
                              color: Colors.red,
                              alignment: Alignment.centerRight,
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${item.date.month}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                    Text(
                                      '${item.date.day}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                item.payee,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    item.purpose,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payment,
                                        size: 14,
                                        color: Colors.grey[500],
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
                                ],
                              ),
                              trailing: Text(
                                FormattingUtils.formatCurrency(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () => _onEditItem(item),
                            ),
                          );
                        },
                      ),
              ),

              // フッター（合計と追加ボタン）
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '合計金額',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                FormattingUtils.formatCurrency(
                                    sheet.totalAmount),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          if (sheet.items.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${sheet.items.length}件',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
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