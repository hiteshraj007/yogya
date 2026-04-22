import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/academic_doc_model.dart';
import '../models/user_profile_model.dart';
import '../local/hive_service.dart';

class FirestoreSyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> syncProfileToCloud(String uid, UserProfileModel profile) async {
    try {
      await _db.collection('users').doc(uid).set({
        'id': profile.id,
        'name': profile.name,
        'email': profile.email,
        'category': profile.category,
        'gender': profile.gender,
        'dateOfBirth': profile.dateOfBirth,
        'phone': profile.phone,
        'profileCompletion': profile.profileCompletion,
        'stateOfDomicile': profile.stateOfDomicile,
        'primaryExamGoal': profile.primaryExamGoal,
        'isVerified': profile.isVerified,
        'confidenceLevel': profile.confidenceLevel,
        'tenthBoard': profile.tenthBoard,
        'tenthYear': profile.tenthYear,
        'tenthPercentage': profile.tenthPercentage,
        'twelfthBoard': profile.twelfthBoard,
        'twelfthYear': profile.twelfthYear,
        'twelfthPercentage': profile.twelfthPercentage,
        'gradCourse': profile.gradCourse,
        'gradUniversity': profile.gradUniversity,
        'gradYear': profile.gradYear,
        'gradPercentage': profile.gradPercentage,
        'graduationStatus': profile.graduationStatus,
        'qualification': profile.qualification,
        'university': profile.university,
        'passingYear': profile.passingYear,
        'percentage': profile.percentage,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to sync profile to cloud: $e');
    }
  }

  static Future<void> syncDocToCloud(String uid, AcademicDocModel doc) async {
    try {
      await _db.collection('users').doc(uid).collection('documents').doc(doc.id).set({
        'id': doc.id,
        'docType': doc.docType,
        'fileName': '', 
        'extractedText': doc.extractedText,
        'board': doc.board,
        'year': doc.year,
        'aggregate': doc.aggregate,
        'stream': doc.stream,
        'confidence': doc.confidence,
        'isVerified': doc.isVerified,
        'uploadedAt': doc.uploadedAt.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to sync doc to cloud: $e');
    }
  }

  static Future<void> deleteDocFromCloud(String uid, String docId) async {
    try {
      await _db.collection('users').doc(uid).collection('documents').doc(docId).delete();
    } catch (e) {
      print('Failed to delete doc from cloud: $e');
    }
  }

  static Future<void> syncDownFromCloud(String uid) async {
    try {
      final profileSnap = await _db.collection('users').doc(uid).get();
      if (profileSnap.exists) {
        final data = profileSnap.data()!;
        final profile = UserProfileModel(
          id: data['id'] ?? uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          category: data['category'] ?? 'General',
          gender: data['gender'] ?? 'Male',
          dateOfBirth: data['dateOfBirth'] ?? '',
          phone: data['phone'] ?? '',
          profileCompletion: data['profileCompletion'] ?? 0,
          stateOfDomicile: data['stateOfDomicile'] ?? '',
          primaryExamGoal: data['primaryExamGoal'] ?? '',
          isVerified: data['isVerified'] ?? false,
          confidenceLevel: (data['confidenceLevel'] ?? 0.0).toDouble(),
          tenthBoard: data['tenthBoard'] ?? '',
          tenthYear: data['tenthYear'] ?? '',
          tenthPercentage: data['tenthPercentage'] ?? '',
          twelfthBoard: data['twelfthBoard'] ?? '',
          twelfthYear: data['twelfthYear'] ?? '',
          twelfthPercentage: data['twelfthPercentage'] ?? '',
          gradCourse: data['gradCourse'] ?? '',
          gradUniversity: data['gradUniversity'] ?? '',
          gradYear: data['gradYear'] ?? '',
          gradPercentage: data['gradPercentage'] ?? '',
          graduationStatus: data['graduationStatus'] ?? '',
          qualification: data['qualification'] ?? '',
          university: data['university'] ?? '',
          passingYear: data['passingYear'] ?? '',
          percentage: data['percentage'] ?? '',
        );
        await HiveService.saveUserProfileOnlyLocal(profile);
      }

      final docsSnap = await _db.collection('users').doc(uid).collection('documents').get();
      for (var docSnap in docsSnap.docs) {
        final data = docSnap.data();
        final doc = AcademicDocModel(
          id: data['id'] ?? docSnap.id,
          docType: data['docType'] ?? '',
          fileName: data['fileName'] ?? '',
          extractedText: data['extractedText'] ?? '',
          board: data['board'] ?? '',
          year: data['year'] ?? '',
          aggregate: data['aggregate'] ?? '',
          stream: data['stream'] ?? '',
          confidence: (data['confidence'] ?? 0.0).toDouble(),
          isVerified: data['isVerified'] ?? false,
          uploadedAt: data['uploadedAt'] != null 
              ? DateTime.parse(data['uploadedAt']) 
              : DateTime.now(),
        );
        await HiveService.saveDocOnlyLocal(doc, uid: uid);
      }
    } catch (e) {
      print('Failed to sync down from cloud: $e');
    }
  }
}
