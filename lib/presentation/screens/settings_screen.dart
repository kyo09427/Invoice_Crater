import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final defaultApplicantController =
              TextEditingController(text: settings.defaultApplicantName);

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: defaultApplicantController,
                      decoration: const InputDecoration(
                        labelText: 'デフォルト申請者名',
                        hintText: '例: 山田 太郎',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) async {
                        final newSettings = settings.copyWith(
                          defaultApplicantName: value,
                        );
                        await ref
                            .read(appSettingsProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                child: Text(
                  '新規作成時に、この名前が自動的に入力されます。',
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
                  TextButton(
                    onPressed: () {
                      // 編集ボタン（現在は見た目だけ）
                    },
                    child: const Text('編集'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: surfaceVariantColor.withOpacity(0.7)),
                ),
                child: Column(
                  children: [
                    ...settings.paymentMethodCandidates.map(
                      (method) => InkWell(
                        onTap: () {
                          // タップ時の挙動は必要なら後で追加
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
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
                                onPressed: () async {
                                  final newList = List<String>.from(
                                    settings.paymentMethodCandidates,
                                  )..remove(method);
                                  final newSettings = settings.copyWith(
                                    paymentMethodCandidates: newList,
                                  );
                                  await ref
                                      .read(appSettingsProvider.notifier)
                                      .updateSettings(newSettings);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final controller = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text('決済手段を追加'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: '例: PayPay',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (controller.text.isNotEmpty) {
                                      final newList = List<String>.from(
                                        settings.paymentMethodCandidates,
                                      )..add(controller.text);
                                      final newSettings = settings.copyWith(
                                        paymentMethodCandidates: newList,
                                      );
                                      await ref
                                          .read(appSettingsProvider.notifier)
                                          .updateSettings(newSettings);
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                    }
                                  },
                                  child: const Text('追加'),
                                ),
                              ],
                            );
                          },
                        );
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
                  border:
                      Border.all(color: surfaceVariantColor.withOpacity(0.7)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            '締め切り3日前に通知します',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: true,
                      onChanged: (_) {
                        // 現状、設定値とは連携していないダミーのスイッチ
                      },
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
                      'バージョン 2.4.0',
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
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
