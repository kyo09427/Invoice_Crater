// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseItemAdapter extends TypeAdapter<ExpenseItem> {
  @override
  final int typeId = 0;

  @override
  ExpenseItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseItem(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      payee: fields[2] as String,
      purpose: fields[3] as String,
      paymentMethod: fields[4] as String,
      amount: fields[5] as int,
      note: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.payee)
      ..writeByte(3)
      ..write(obj.purpose)
      ..writeByte(4)
      ..write(obj.paymentMethod)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
