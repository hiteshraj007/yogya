import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile_model.dart';
import '../models/academic_doc_model.dart';
import '../models/eligibility_result_model.dart';

class HiveService {
  // Box names
  static const String _userBox        = 'userProfile';
  static const String _docsBox        = 'academicDocs';
  static const String _eligibilityBox = 'eligibilityResults';

  // ── Initialize ──────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();

    // Adapters register karo
    Hive.registerAdapter(UserProfileModelAdapter());
    Hive.registerAdapter(AcademicDocModelAdapter());
    Hive.registerAdapter(EligibilityResultModelAdapter());

    // Boxes open karo (with safety for schema changes)
    try {
      await Hive.openBox<UserProfileModel>(_userBox);
    } catch (e) {
      // Agar schema mismatch hota hai toh box delete karke naya banao
      await Hive.deleteBoxFromDisk(_userBox);
      await Hive.openBox<UserProfileModel>(_userBox);
    }

    try {
      await Hive.openBox<AcademicDocModel>(_docsBox);
    } catch (e) {
      await Hive.deleteBoxFromDisk(_docsBox);
      await Hive.openBox<AcademicDocModel>(_docsBox);
    }

    try {
      await Hive.openBox<EligibilityResultModel>(_eligibilityBox);
    } catch (e) {
      await Hive.deleteBoxFromDisk(_eligibilityBox);
      await Hive.openBox<EligibilityResultModel>(_eligibilityBox);
    }
  }

  // ── UserProfile CRUD ─────────────────────────────────────
  static Box<UserProfileModel> get _userProfileBox =>
      Hive.box<UserProfileModel>(_userBox);

  static Future<void> saveUserProfile(UserProfileModel profile) async {
    await _userProfileBox.put(profile.id, profile);
  }

  static UserProfileModel? getUserProfile(String uid) {
    return _userProfileBox.get(uid);
  }

  static Future<void> deleteUserProfile(String uid) async {
    await _userProfileBox.delete(uid);
  }

  // ── AcademicDoc CRUD ─────────────────────────────────────
  static Box<AcademicDocModel> get _academicDocsBox =>
      Hive.box<AcademicDocModel>(_docsBox);

  static Future<void> saveDoc(AcademicDocModel doc) async {
    await _academicDocsBox.put(doc.id, doc);
  }

  static List<AcademicDocModel> getAllDocs() {
    return _academicDocsBox.values.toList();
  }

  static AcademicDocModel? getDoc(String id) {
    return _academicDocsBox.get(id);
  }

  static Future<void> deleteDoc(String id) async {
    await _academicDocsBox.delete(id);
  }

  // ── EligibilityResult CRUD ───────────────────────────────
  static Box<EligibilityResultModel> get _eligibilityBox2 =>
      Hive.box<EligibilityResultModel>(_eligibilityBox);

  static Future<void> saveEligibilityResult(
      EligibilityResultModel result) async {
    await _eligibilityBox2.put(result.examId, result);
  }

  static List<EligibilityResultModel> getAllEligibilityResults() {
    return _eligibilityBox2.values.toList();
  }

  static Future<void> clearEligibilityResults() async {
    await _eligibilityBox2.clear();
  }
}