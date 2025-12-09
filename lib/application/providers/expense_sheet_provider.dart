import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_sheet.dart';
import 'core_providers.dart';
import 'expense_sheet_list_provider.dart';

final expenseSheetProvider = AsyncNotifierProvider.family<ExpenseSheetNotifier, ExpenseSheet?, String>(() => ExpenseSheetNotifier());

class ExpenseSheetNotifier extends FamilyAsyncNotifier<ExpenseSheet?, String> {
  @override
  Future<ExpenseSheet?> build(String arg) async {
    final dataSource = ref.watch(expenseSheetDataSourceProvider);
    return dataSource.getById(arg);
  }

  Future<void> updateSheet(ExpenseSheet sheet) async {
    final dataSource = ref.read(expenseSheetDataSourceProvider);
    await dataSource.save(sheet);
    
    // Invalidate self
    ref.invalidateSelf();
    
    // Also invalidate the list provider so it reflects the changes (e.g. title change, total amount change)
    ref.invalidate(expenseSheetListProvider);
    
    await future;
  }
}
