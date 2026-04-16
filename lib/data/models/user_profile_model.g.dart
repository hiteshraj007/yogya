// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 0;

  @override
  UserProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      category: fields[3] as String,
      gender: fields[4] as String,
      dateOfBirth: fields[5] as String,
      qualification: fields[6] as String,
      university: fields[7] as String,
      passingYear: fields[8] as String,
      percentage: fields[9] as String,
      phone: fields[10] as String,
      profileCompletion: fields[11] as int,
      stateOfDomicile: fields[12] as String,
      primaryExamGoal: fields[13] as String,
      isVerified: fields[14] as bool,
      confidenceLevel: fields[15] as double,
      graduationStatus: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.dateOfBirth)
      ..writeByte(6)
      ..write(obj.qualification)
      ..writeByte(7)
      ..write(obj.university)
      ..writeByte(8)
      ..write(obj.passingYear)
      ..writeByte(9)
      ..write(obj.percentage)
      ..writeByte(10)
      ..write(obj.phone)
      ..writeByte(11)
      ..write(obj.profileCompletion)
      ..writeByte(12)
      ..write(obj.stateOfDomicile)
      ..writeByte(13)
      ..write(obj.primaryExamGoal)
      ..writeByte(14)
      ..write(obj.isVerified)
      ..writeByte(15)
      ..write(obj.confidenceLevel)
      ..writeByte(16)
      ..write(obj.graduationStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
