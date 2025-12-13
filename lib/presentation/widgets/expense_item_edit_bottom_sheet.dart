import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _amountFocusNode = FocusNode();

  late DateTime _date;
  late TextEditingController _payeeController;
  late TextEditingController _purposeController;
  late String _paymentMethod;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _date = item?.date ?? DateTime.now();
    _payeeController = TextEditingController(text: item?.payee);
    _purposeController = TextEditingController(text: item?.purpose);
    _amountController = TextEditingController(
      text: item?.amount.toString() ?? '',
    );
    _noteController = TextEditingController(text: item?.note);
    _paymentMethod = item?.paymentMethod ?? '';
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _initializePaymentMethod(List<String> candidates) {
    if (_isInitialized) return;
    
    if (_paymentMethod.isEmpty && candidates.isNotEmpty) {
      _paymentMethod = candidates.first;
    } else if (_paymentMethod.isEmpty) {
      _paymentMethod = '現金';
    }
    
    _isInitialized = true;
  }

  // 🔧 修正: 支払日選択を独立したメソッドに
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      // localeパラメータを削除（不要）
    );
    
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payee = _payeeController.text.trim();
    final purpose = _purposeController.text.trim();
    final amountStr = _amountController.text.trim();
    final note = _noteController.text.trim();

    if (payee.isEmpty || purpose.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('必須項目を入力してください')),
      );
      return;
    }

    final amount = int.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金額は1以上の整数を入力してください')),
      );
      return;
    }

    final newItem = ExpenseItem(
      id: widget.item?.id ?? const Uuid().v4(),
      date: _date,
      payee: payee,
      purpose: purpose,
      paymentMethod: _paymentMethod,
      amount: amount,
      note: note.isEmpty ? null : note,
    );

    Navigator.pop(context, newItem);
  }

  @override
  Widget build(BuildContext context) {
    final appSettingsAsync = ref.watch(appSettingsProvider);

    return appSettingsAsync.when(
      data: (settings) {
        _initializePaymentMethod(settings.paymentMethodCandidates);

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
                  // ヘッダー
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item == null ? '明細追加' : '明細編集',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🔧 修正: 支払日選択をGestureDetectorに変更
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '支払日',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FormattingUtils.formatDate(_date),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 支払い先
                  TextFormField(
                    controller: _payeeController,
                    decoration: const InputDecoration(
                      labelText: '支払い先 *',
                      hintText: '例: ○○商店',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    maxLength: 100,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '支払い先を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 目的・用途
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: '目的・用途 *',
                      hintText: '例: 文房具購入',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLength: 200,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '目的・用途を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 決済手段
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: '決済手段 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: settings.paymentMethodCandidates
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '決済手段を選択してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 金額
                  TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    decoration: const InputDecoration(
                      labelText: '金額 *',
                      hintText: '1000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments),
                      suffixText: '円',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '金額を入力してください';
                      }
                      final amount = int.tryParse(value);
                      if (amount == null) {
                        return '有効な数値を入力してください';
                      }
                      if (amount <= 0) {
                        return '1円以上の金額を入力してください';
                      }
                      if (amount > 999999999) {
                        return '金額が大きすぎます';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 備考（任意）
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: '備考（任意）',
                      hintText: '追加情報があれば入力してください',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLength: 500,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onSave(),
                  ),
                  const SizedBox(height: 24),

                  // ボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _onSave,
                        icon: const Icon(Icons.check),
                        label: const Text('保存'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
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
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('設定の読み込みに失敗しました: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}