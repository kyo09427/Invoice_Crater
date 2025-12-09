import 'package:hive/hive.dart';

part 'expense_item.g.dart';

@HiveType(typeId: 0)
class ExpenseItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String payee;

  @HiveField(3)
  final String purpose;

  @HiveField(4)
  final String paymentMethod;

  @HiveField(5)
  final int amount;

  @HiveField(6)
  final String? note;

  ExpenseItem({
    required this.id,
    required this.date,
    required this.payee,
    required this.purpose,
    required this.paymentMethod,
    required this.amount,
    this.note,
  });

  ExpenseItem copyWith({
    String? id,
    DateTime? date,
    String? payee,
    String? purpose,
    String? paymentMethod,
    int? amount,
    String? note,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      date: date ?? this.date,
      payee: payee ?? this.payee,
      purpose: purpose ?? this.purpose,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }
}
