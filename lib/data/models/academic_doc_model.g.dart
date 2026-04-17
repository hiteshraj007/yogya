// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academic_doc_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AcademicDocModelAdapter extends TypeAdapter<AcademicDocModel> {
  @override
  final int typeId = 3;

  @override
  AcademicDocModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AcademicDocModel(
      id: fields[0] as String,
      docType: fields[1] as String,
      fileName: fields[2] as String,
      extractedText: fields[3] as String,
      board: fields[4] as String,
      year: fields[5] as String,
      aggregate: fields[6] as String,
      stream: fields[7] as String,
      confidence: fields[8] as double,
      isVerified: fields[9] as bool,
      uploadedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AcademicDocModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.docType)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.extractedText)
      ..writeByte(4)
      ..write(obj.board)
      ..writeByte(5)
      ..write(obj.year)
      ..writeByte(6)
      ..write(obj.aggregate)
      ..writeByte(7)
      ..write(obj.stream)
      ..writeByte(8)
      ..write(obj.confidence)
      ..writeByte(9)
      ..write(obj.isVerified)
      ..writeByte(10)
      ..write(obj.uploadedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicDocModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
