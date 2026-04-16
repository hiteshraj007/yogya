import 'package:hive_flutter/hive_flutter.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 0)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String category;

  @HiveField(4)
  String gender;

  @HiveField(5)
  String dateOfBirth;

  @HiveField(6)
  String qualification;

  @HiveField(7)
  String university;

  @HiveField(8)
  String passingYear;

  @HiveField(9)
  String percentage;

  @HiveField(10)
  String phone;

  @HiveField(11)
  int profileCompletion;

  @HiveField(12)
  String stateOfDomicile;

  @HiveField(13)
  String primaryExamGoal;

  @HiveField(14)
  bool isVerified;

  @HiveField(15)
  double confidenceLevel;

  @HiveField(16)
  String graduationStatus; // "Pursuing" or "Completed"

  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.category        = 'General',
    this.gender          = 'Male',
    this.dateOfBirth     = '',
    this.qualification   = '',
    this.university      = '',
    this.passingYear     = '',
    this.percentage      = '',
    this.phone           = '',
    this.profileCompletion = 0,
    this.stateOfDomicile = '',
    this.primaryExamGoal = '',
    this.isVerified      = false,
    this.confidenceLevel = 0.0,
    this.graduationStatus = '',
  });

  // Profile completion calculate karo
  int calculateCompletion() {
    int filled = 0;
    if (name.isNotEmpty)          filled++;
    if (email.isNotEmpty)         filled++;
    if (dateOfBirth.isNotEmpty)   filled++;
    if (qualification.isNotEmpty) filled++;
    if (university.isNotEmpty)    filled++;
    if (passingYear.isNotEmpty)   filled++;
    if (percentage.isNotEmpty)    filled++;
    if (phone.isNotEmpty)         filled++;
    if (stateOfDomicile.isNotEmpty) filled++;
    if (primaryExamGoal.isNotEmpty) filled++;
    return ((filled / 10) * 100).round();
  }
}