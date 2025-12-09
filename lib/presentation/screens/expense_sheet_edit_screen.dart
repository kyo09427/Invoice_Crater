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

    // Load default applicant name if empty
    if (sheet.applicantName.isEmpty) {
      final settings = ref.read(appSettingsProvider).asData?.value;
      if (settings != null && settings.defaultApplicantName.isNotEmpty) {
        _applicantController.text = settings.defaultApplicantName;
        // Also update the sheet immediately? Maybe wait for user action.
        // Let's just prepopulate the UI.
      }
    }
  }

  Future<void> _updateSheet(ExpenseSheet sheet) async {
    await ref
        .read(expenseSheetProvider(widget.sheetId).notifier)
        .updateSheet(sheet);
  }

  void _onSaveHeader() {
    final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
    if (sheet == null) return;

    final newSheet = sheet.copyWith(
      title: _titleController.text,
      applicantName: _applicantController.text,
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
        _updateSheet(newSheet);
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
        _updateSheet(newSheet);
      }
    }
  }

  Future<void> _onDeleteItem(ExpenseItem item) async {
    final sheet = ref.read(expenseSheetProvider(widget.sheetId)).value;
    if (sheet != null) {
      final newItems = List<ExpenseItem>.from(sheet.items)
        ..removeWhere((e) => e.id == item.id);
      final newSheet = sheet.copyWith(items: newItems);
      _updateSheet(newSheet);
    }
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
            onPressed: () {
               // Update header before navigating just in case
               _onSaveHeader();
               Navigator.pushNamed(
                context,
                ExpensePdfPreviewScreen.routeName,
                arguments: widget.sheetId,
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
          _initializeControllers(sheet);

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: '精算書タイトル'),
                      onChanged: (_) => _onSaveHeader(),
                    ),
                    TextField(
                      controller: _applicantController,
                      decoration: const InputDecoration(labelText: '申請者名'),
                       onChanged: (_) => _onSaveHeader(),
                    ),
                    Row(
                      children: [
                        const Text('作成日: '),
                        TextButton(
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
                          child: Text(FormattingUtils.formatDate(
                              _createdAt ?? DateTime.now())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Items List
              Expanded(
                child: ListView.builder(
                  itemCount: sheet.items.length,
                  itemBuilder: (context, index) {
                    final item = sheet.items[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _onDeleteItem(item),
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${item.date.month}/${item.date.day}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        title: Text(item.payee),
                        subtitle: Text(item.purpose),
                        trailing: Text(FormattingUtils.formatCurrency(item.amount)),
                        onTap: () => _onEditItem(item),
                      ),
                    );
                  },
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('合計金額:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          FormattingUtils.formatCurrency(sheet.totalAmount),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
