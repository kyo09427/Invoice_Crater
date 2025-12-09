// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_sheet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseSheetAdapter extends TypeAdapter<ExpenseSheet> {
  @override
  final int typeId = 1;

  @override
  ExpenseSheet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseSheet(
      id: fields[0] as String,
      title: fields[1] as String,
      applicantName: fields[2] as String,
      createdAt: fields[3] as DateTime,
      items: (fields[4] as List).cast<ExpenseItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseSheet obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.applicantName)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseSheetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
