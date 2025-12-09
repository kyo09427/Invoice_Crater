import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../application/providers/app_settings_provider.dart';
import '../../core/utils/formatting_utils.dart';
import '../../data/models/expense_item.dart';

class ExpenseItemEditBottomSheet extends ConsumerStatefulWidget {
  final ExpenseItem? item;

  const ExpenseItemEditBottomSheet({super.key, this.item});

  @override
  ConsumerState<ExpenseItemEditBottomSheet> createState() =>
      _ExpenseItemEditBottomSheetState();
}

class _ExpenseItemEditBottomSheetState
    extends ConsumerState<ExpenseItemEditBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  late TextEditingController _payeeController;
  late TextEditingController _purposeController;
  late String _paymentMethod;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _date = item?.date ?? DateTime.now();
    _payeeController = TextEditingController(text: item?.payee);
    _purposeController = TextEditingController(text: item?.purpose);
    _amountController =
        TextEditingController(text: item?.amount.toString() ?? '');
    _noteController = TextEditingController(text: item?.note);
    // Payment method will be set in didChangeDependencies or build when we have data
    // But we need a default.
    // _paymentMethod will be initialized in build if not set? No, state needs it.
    // We'll set a temporary default and update it from settings if it's new.
    _paymentMethod = item?.paymentMethod ?? ''; 
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettingsAsync = ref.watch(appSettingsProvider);

    return appSettingsAsync.when(
      data: (settings) {
        // Initialize payment method if empty (new item)
        if (_paymentMethod.isEmpty) {
          if (settings.paymentMethodCandidates.isNotEmpty) {
            _paymentMethod = settings.paymentMethodCandidates.first;
          } else {
            _paymentMethod = '現金'; // Fallback
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.item == null ? '明細追加' : '明細編集',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date
                  Row(
                    children: [
                      const Text('支払日: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _date = picked;
                            });
                          }
                        },
                        child: Text(FormattingUtils.formatDate(_date)),
                      ),
                    ],
                  ),
                  
                  // Payee
                  TextFormField(
                    controller: _payeeController,
                    decoration: const InputDecoration(labelText: '支払い先'),
                    validator: (value) =>
                        value == null || value.isEmpty ? '必須です' : null,
                  ),
                  
                  // Purpose
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(labelText: '目的・用途'),
                    validator: (value) =>
                        value == null || value.isEmpty ? '必須です' : null,
                  ),
                  
                  // Payment Method
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: '決済手段'),
                    items: settings.paymentMethodCandidates
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      }
                    },
                  ),
                  
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: '金額', suffixText: '円'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return '必須です';
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed <= 0) return '0より大きい整数を入力';
                      return null;
                    },
                  ),
                  
                  // Note
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: '備考 (任意)'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final newItem = ExpenseItem(
                              id: widget.item?.id ?? const Uuid().v4(),
                              date: _date,
                              payee: _payeeController.text,
                              purpose: _purposeController.text,
                              paymentMethod: _paymentMethod,
                              amount: int.parse(_amountController.text),
                              note: _noteController.text,
                            );
                            Navigator.pop(context, newItem);
                          }
                        },
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
