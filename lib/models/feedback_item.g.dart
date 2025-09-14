// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedbackItemAdapter extends TypeAdapter<FeedbackItem> {
  @override
  final int typeId = 3;

  @override
  FeedbackItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedbackItem(
      id: fields[0] as String,
      userId: fields[1] as String,
      userName: fields[2] as String,
      message: fields[3] as String,
      createdAt: fields[4] as DateTime,
      isRead: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FeedbackItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
