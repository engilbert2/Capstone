// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryItemAdapter extends TypeAdapter<CategoryItem> {
  @override
  final int typeId = 1;

  @override
  CategoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryItem(
      name: fields[0] as String,
      limit: fields[1] as double,
      icon: fields[2] as String,
      iconCodePoint: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.limit)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.iconCodePoint);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
