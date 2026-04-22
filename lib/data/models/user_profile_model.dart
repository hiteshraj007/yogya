import 'package:hive_flutter/hive_flutter.dart';
part 'user_profile_model.g.dart';

@HiveType(typeId: 1)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  String id;
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
  String phone;
  @HiveField(7)
  int profileCompletion;
  @HiveField(8)
  String stateOfDomicile;
  @HiveField(9)
  String primaryExamGoal;
  @HiveField(10)
  bool isVerified;
  @HiveField(11)
  double confidenceLevel;

  // --- 10th Info (Base for Name & DOB) ---
  @HiveField(12)
  String tenthBoard;
  @HiveField(13)
  String tenthYear;
  @HiveField(14)
  String tenthPercentage;

  // --- 12th Info ---
  @HiveField(15)
  String twelfthBoard;
  @HiveField(16)
  String twelfthYear;
  @HiveField(17)
  String twelfthPercentage;

  // --- Graduation Info ---
  @HiveField(18)
  String gradCourse;
  @HiveField(19)
  String gradUniversity;
  @HiveField(20)
  String gradYear;
  @HiveField(21)
  String gradPercentage;
  @HiveField(22)
  String graduationStatus;

  // Backward compatibility fields
  @HiveField(23)
  String qualification;
  @HiveField(24)
  String university;
  @HiveField(25)
  String passingYear;
  @HiveField(26)
  String percentage;

  UserProfileModel({
    required this.id,
    this.name = '',
    this.email = '',
    this.category = 'General',
    this.gender = 'Male',
    this.dateOfBirth = '',
    this.phone = '',
    this.profileCompletion = 0,
    this.stateOfDomicile = '',
    this.primaryExamGoal = '',
    this.isVerified = false,
    this.confidenceLevel = 0.0,
    this.tenthBoard = '',
    this.tenthYear = '',
    this.tenthPercentage = '',
    this.twelfthBoard = '',
    this.twelfthYear = '',
    this.twelfthPercentage = '',
    this.gradCourse = '',
    this.gradUniversity = '',
    this.gradYear = '',
    this.gradPercentage = '',
    this.graduationStatus = '',
    this.qualification = '',
    this.university = '',
    this.passingYear = '',
    this.percentage = '',
  });

  int calculateCompletion() {
    int score = 0;
    if (name.isNotEmpty) score += 15;
    if (email.isNotEmpty) score += 10;
    if (phone.isNotEmpty) score += 10;
    if (dateOfBirth.isNotEmpty) score += 15;
    if (stateOfDomicile.isNotEmpty) score += 10;
    if (primaryExamGoal.isNotEmpty) score += 10;

    // Academic Progress (Max 30)
    if (tenthBoard.isNotEmpty) score += 10;
    if (twelfthBoard.isNotEmpty) score += 10;
    if (gradCourse.isNotEmpty) score += 10;

    return score.clamp(0, 100);
  }
}
