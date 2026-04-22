import 'package:hive_flutter/hive_flutter.dart';
import '../remote/firestore_sync_service.dart';
import '../models/user_profile_model.dart';
import '../models/academic_doc_model.dart';
import '../models/eligibility_result_model.dart';

class HiveService {
  // Box names
  static const String _userBox = 'userProfile';
  static const String _docsBox = 'academicDocs';
  static const String _eligibilityBox = 'eligibilityResults';
  static const String _attemptHistoryBox = 'attemptHistory';

  // ── Initialize ──────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters safely (avoid duplicate registration crash)
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserProfileModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(EligibilityResultModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AcademicDocModelAdapter());
    }

    await _openUserBoxSafe();
    await _openDocsBoxSafe();
    await _openEligibilityBoxSafe();

    if (!Hive.isBoxOpen(_attemptHistoryBox)) {
      await Hive.openBox(_attemptHistoryBox);
    }
  }

  static Future<void> _openUserBoxSafe() async {
    if (Hive.isBoxOpen(_userBox)) return;
    try {
      await Hive.openBox<UserProfileModel>(_userBox);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_userBox);
      await Hive.openBox<UserProfileModel>(_userBox);
    }
  }

  static Future<void> _openDocsBoxSafe() async {
    if (Hive.isBoxOpen(_docsBox)) return;
    try {
      await Hive.openBox<AcademicDocModel>(_docsBox);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_docsBox);
      await Hive.openBox<AcademicDocModel>(_docsBox);
    }
  }

  static Future<void> _openEligibilityBoxSafe() async {
    if (Hive.isBoxOpen(_eligibilityBox)) return;
    try {
      await Hive.openBox<EligibilityResultModel>(_eligibilityBox);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_eligibilityBox);
      await Hive.openBox<EligibilityResultModel>(_eligibilityBox);
    }
  }

  // ── UserProfile CRUD ─────────────────────────────────────
  static Box<UserProfileModel> get _userProfileBox =>
      Hive.box<UserProfileModel>(_userBox);

  static Future<void> saveUserProfile(UserProfileModel profile) async {
    await _openUserBoxSafe();
    await _userProfileBox.put(profile.id, profile);
    await FirestoreSyncService.syncProfileToCloud(profile.id, profile);
  }

  static Future<void> saveUserProfileOnlyLocal(UserProfileModel profile) async {
    await _openUserBoxSafe();
    await _userProfileBox.put(profile.id, profile);
  }

  static UserProfileModel? getUserProfile(String uid) {
    if (!Hive.isBoxOpen(_userBox)) return null;
    return _userProfileBox.get(uid);
  }

  static Future<void> deleteUserProfile(String uid) async {
    await _openUserBoxSafe();
    await _userProfileBox.delete(uid);
  }

  // ── AcademicDoc CRUD ─────────────────────────────────────
  static Box<AcademicDocModel> get _academicDocsBox =>
      Hive.box<AcademicDocModel>(_docsBox);

  static Future<void> saveDoc(AcademicDocModel doc, {String? uid}) async {
    await _openDocsBoxSafe();
    final key = uid != null ? '${uid}_${doc.id}' : doc.id;
    await _academicDocsBox.put(key, doc);
    if (uid != null) {
      await FirestoreSyncService.syncDocToCloud(uid, doc);
    }
  }

  static Future<void> saveDocOnlyLocal(AcademicDocModel doc, {String? uid}) async {
    await _openDocsBoxSafe();
    final key = uid != null ? '${uid}_${doc.id}' : doc.id;
    await _academicDocsBox.put(key, doc);
  }

  static List<AcademicDocModel> getAllDocs({String? uid}) {
    if (!Hive.isBoxOpen(_docsBox)) return [];
    if (uid == null) return _academicDocsBox.values.toList();
    return _academicDocsBox.toMap().entries
        .where((e) => e.key.toString().startsWith('${uid}_'))
        .map((e) => e.value)
        .toList();
  }

  static AcademicDocModel? getDoc(String id, {String? uid}) {
    if (!Hive.isBoxOpen(_docsBox)) return null;
    final key = uid != null ? '${uid}_$id' : id;
    return _academicDocsBox.get(key);
  }

  static Future<void> deleteDoc(String id, {String? uid}) async {
    await _openDocsBoxSafe();
    final key = uid != null ? '${uid}_$id' : id;
    await _academicDocsBox.delete(key);
    if (uid != null) {
      await FirestoreSyncService.deleteDocFromCloud(uid, id);
    }
  }

  // ── EligibilityResult CRUD ───────────────────────────────
  static Box<EligibilityResultModel> get _eligibilityBox2 =>
      Hive.box<EligibilityResultModel>(_eligibilityBox);

  static Future<void> saveEligibilityResult(
      EligibilityResultModel result, {String? uid}) async {
    await _openEligibilityBoxSafe();
    final key = uid != null ? '${uid}_${result.examId}' : result.examId;
    await _eligibilityBox2.put(key, result);
  }

  static List<EligibilityResultModel> getAllEligibilityResults({String? uid}) {
    if (!Hive.isBoxOpen(_eligibilityBox)) return [];
    if (uid == null) return _eligibilityBox2.values.toList();
    return _eligibilityBox2.toMap().entries
        .where((e) => e.key.toString().startsWith('${uid}_'))
        .map((e) => e.value)
        .toList();
  }

  static Future<void> clearEligibilityResults() async {
    await _openEligibilityBoxSafe();
    await _eligibilityBox2.clear();
  }

  // ── Session Wipe ─────────────────────────────────────────
  static Future<void> clearUserSessionData() async {
    // We clear docs, eligibility, and attempts.
    // We DO NOT clear the entire _userBox so that if someone logs in 
    // with an old account, their profile is still locally cached.
    if (Hive.isBoxOpen(_docsBox)) await _academicDocsBox.clear();
    if (Hive.isBoxOpen(_eligibilityBox)) await _eligibilityBox2.clear();
    if (Hive.isBoxOpen(_attemptHistoryBox)) await Hive.box(_attemptHistoryBox).clear();
  }
}