import 'package:hive/hive.dart';
import '../models/expense_sheet.dart';

class HiveExpenseSheetDataSource {
  final Box<ExpenseSheet> box;

  HiveExpenseSheetDataSource(this.box);

  Future<List<ExpenseSheet>> getAll() async {
    return box.values.toList();
  }

  Future<ExpenseSheet?> getById(String id) async {
    return box.get(id);
  }

  Future<void> save(ExpenseSheet sheet) async {
    await box.put(sheet.id, sheet);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }
}
