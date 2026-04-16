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
// lib/presentation/providers/profile_provider.dart
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
    required String qualification,
    required String university,
    required String passingYear,
    required String percentage,
    required String phone,
    String stateOfDomicile = '',
    String primaryExamGoal = '',
    bool isVerified = false,
    double confidenceLevel = 0.0,
    String graduationStatus = '',
  }) async {
    state = state.copyWith(isLoading: true, isSaved: false, clearError: true);
    try {
      final profile = UserProfileModel(
        id: uid,
        name: name,
        email: email,
        category: category,
        gender: gender,
        dateOfBirth: dateOfBirth,
        qualification: qualification,
        university: university,
        passingYear: passingYear,
        percentage: percentage,
        phone: phone,
        profileCompletion: 0,
        stateOfDomicile: stateOfDomicile,
        primaryExamGoal: primaryExamGoal,
        isVerified: isVerified,
        confidenceLevel: confidenceLevel,
        graduationStatus: graduationStatus,
      );
      profile.profileCompletion = profile.calculateCompletion();
      await HiveService.saveUserProfile(profile);
      state = state.copyWith(isLoading: false, isSaved: true, profile: profile);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save profile. Please try again.');
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

    String mergeText(String current, String incoming) {
      final inVal = incoming.trim();
      if (inVal.isEmpty) return current;
      if (docType.contains('10') || current.trim().isEmpty) return inVal;
      return current;
    }

    String mergeDob(String current, String incoming) {
      var value = incoming.trim();
      if (value.isEmpty) return current;

      value = value.replaceAll('-', '/').replaceAll('.', '/').replaceAll(RegExp(r'\s+'), '');
      final m = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(value);
      if (m == null) return current;

      final dd = int.parse(m.group(1)!);
      final mm = int.parse(m.group(2)!);
      final yyyy = int.parse(m.group(3)!);

      if (yyyy < 1950 || yyyy > DateTime.now().year) return current;
      final dt = DateTime(yyyy, mm, dd);
      if (dt.year != yyyy || dt.month != mm || dt.day != dd) return current;

      int age = DateTime.now().year - yyyy;
      if (DateTime.now().month < mm || (DateTime.now().month == mm && DateTime.now().day < dd)) age--;
      if (age < 10 || age > 80) return current;

      return '${dd.toString().padLeft(2, '0')}/${mm.toString().padLeft(2, '0')}/$yyyy';
    }

    String mergeQualification(String current, String incoming, String passYear) {
      int rank(String value) {
        final q = value.toLowerCase();
        if (q.contains('phd')) return 5;
        if (q.contains('post')) return 4;
        if (q.contains('grad')) return 3;
        if (q.contains('12')) return 2;
        if (q.contains('10')) return 1;
        return 0;
      }
      
      final cRank = rank(current);
      final iRank = rank(incoming);

      if (incoming.trim().isEmpty) return current;

      if (iRank == 3) { // graduation
        final pYear = int.tryParse(passYear);
        if (pYear == null || pYear > DateTime.now().year) {
           return cRank < 2 ? '12th Pass' : current;
        }
      }

      return iRank >= cRank ? incoming : current;
    }

    double? numericValue(String raw) {
      final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw.trim().toLowerCase());
      if (m == null) return null;
      return double.tryParse(m.group(1)!);
    }

    bool isCgpa(String raw) => raw.toLowerCase().contains('cgpa') || raw.toLowerCase().contains('gpa');

    String normalizeByQualification(String raw, String qualification) {
      final val = raw.trim();
      if (val.isEmpty) return '';
      final q = qualification.toLowerCase();

      if (q.contains('grad')) {
        if (isCgpa(val)) return val;
        final num = numericValue(val);
        if (num != null && num <= 10.0) return 'CGPA ${num.toStringAsFixed(2)}';
        return val;
      }

      if (val.contains('%')) return val;
      final num = numericValue(val);
      if (num == null) return val;
      if (num <= 10.0) return '${(num * 9.5).toStringAsFixed(2)}%';
      return '${num.toStringAsFixed(2)}%';
    }

    String newGraduationStatus = existing?.graduationStatus ?? '';
    if (docType.toLowerCase().contains('grad')) {
        if (graduationStatus != null && graduationStatus.isNotEmpty) {
            newGraduationStatus = graduationStatus;
        } else {
            final iy = int.tryParse(passingYear);
            if (iy == null || iy > DateTime.now().year) {
                newGraduationStatus = 'Pursuing';
            } else {
                newGraduationStatus = 'Completed';
            }
        }
    }

    // Merge Course Name into Qualification if applicable
    String mergedQualification = mergeQualification(existing?.qualification ?? '', docType, passingYear);
    if (docType.toLowerCase().contains('grad') && courseName != null && courseName.isNotEmpty) {
        mergedQualification = courseName;
    }

    final currentYear = int.tryParse(existing?.passingYear ?? '');
    final incomingYear = int.tryParse(passingYear);
    final mergedYear = incomingYear != null && (currentYear == null || incomingYear > currentYear)
        ? passingYear
        : (existing?.passingYear ?? '');

    final incomingNormalized = normalizeByQualification(percentage, mergedQualification);
    final currentNormalized = normalizeByQualification(existing?.percentage ?? '', existing?.qualification ?? '');

    String mergedPercentage;
    if (mergedQualification.toLowerCase().contains('grad')) {
      mergedPercentage = incomingNormalized.isNotEmpty ? incomingNormalized : currentNormalized;
    } else {
      final currentNum = numericValue(currentNormalized);
      final incomingNum = numericValue(incomingNormalized);
      mergedPercentage = (incomingNum != null && (currentNum == null || incomingNum > currentNum))
          ? incomingNormalized
          : currentNormalized;
    }

    final mergedGoal = primaryExamGoal.trim().isNotEmpty ? primaryExamGoal : (existing?.primaryExamGoal ?? '');

    await saveProfile(
      uid: uid,
      name: mergeText(existing?.name ?? '', extractedName),
      email: existing?.email ?? '',
      category: existing?.category ?? 'General',
      gender: existing?.gender ?? 'Male',
      dateOfBirth: mergeDob(existing?.dateOfBirth ?? '', dateOfBirth),
      qualification: mergedQualification,
      university: mergeText(existing?.university ?? '', university),
      passingYear: mergedYear,
      percentage: mergedPercentage,
      phone: existing?.phone ?? '',
      stateOfDomicile: existing?.stateOfDomicile ?? '',
      primaryExamGoal: mergedGoal,
      isVerified: existing?.isVerified ?? false || isVerified,
      confidenceLevel: (existing?.confidenceLevel ?? 0.0) < confidenceLevel ? confidenceLevel : (existing?.confidenceLevel ?? 0.0),
      graduationStatus: newGraduationStatus.isNotEmpty ? newGraduationStatus : (existing?.graduationStatus ?? ''),
    );
  }

  void resetSaved() => state = state.copyWith(isSaved: false);
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) => ProfileNotifier());

final profileLoaderProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    await ref.read(profileNotifierProvider.notifier).loadProfile(user.uid);
  }
});