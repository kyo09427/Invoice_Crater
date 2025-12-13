import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // 🔧 修正: TextEditingControllerをStateとして管理
  late TextEditingController _defaultApplicantController;
  bool _isInitialized = false;

  @override
  void dispose() {
    _defaultApplicantController.dispose();
    super.dispose();
  }

  // 🔧 修正: 初回のみコントローラーを初期化
  void _initializeController(String defaultName) {
    if (_isInitialized) return;
    _defaultApplicantController = TextEditingController(text: defaultName);
    _isInitialized = true;
  }

  // 🔧 修正: デフォルト申請者名を保存
  Future<void> _saveDefaultApplicantName() async {
    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) return;

    final newName = _defaultApplicantController.text.trim();
    
    // 変更がない場合は保存しない
    if (newName == settings.defaultApplicantName) return;

    try {
      final newSettings = settings.copyWith(
        defaultApplicantName: newName,
      );
      await ref.read(appSettingsProvider.notifier).updateSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newName.isEmpty 
                ? 'デフォルト申請者名をクリアしました'
                : 'デフォルト申請者名を「$newName」に設定しました',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF137FEC);
    const backgroundLight = Color(0xFFFDFCFF);
    const backgroundDark = Color(0xFF1A1C1E);
    const surfaceLight = Color(0xFFFDFCFF);
    const surfaceDark = Color(0xFF1A1C1E);
    const surfaceVariantLight = Color(0xFFE1E2EC);
    const surfaceVariantDark = Color(0xFF44474F);
    const outlineLight = Color(0xFF74777F);
    const outlineDark = Color(0xFF8E9099);
    const textPrimaryLight = Color(0xFF1A1C1E);
    const textPrimaryDark = Color(0xFFE2E2E6);
    const textSecondaryLight = Color(0xFF44474F);
    const textSecondaryDark = Color(0xFFC4C6D0);

    return Scaffold(
      backgroundColor: isDark ? backgroundDark : backgroundLight,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? surfaceDark : surfaceLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        titleSpacing: 0,
        title: const Text(
          '設定',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          // 🔧 修正: 設定読み込み後にコントローラーを初期化
          _initializeController(settings.defaultApplicantName);

          final outlineColor = isDark ? outlineDark : outlineLight;
          final textPrimaryColor = isDark ? textPrimaryDark : textPrimaryLight;
          final textSecondaryColor =
              isDark ? textSecondaryDark : textSecondaryLight;
          final surfaceColor = isDark ? surfaceDark : surfaceLight;
          final surfaceVariantColor =
              isDark ? surfaceVariantDark : surfaceVariantLight;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // 基本設定
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '基本設定',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: outlineColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _defaultApplicantController,
                      decoration: InputDecoration(
                        labelText: 'デフォルト申請者名',
                        hintText: '例: 山田 太郎',
                        border: InputBorder.none,
                        // 🔧 追加: クリアボタン
                        suffixIcon: _defaultApplicantController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _defaultApplicantController.clear();
                                  _saveDefaultApplicantName();
                                },
                                tooltip: 'クリア',
                              )
                            : null,
                      ),
                      maxLength: 50,
                      textInputAction: TextInputAction.done,
                      // 🔧 修正: Enterキーで保存
                      onSubmitted: (_) => _saveDefaultApplicantName(),
                      // 🔧 追加: 変更時にSetStateでクリアボタンを更新
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    // 🔧 追加: 保存ボタン
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _saveDefaultApplicantName,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('保存'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                child: Text(
                  '新規作成時に、この名前が自動的に入力されます。Enterキーまたは「保存」ボタンで保存してください。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: textSecondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 決済手段の管理
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '決済手段の管理',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: surfaceVariantColor.withOpacity(0.7),
                  ),
                ),
                child: Column(
                  children: [
                    ...settings.paymentMethodCandidates.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final method = entry.value;
                        final isLast = index == settings.paymentMethodCandidates.length - 1;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: surfaceVariantColor.withOpacity(0.5),
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments,
                                size: 24,
                                color: textSecondaryColor,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  method,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textPrimaryColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: textSecondaryColor,
                                tooltip: '削除',
                                onPressed: () async {
                                  // 確認ダイアログ
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('決済手段を削除'),
                                      content: Text('「$method」を削除してもよろしいですか？'),
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

                                  if (confirmed == true) {
                                    final newList = List<String>.from(
                                      settings.paymentMethodCandidates,
                                    )..remove(method);
                                    
                                    final newSettings = settings.copyWith(
                                      paymentMethodCandidates: newList,
                                    );
                                    
                                    await ref
                                        .read(appSettingsProvider.notifier)
                                        .updateSettings(newSettings);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('「$method」を削除しました'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    // 追加ボタン
                    InkWell(
                      onTap: () async {
                        final controller = TextEditingController();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text('決済手段を追加'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: '例: PayPay',
                                  labelText: '決済手段名',
                                  border: OutlineInputBorder(),
                                ),
                                maxLength: 20,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (controller.text.trim().isNotEmpty) {
                                    Navigator.pop(dialogContext, true);
                                  }
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('キャンセル'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    if (controller.text.trim().isNotEmpty) {
                                      Navigator.pop(dialogContext, true);
                                    }
                                  },
                                  child: const Text('追加'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true && controller.text.trim().isNotEmpty) {
                          final newMethod = controller.text.trim();
                          
                          // 重複チェック
                          if (settings.paymentMethodCandidates.contains(newMethod)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('「$newMethod」は既に登録されています'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                            return;
                          }
                          
                          final newList = List<String>.from(
                            settings.paymentMethodCandidates,
                          )..add(newMethod);
                          
                          final newSettings = settings.copyWith(
                            paymentMethodCandidates: newList,
                          );
                          
                          await ref
                              .read(appSettingsProvider.notifier)
                              .updateSettings(newSettings);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('「$newMethod」を追加しました'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '新しい決済手段を追加',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  'よく使う項目を上に並び替えると、経費入力時の選択がスムーズになります。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: textSecondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 通知セクション
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '通知',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: surfaceVariantColor.withOpacity(0.7),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '申請締め切りのリマインド',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '締め切り3日前に通知します（予定）',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: false,
                      onChanged: null, // v1.3で実装予定
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // アプリ情報
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: surfaceVariantColor.withOpacity(0.4),
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: surfaceVariantColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '精算アプリ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'バージョン 1.1.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            '利用規約',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: textSecondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'プライバシーポリシー',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  color: Colors.red,
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
                FilledButton(
                  onPressed: () {
                    ref.invalidate(appSettingsProvider);
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}