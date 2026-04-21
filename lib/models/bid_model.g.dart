// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bid_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RequirementAdapter extends TypeAdapter<Requirement> {
  @override
  final int typeId = 0;

  @override
  Requirement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Requirement(
      name: fields[0] as String,
      isUploaded: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Requirement obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.isUploaded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequirementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BidAdapter extends TypeAdapter<Bid> {
  @override
  final int typeId = 1;

  @override
  Bid read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bid(
      title: fields[0] as String,
      deadline: fields[1] as DateTime,
      requirements: (fields[2] as List).cast<Requirement>(),
      reminderMinutesBefore: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Bid obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.deadline)
      ..writeByte(2)
      ..write(obj.requirements)
      ..writeByte(3)
      ..write(obj.reminderMinutesBefore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BidAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
