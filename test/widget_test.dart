import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:invoice_creater/main.dart';
import 'package:invoice_creater/data/models/expense_sheet.dart';
import 'package:invoice_creater/data/models/expense_item.dart';
import 'package:invoice_creater/data/models/app_settings.dart';

/// 基本的な統合テスト
/// 
/// 注: 本格的なテストを実行するには、以下のファイルを作成してください：
/// - test/models/expense_sheet_test.dart
/// - test/providers/expense_sheet_list_provider_test.dart
/// - test/widgets/expense_item_tile_test.dart
void main() {
  setUpAll(() async {
    // テスト用のHive初期化
    await Hive.initFlutter();
    
    // アダプターの登録
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExpenseSheetAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
  });

  tearDownAll(() async {
    // テスト終了後のクリーンアップ
    await Hive.deleteFromDisk();
    await Hive.close();
  });

  testWidgets('App starts and shows home screen', (WidgetTester tester) async {
    // テスト用のボックスを開く
    final expenseBox = await Hive.openBox<ExpenseSheet>('test_expenses');
    final settingsBox = await Hive.openBox<AppSettings>('test_settings');

    try {
      // アプリをビルド
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // テスト用のボックスを注入
          ],
          child: const InvoiceCreatorApp(),
        ),
      );

      // 初期フレームを待つ
      await tester.pumpAndSettle();

      // ホーム画面のタイトルが表示されているか確認
      expect(find.text('ホーム'), findsOneWidget);

      // FABが表示されているか確認
      expect(find.byType(FloatingActionButton), findsOneWidget);
      
      // 空状態のメッセージが表示されているか確認
      // （初期状態では精算書がないため）
      expect(
        find.textContaining('精算書がありません'),
        findsOneWidget,
      );
    } finally {
      // テスト後のクリーンアップ
      await expenseBox.clear();
      await expenseBox.close();
      await settingsBox.clear();
      await settingsBox.close();
    }
  });

  testWidgets('Navigation to settings works', (WidgetTester tester) async {
    final expenseBox = await Hive.openBox<ExpenseSheet>('test_expenses_2');
    final settingsBox = await Hive.openBox<AppSettings>('test_settings_2');

    try {
      await tester.pumpWidget(
        ProviderScope(
          child: const InvoiceCreatorApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 設定アイコンをタップ
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
      
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // 設定画面のタイトルが表示されているか確認
      expect(find.text('設定'), findsOneWidget);
    } finally {
      await expenseBox.clear();
      await expenseBox.close();
      await settingsBox.clear();
      await settingsBox.close();
    }
  });

  group('ExpenseSheet model tests', () {
    test('totalAmount calculates correctly', () {
      final items = [
        ExpenseItem(
          id: '1',
          date: DateTime.now(),
          payee: 'Store A',
          purpose: 'Supplies',
          paymentMethod: 'Cash',
          amount: 1000,
        ),
        ExpenseItem(
          id: '2',
          date: DateTime.now(),
          payee: 'Store B',
          purpose: 'Food',
          paymentMethod: 'Card',
          amount: 2500,
        ),
      ];

      final sheet = ExpenseSheet(
        id: 'test',
        title: 'Test Sheet',
        applicantName: 'Tester',
        createdAt: DateTime.now(),
        items: items,
      );

      expect(sheet.totalAmount, equals(3500));
    });

    test('totalAmount is zero when no items', () {
      final sheet = ExpenseSheet(
        id: 'test',
        title: 'Test Sheet',
        applicantName: 'Tester',
        createdAt: DateTime.now(),
        items: [],
      );

      expect(sheet.totalAmount, equals(0));
    });

    test('copyWith creates a new instance with updated values', () {
      final original = ExpenseSheet(
        id: 'test',
        title: 'Original Title',
        applicantName: 'Original Name',
        createdAt: DateTime.now(),
        items: [],
      );

      final copied = original.copyWith(title: 'New Title');

      expect(copied.title, equals('New Title'));
      expect(copied.applicantName, equals('Original Name'));
      expect(copied.id, equals(original.id));
    });
  });

  group('AppSettings model tests', () {
    test('initial creates default settings', () {
      final settings = AppSettings.initial();

      expect(settings.defaultApplicantName, equals(''));
      expect(settings.paymentMethodCandidates, isNotEmpty);
      expect(
        settings.paymentMethodCandidates,
        containsAll(['現金', 'Suica', 'd払い']),
      );
    });

    test('copyWith updates payment methods', () {
      final original = AppSettings.initial();
      final newMethods = ['現金', 'PayPay', 'LINE Pay'];
      final updated = original.copyWith(
        paymentMethodCandidates: newMethods,
      );

      expect(updated.paymentMethodCandidates, equals(newMethods));
      expect(
        updated.defaultApplicantName,
        equals(original.defaultApplicantName),
      );
    });
  });
}

/// サンプルテストデータ生成用ヘルパー
class TestDataHelper {
  static ExpenseSheet createSampleSheet({
    String? id,
    String? title,
    int itemCount = 3,
  }) {
    return ExpenseSheet(
      id: id ?? 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Sample Expense Sheet',
      applicantName: 'Test User',
      createdAt: DateTime.now(),
      items: List.generate(
        itemCount,
        (index) => ExpenseItem(
          id: 'item_$index',
          date: DateTime.now().subtract(Duration(days: index)),
          payee: 'Payee $index',
          purpose: 'Purpose $index',
          paymentMethod: '現金',
          amount: (index + 1) * 1000,
        ),
      ),
    );
  }

  static ExpenseItem createSampleItem({
    String? id,
    int? amount,
  }) {
    return ExpenseItem(
      id: id ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      payee: 'Test Payee',
      purpose: 'Test Purpose',
      paymentMethod: '現金',
      amount: amount ?? 1000,
    );
  }
}