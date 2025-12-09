import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_sheet.dart';
import 'core_providers.dart';

final expenseSheetListProvider = AsyncNotifierProvider<ExpenseSheetListNotifier, List<ExpenseSheet>>(ExpenseSheetListNotifier.new);

class ExpenseSheetListNotifier extends AsyncNotifier<List<ExpenseSheet>> {
  @override
  Future<List<ExpenseSheet>> build() async {
    final dataSource = ref.watch(expenseSheetDataSourceProvider);
    return dataSource.getAll();
  }

  Future<void> addSheet(ExpenseSheet sheet) async {
    final dataSource = ref.read(expenseSheetDataSourceProvider);
    await dataSource.save(sheet);
    // Invalidate self to reload the list
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteSheet(String id) async {
    final dataSource = ref.read(expenseSheetDataSourceProvider);
    await dataSource.delete(id);
    ref.invalidateSelf();
    await future;
  }
}
