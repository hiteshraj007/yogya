// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../data/local/hive_service.dart';
// import '../../data/models/user_profile_model.dart';
// import '../../data/providers/auth_provider.dart';

// // ── Profile State ─────────────────────────────────────────
// class ProfileState {
//   final UserProfileModel? profile;
//   final bool isLoading;
//   final bool isSaved;
//   final String? errorMessage;

//   const ProfileState({
//     this.profile,
//     this.isLoading = false,
//     this.isSaved = false,
//     this.errorMessage,
//   });

//   ProfileState copyWith({
//     UserProfileModel? profile,
//     bool? isLoading,
//     bool? isSaved,
//     String? errorMessage,
//     bool clearError = false,
//   }) {
//     return ProfileState(
//       profile: profile ?? this.profile,
//       isLoading: isLoading ?? this.isLoading,
//       isSaved: isSaved ?? this.isSaved,
//       errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
//     );
//   }
// }

// // ── Profile Notifier ──────────────────────────────────────
// class ProfileNotifier extends StateNotifier<ProfileState> {
//   ProfileNotifier() : super(const ProfileState());

//   // Hive se profile load karo
//   Future<void> loadProfile(String uid) async {
//     state = state.copyWith(isLoading: true);
//     final profile = HiveService.getUserProfile(uid);
//     state = state.copyWith(
//       isLoading: false,
//       profile: profile,
//     );
//   }

//   // Profile save karo Hive mein
//   Future<void> saveProfile({
//     required String uid,
//     required String name,
//     required String email,
//     required String category,
//     required String gender,
//     required String dateOfBirth,
//     required String qualification,
//     required String university,
//     required String passingYear,
//     required String percentage,
//     required String phone,
//     String stateOfDomicile = '',
//     String primaryExamGoal = '',
//   }) async {
//     state = state.copyWith(isLoading: true, isSaved: false);

//     try {
//       // Existing profile lo ya naya banao
//       final existing = HiveService.getUserProfile(uid);

//       final profile = UserProfileModel(
//         id: uid,
//         name: name,
//         email: email,
//         category: category,
//         gender: gender,
//         dateOfBirth: dateOfBirth,
//         qualification: qualification,
//         university: university,
//         passingYear: passingYear,
//         percentage: percentage,
//         phone: phone,
//         profileCompletion: 0,
//         stateOfDomicile: stateOfDomicile,
//         primaryExamGoal: primaryExamGoal,
//       );

//       // Completion calculate karo
//       profile.profileCompletion = profile.calculateCompletion();

//       // Hive mein save karo
//       await HiveService.saveUserProfile(profile);

//       state = state.copyWith(
//         isLoading: false,
//         isSaved: true,
//         profile: profile,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         errorMessage: 'Failed to save profile. Please try again.',
//       );
//     }
//   }
//   Future<void> updateFromOcr({
//     required String uid,
//     required String docType,
//     required String dateOfBirth,
//     required String university,
//     required String percentage,
//     required String passingYear,
//     String primaryExamGoal = '',
//   }) async {
//     final existing = HiveService.getUserProfile(uid) ?? state.profile;

//     String mergeQualification(String current, String incoming) {
//       int rank(String value) {
//         final q = value.toLowerCase();
//         if (q.contains('phd')) return 5;
//         if (q.contains('post')) return 4;
//         if (q.contains('grad')) return 3;
//         if (q.contains('12')) return 2;
//         if (q.contains('10')) return 1;
//         return 0;
//       }

//       if (incoming.trim().isEmpty) return current;
//       if (rank(incoming) >= rank(current)) return incoming;
//       return current;
//     }

//     double? parsePercent(String raw) {
//       final value = raw.trim().toLowerCase();
//       if (value.isEmpty) return null;

//       final number = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
//       if (number == null) return null;

//       final parsed = double.tryParse(number.group(1)!);
//       if (parsed == null) return null;

//       if (value.contains('cgpa')) return parsed * 9.5;
//       return parsed;
//     }

//     final currentPercent = parsePercent(existing?.percentage ?? '');
//     final incomingPercent = parsePercent(percentage);
//     final mergedPercent = incomingPercent != null &&
//             (currentPercent == null || incomingPercent > currentPercent)
//         ? percentage
//         : (existing?.percentage ?? '');

//     final currentYear = int.tryParse(existing?.passingYear ?? '');
//     final incomingYear = int.tryParse(passingYear);
//     final mergedYear = incomingYear != null &&
//             (currentYear == null || incomingYear > currentYear)
//         ? passingYear
//         : (existing?.passingYear ?? '');

//     final mergedGoal =
//         primaryExamGoal.trim().isNotEmpty ? primaryExamGoal : (existing?.primaryExamGoal ?? '');

//     await saveProfile(
//       uid: uid,
//       name: existing?.name ?? '',
//       email: existing?.email ?? '',
//       category: existing?.category ?? 'General',
//       gender: existing?.gender ?? 'Male',
//       dateOfBirth: dateOfBirth.isNotEmpty ? dateOfBirth : (existing?.dateOfBirth ?? ''),
//       qualification: mergeQualification(existing?.qualification ?? '', docType),
//       university: university.isNotEmpty ? university : (existing?.university ?? ''),
//       passingYear: mergedYear,
//       percentage: mergedPercent,
//       phone: existing?.phone ?? '',
//       stateOfDomicile: existing?.stateOfDomicile ?? '',
//       primaryExamGoal: mergedGoal,
//     );
//   }

//   void resetSaved() => state = state.copyWith(isSaved: false);
// }

// // ── Providers ─────────────────────────────────────────────
// final profileNotifierProvider =
//     StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
//   return ProfileNotifier();
// });

// // Profile load karo jab user login ho
// final profileLoaderProvider = FutureProvider<void>((ref) async {
//   final user = ref.watch(currentUserProvider);
//   if (user != null) {
//     await ref.read(profileNotifierProvider.notifier).loadProfile(user.uid);
//   }
// });
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/remote/firestore_sync_service.dart';

class ProfileState {
  final UserProfileModel? profile;
  final bool isLoading;
  final bool isSaved;
  final String? errorMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaved = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    UserProfileModel? profile,
    bool? isLoading,
    bool? isSaved,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return ProfileState(
      profile: clearProfile ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  Future<void> loadProfile(String uid) async {
    state = state.copyWith(isLoading: true);
    
    // Sync down from remote
    await FirestoreSyncService.syncDownFromCloud(uid);

    final profile = HiveService.getUserProfile(uid);
    state = state.copyWith(
      isLoading: false, 
      profile: profile, 
      clearProfile: profile == null,
    );
  }

  void clearProfile() {
    state = const ProfileState();
  }

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String email,
    required String category,
    required String gender,
    required String dateOfBirth,
    required String phone,
    String stateOfDomicile = '',
    String primaryExamGoal = '',
    String tenthBoard = '', String tenthYear = '', String tenthPercentage = '',
    String twelfthBoard = '', String twelfthYear = '', String twelfthPercentage = '',
    String gradCourse = '', String gradUniversity = '', String gradYear = '', String gradPercentage = '', String graduationStatus = '',
  }) async {
    state = state.copyWith(isLoading: true, isSaved: false, clearError: true);
    try {
      final existing = HiveService.getUserProfile(uid);
      
      // Auto-compute display qualification
      String computedQual = 'Not Specified';
      final hasTenth =
          tenthBoard.isNotEmpty || tenthYear.isNotEmpty || tenthPercentage.isNotEmpty;
      final hasTwelfth =
          twelfthBoard.isNotEmpty || twelfthYear.isNotEmpty || twelfthPercentage.isNotEmpty;
      final normalizedGradStatus = graduationStatus.trim().toLowerCase();
      if (gradCourse.trim().isNotEmpty) {
        final course = gradCourse.trim();
        if (normalizedGradStatus == 'completed') {
          computedQual = 'Graduation ($course)';
        } else if (normalizedGradStatus == 'pursuing' ||
            normalizedGradStatus.isEmpty) {
          computedQual = 'Pursuing Graduation ($course)';
        } else {
          computedQual = 'Graduation ($course)';
        }
      } else if (hasTwelfth) {
        computedQual = '12th Pass';
      } else if (hasTenth) {
        computedQual = '10th Pass';
      }

      final profile = UserProfileModel(
        id: uid, name: name, email: email, category: category, gender: gender,
        dateOfBirth: dateOfBirth, phone: phone, stateOfDomicile: stateOfDomicile,
        primaryExamGoal: primaryExamGoal,
        tenthBoard: tenthBoard, tenthYear: tenthYear, tenthPercentage: tenthPercentage,
        twelfthBoard: twelfthBoard, twelfthYear: twelfthYear, twelfthPercentage: twelfthPercentage,
        gradCourse: gradCourse, gradUniversity: gradUniversity, gradYear: gradYear, gradPercentage: gradPercentage,
        graduationStatus: graduationStatus,
        qualification: computedQual,
        isVerified: existing?.isVerified ?? false, confidenceLevel: existing?.confidenceLevel ?? 0.0,
      );
      profile.profileCompletion = profile.calculateCompletion();
      await HiveService.saveUserProfile(profile);
      state = state.copyWith(isLoading: false, isSaved: true, profile: profile);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save profile.');
    }
  }

  Future<void> updateFromOcr({
    required String uid,
    required String docType,
    required String dateOfBirth,
    required String university,  // raw school/institution name
    required String percentage,
    required String passingYear,
    required String extractedName,
    required String primaryExamGoal,
    String board = '',            // clean board name (e.g. "CBSE")
    String? courseName,
    String? graduationStatus,
    bool isVerified = false,
    double confidenceLevel = 0.0,
  }) async {
    final existing = HiveService.getUserProfile(uid) ?? state.profile;

    String tBoard  = existing?.tenthBoard     ?? '';
    String tYear   = existing?.tenthYear      ?? '';
    String tPercent = existing?.tenthPercentage ?? '';
    String twBoard = existing?.twelfthBoard    ?? '';
    String twYear  = existing?.twelfthYear     ?? '';
    String twPercent = existing?.twelfthPercentage ?? '';
    String gCourse = existing?.gradCourse     ?? '';
    String gUni    = existing?.gradUniversity  ?? '';
    String gYear   = existing?.gradYear       ?? '';
    String gPercent = existing?.gradPercentage ?? '';
    String gStatus = existing?.graduationStatus ?? '';

    String newName = existing?.name ?? '';
    String newDob  = existing?.dateOfBirth ?? '';

    // Use the clean board name; fall back to raw university text
    final effectiveBoard = board.isNotEmpty ? board : university;

    final dt = docType.toLowerCase();
    if (dt.contains('10')) {
      tBoard  = effectiveBoard;
      tYear   = passingYear;
      tPercent = percentage;
      // 10th marksheet is the ground truth for name & DOB
      if (extractedName.isNotEmpty) newName = extractedName;
      if (dateOfBirth.isNotEmpty)  newDob  = dateOfBirth;
    } else if (dt.contains('12')) {
      twBoard  = effectiveBoard;
      twYear   = passingYear;
      twPercent = percentage;
      // Fill DOB only if not already set
      if (newDob.isEmpty && dateOfBirth.isNotEmpty) newDob = dateOfBirth;
    } else if (dt.contains('pg') || dt.contains('post')) {
      // PG — store in grad fields (could be extended later)
      gCourse = _resolveCourseName(courseName, university, gCourse);
      gUni    = university;
      gYear   = passingYear;
      gPercent = percentage;
      gStatus  = 'Completed';
    } else if (dt.contains('grad') || dt.contains('ug') || dt.contains('bachelor')) {
      gCourse = _resolveCourseName(courseName, university, gCourse);
      gUni    = university;
      gYear   = passingYear;
      gPercent = percentage;
      final currentYear = DateTime.now().year;
      gStatus  = (graduationStatus != null && graduationStatus.isNotEmpty)
          ? graduationStatus
          : (gStatus.isNotEmpty
              ? gStatus
              : ((int.tryParse(passingYear) ?? currentYear + 1) >
                      currentYear
                  ? 'Pursuing'
                  : ''));
    }

    await saveProfile(
      uid: uid,
      name: newName,
      email: existing?.email.isNotEmpty == true ? existing!.email : (FirebaseAuth.instance.currentUser?.email ?? ''),
      category: existing?.category ?? 'General',
      gender: existing?.gender ?? 'Male',
      dateOfBirth: newDob,
      phone: existing?.phone ?? '',
      stateOfDomicile: existing?.stateOfDomicile.isNotEmpty == true 
          ? existing!.stateOfDomicile 
          : _guessStateFromBoard(twBoard.isNotEmpty ? twBoard : tBoard, university),
      primaryExamGoal: primaryExamGoal.trim().isNotEmpty
          ? primaryExamGoal
          : (existing?.primaryExamGoal ?? ''),
      tenthBoard:      tBoard,
      tenthYear:       tYear,
      tenthPercentage: tPercent,
      twelfthBoard:    twBoard,
      twelfthYear:     twYear,
      twelfthPercentage: twPercent,
      gradCourse:      gCourse,
      gradUniversity:  gUni,
      gradYear:        gYear,
      gradPercentage:  gPercent,
      graduationStatus: gStatus,
    );
  }

  String _guessStateFromBoard(String board, [String school = '']) {
    if (board.isEmpty && school.isEmpty) return '';
    final lower = '$board $school'.toLowerCase();
    final states = [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
      'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
      'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
      'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
      'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Puducherry', 'Chandigarh'
    ];
    for (final st in states) {
      if (lower.contains(st.toLowerCase())) return st;
    }
    if (lower.contains('up board') || lower.contains('upmsp')) return 'Uttar Pradesh';
    if (lower.contains('bseb')) return 'Bihar';
    if (lower.contains('rbse')) return 'Rajasthan';
    if (lower.contains('gseb')) return 'Gujarat';
    if (lower.contains('msbshse')) return 'Maharashtra';
    if (lower.contains('kseeb')) return 'Karnataka';
    if (lower.contains('wbbse') || lower.contains('wbchse')) return 'West Bengal';
    if (lower.contains('bseap') || lower.contains('bieap')) return 'Andhra Pradesh';
    return '';
  }

  String _resolveCourseName(String? extractedCourse, String university, String existingCourse) {
    final cleanedExtracted = (extractedCourse ?? '').trim();
    if (cleanedExtracted.isNotEmpty) return cleanedExtracted;

    final source = university.trim();
    if (source.isEmpty) return existingCourse;

    final lower = source.toLowerCase();
    if (RegExp(r'\bb\.?\s*tech\b').hasMatch(lower)) return 'B.Tech';
    if (RegExp(r'\bb\.?\s*e\.?\b').hasMatch(lower)) return 'B.E.';
    if (RegExp(r'\bbca\b').hasMatch(lower)) return 'BCA';
    if (RegExp(r'\bb\.?\s*sc\b').hasMatch(lower)) return 'B.Sc';
    if (RegExp(r'\bb\.?\s*com\b').hasMatch(lower)) return 'B.Com';
    if (RegExp(r'\bb\.?\s*a\.?\b').hasMatch(lower)) return 'B.A.';

    return existingCourse;
  }

  void resetSaved() => state = state.copyWith(isSaved: false);
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final notifier = ProfileNotifier();
  
  ref.listen<User?>(currentUserProvider, (previous, next) {
    if (next != null) {
      Future.microtask(() => notifier.loadProfile(next.uid));
    } else {
      Future.microtask(() => notifier.clearProfile());
    }
  }, fireImmediately: true);
  
  return notifier;
});

// Deprecated: No longer modifies state, just a placeholder to not break main.dart
final profileLoaderProvider = Provider<void>((ref) {});
