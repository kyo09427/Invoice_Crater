import 'package:hive/hive.dart';
import 'expense_item.dart';

part 'expense_sheet.g.dart';

@HiveType(typeId: 1)
class ExpenseSheet {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String applicantName;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final List<ExpenseItem> items;

  ExpenseSheet({
    required this.id,
    required this.title,
    required this.applicantName,
    required this.createdAt,
    required this.items,
  });

  int get totalAmount => items.fold(0, (sum, item) => sum + item.amount);

  ExpenseSheet copyWith({
    String? id,
    String? title,
    String? applicantName,
    DateTime? createdAt,
    List<ExpenseItem>? items,
  }) {
    return ExpenseSheet(
      id: id ?? this.id,
      title: title ?? this.title,
      applicantName: applicantName ?? this.applicantName,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
