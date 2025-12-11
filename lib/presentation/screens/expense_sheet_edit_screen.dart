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
          SnackBar(content: Text('保存に失敗しました: $e')),
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
      builder: (context) => const ExpenseItemEditBottomSheet(),
    );

    if (newItem != null) {
      final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
      if (sheet != null) {
        final newItems = List<ExpenseItem>.from(sheet.items)..add(newItem);
        final newSheet = sheet.copyWith(items: newItems);
        await _updateSheet(newSheet);
      }
    }
  }

  Future<void> _onEditItem(ExpenseItem item) async {
    final updatedItem = await showModalBottomSheet<ExpenseItem>(
      context: context,
      isScrollControlled: true,
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
      }
    }
  }

  Future<void> _onDeleteItem(ExpenseItem item) async {
    // 削除確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この明細を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
      if (sheet != null) {
        final newItems = List<ExpenseItem>.from(sheet.items)
          ..removeWhere((e) => e.id == item.id);
        final newSheet = sheet.copyWith(items: newItems);
        await _updateSheet(newSheet);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('明細を削除しました')),
          );
        }
      }
    }
  }

  void _onNavigateToPdf() {
    final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
    
    // バリデーション
    if (sheet == null) return;
    
    if (sheet.title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }
    
    if (sheet.applicantName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('申請者名を入力してください')),
      );
      return;
    }
    
    if (sheet.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('明細を1件以上追加してください')),
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
            return const Center(child: Text('精算書が見つかりません'));
          }
          _initializeControllers(sheet);

          return Column(
            children: [
              // ヘッダー情報入力
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '精算書タイトル',
                        hintText: '例: 11月度 生徒会精算書',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 100,
                      onChanged: (_) => _onSaveHeader(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _applicantController,
                      decoration: const InputDecoration(
                        labelText: '申請者名',
                        hintText: '例: 山田 太郎',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 50,
                      onChanged: (_) => _onSaveHeader(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('作成日: '),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            FormattingUtils.formatDate(_createdAt ?? DateTime.now()),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _createdAt ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _createdAt = picked;
                              });
                              _onSaveHeader();
                            }
                          },
                        ),
                      ],
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
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '明細がありません',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
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
                    : ListView.builder(
                        itemCount: sheet.items.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final item = sheet.items[index];
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('削除確認'),
                                  content: const Text('この明細を削除しますか？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text(
                                        '削除',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _onDeleteItem(item),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${item.date.month}/${item.date.day}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(item.payee),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.purpose),
                                  Text(
                                    item.paymentMethod,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                FormattingUtils.formatCurrency(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '合計金額:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          FormattingUtils.formatCurrency(sheet.totalAmount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onAddItem,
                        icon: const Icon(Icons.add),
                        label: const Text('明細を追加'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(expenseSheetProvider(widget.sheetId));
                },
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}