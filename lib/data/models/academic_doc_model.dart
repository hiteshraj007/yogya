import 'package:hive_flutter/hive_flutter.dart';

part 'academic_doc_model.g.dart';

@HiveType(typeId: 3)
class AcademicDocModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String docType; // '10th', '12th', 'graduation', 'admit_card'

  @HiveField(2)
  String fileName;

  @HiveField(3)
  String extractedText;

  @HiveField(4)
  String board;

  @HiveField(5)
  String year;

  @HiveField(6)
  String aggregate;

  @HiveField(7)
  String stream;

  @HiveField(8)
  double confidence;

  @HiveField(9)
  bool isVerified;

  @HiveField(10)
  DateTime uploadedAt;

  AcademicDocModel({
    required this.id,
    required this.docType,
    this.fileName = '',
    this.extractedText = '',
    this.board = '',
    this.year = '',
    this.aggregate = '',
    this.stream = '',
    this.confidence = 0.0,
    this.isVerified = false,
    required this.uploadedAt,
  });
}