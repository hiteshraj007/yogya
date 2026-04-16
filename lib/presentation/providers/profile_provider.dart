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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/providers/auth_provider.dart';

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
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
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
    final profile = HiveService.getUserProfile(uid);
    state = state.copyWith(isLoading: false, profile: profile);
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
      if (graduationStatus == 'Completed' && gradCourse.isNotEmpty) {
        computedQual = 'Graduation ($gradCourse)';
      } else if (twelfthBoard.isNotEmpty) {
        computedQual = '12th Pass';
      } else if (tenthBoard.isNotEmpty) {
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
    required String university,
    required String percentage,
    required String passingYear,
    required String extractedName,
    required String primaryExamGoal,
    String? courseName,
    String? graduationStatus,
    bool isVerified = false,
    double confidenceLevel = 0.0,
  }) async {
    final existing = HiveService.getUserProfile(uid) ?? state.profile;
    
    String tBoard = existing?.tenthBoard ?? ''; String tYear = existing?.tenthYear ?? ''; String tPercent = existing?.tenthPercentage ?? '';
    String twBoard = existing?.twelfthBoard ?? ''; String twYear = existing?.twelfthYear ?? ''; String twPercent = existing?.twelfthPercentage ?? '';
    String gCourse = existing?.gradCourse ?? ''; String gUni = existing?.gradUniversity ?? ''; String gYear = existing?.gradYear ?? ''; String gPercent = existing?.gradPercentage ?? ''; String gStatus = existing?.graduationStatus ?? '';

    String newName = existing?.name ?? '';
    String newDob = existing?.dateOfBirth ?? '';

    if (docType.contains('10')) {
      tBoard = university; tYear = passingYear; tPercent = percentage;
      if (extractedName.isNotEmpty) newName = extractedName;
      if (dateOfBirth.isNotEmpty) newDob = dateOfBirth;
    } else if (docType.contains('12')) {
      twBoard = university; twYear = passingYear; twPercent = percentage;
    } else if (docType.toLowerCase().contains('grad')) {
      gCourse = courseName ?? university; gUni = university; gYear = passingYear; gPercent = percentage;
      gStatus = (graduationStatus != null && graduationStatus.isNotEmpty) ? graduationStatus : ((int.tryParse(passingYear) ?? 9999) > DateTime.now().year ? 'Pursuing' : 'Completed');
    }

    await saveProfile(
      uid: uid, name: newName, email: existing?.email ?? '', category: existing?.category ?? 'General', gender: existing?.gender ?? 'Male', dateOfBirth: newDob, phone: existing?.phone ?? '', stateOfDomicile: existing?.stateOfDomicile ?? '', primaryExamGoal: primaryExamGoal.trim().isNotEmpty ? primaryExamGoal : (existing?.primaryExamGoal ?? ''),
      tenthBoard: tBoard, tenthYear: tYear, tenthPercentage: tPercent,
      twelfthBoard: twBoard, twelfthYear: twYear, twelfthPercentage: twPercent,
      gradCourse: gCourse, gradUniversity: gUni, gradYear: gYear, gradPercentage: gPercent, graduationStatus: gStatus,
    );
  }

  void resetSaved() => state = state.copyWith(isSaved: false);
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) => ProfileNotifier());
final profileLoaderProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user != null) await ref.read(profileNotifierProvider.notifier).loadProfile(user.uid);
});