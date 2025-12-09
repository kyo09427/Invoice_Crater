import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          final defaultApplicantController = TextEditingController(text: settings.defaultApplicantName);
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('基本設定', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: defaultApplicantController,
                decoration: const InputDecoration(
                  labelText: 'デフォルト申請者名',
                  hintText: '例: 山田 太郎',
                ),
                onSubmitted: (value) async {
                   final newSettings = settings.copyWith(defaultApplicantName: value);
                   await ref.read(appSettingsProvider.notifier).updateSettings(newSettings);
                },
              ),
              const SizedBox(height: 24),
              const Text('決済手段の管理', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...settings.paymentMethodCandidates.map((method) => ListTile(
                title: Text(method),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final newList = List<String>.from(settings.paymentMethodCandidates)..remove(method);
                    final newSettings = settings.copyWith(paymentMethodCandidates: newList);
                    await ref.read(appSettingsProvider.notifier).updateSettings(newSettings);
                  },
                ),
              )),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('決済手段を追加'),
                onTap: () async {
                  final controller = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('決済手段を追加'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: '例: PayPay'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (controller.text.isNotEmpty) {
                              final newList = List<String>.from(settings.paymentMethodCandidates)..add(controller.text);
                                final newSettings = settings.copyWith(paymentMethodCandidates: newList);
                                await ref.read(appSettingsProvider.notifier).updateSettings(newSettings);
                                if (context.mounted) Navigator.pop(context);
                            }
                          },
                          child: const Text('追加'),
                        ),
                      ],
                    ),
                  );
                },
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
