// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 1;

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
      phone: fields[6] as String,
      profileCompletion: fields[7] as int,
      stateOfDomicile: fields[8] as String,
      primaryExamGoal: fields[9] as String,
      isVerified: fields[10] as bool,
      confidenceLevel: fields[11] as double,
      tenthBoard: fields[12] as String,
      tenthYear: fields[13] as String,
      tenthPercentage: fields[14] as String,
      twelfthBoard: fields[15] as String,
      twelfthYear: fields[16] as String,
      twelfthPercentage: fields[17] as String,
      gradCourse: fields[18] as String,
      gradUniversity: fields[19] as String,
      gradYear: fields[20] as String,
      gradPercentage: fields[21] as String,
      graduationStatus: fields[22] as String,
      qualification: fields[23] as String,
      university: fields[24] as String,
      passingYear: fields[25] as String,
      percentage: fields[26] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(27)
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
      ..write(obj.phone)
      ..writeByte(7)
      ..write(obj.profileCompletion)
      ..writeByte(8)
      ..write(obj.stateOfDomicile)
      ..writeByte(9)
      ..write(obj.primaryExamGoal)
      ..writeByte(10)
      ..write(obj.isVerified)
      ..writeByte(11)
      ..write(obj.confidenceLevel)
      ..writeByte(12)
      ..write(obj.tenthBoard)
      ..writeByte(13)
      ..write(obj.tenthYear)
      ..writeByte(14)
      ..write(obj.tenthPercentage)
      ..writeByte(15)
      ..write(obj.twelfthBoard)
      ..writeByte(16)
      ..write(obj.twelfthYear)
      ..writeByte(17)
      ..write(obj.twelfthPercentage)
      ..writeByte(18)
      ..write(obj.gradCourse)
      ..writeByte(19)
      ..write(obj.gradUniversity)
      ..writeByte(20)
      ..write(obj.gradYear)
      ..writeByte(21)
      ..write(obj.gradPercentage)
      ..writeByte(22)
      ..write(obj.graduationStatus)
      ..writeByte(23)
      ..write(obj.qualification)
      ..writeByte(24)
      ..write(obj.university)
      ..writeByte(25)
      ..write(obj.passingYear)
      ..writeByte(26)
      ..write(obj.percentage);
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
