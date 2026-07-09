import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/eligibility_service.dart';
import '../../core/utils/profile_validators.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/eligibility_result_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/remote/api_service.dart';
import '../../core/constants/exam_data.dart';
import '../../data/providers/auth_provider.dart';
import 'profile_provider.dart';
import 'remote_data_provider.dart';

class EligibilityState {
  final bool isLoading;
  final Set<String> selectedExamIds;
  final List<EligibilityEvaluation> evaluations;
  final String? errorMessage;
  final DateTime? lastComputedAt;
  final String primaryGoal;

  const EligibilityState({
    this.isLoading = false,
    this.selectedExamIds = const {},
    this.evaluations = const [],
    this.errorMessage,
    this.lastComputedAt,
    this.primaryGoal = '',
  });

  EligibilityState copyWith({
    bool? isLoading,
    Set<String>? selectedExamIds,
    List<EligibilityEvaluation>? evaluations,
    String? errorMessage,
    DateTime? lastComputedAt,
    String? primaryGoal,
    bool clearError = false,
  }) {
    return EligibilityState(
      isLoading: isLoading ?? this.isLoading,
      selectedExamIds: selectedExamIds ?? this.selectedExamIds,
      evaluations: evaluations ?? this.evaluations,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastComputedAt: lastComputedAt ?? this.lastComputedAt,
      primaryGoal: primaryGoal ?? this.primaryGoal,
    );
  }
}

final eligibilityProvider =
    StateNotifierProvider<EligibilityNotifier, EligibilityState>((ref) {
  final notifier = EligibilityNotifier(ref);
  
  ref.listen<ProfileState>(profileNotifierProvider, (previous, next) {
    if (next.profile != null && (previous?.profile != next.profile || next.isSaved)) {
      Future.microtask(() async {
        try {
          final examsAsync = ref.read(allExamsProvider);
          final allExams = examsAsync.value ?? ExamData.allExams;
          await notifier.computeAll(next.profile, allExams);
        } catch (_) {
          await notifier.computeAll(next.profile, ExamData.allExams);
        }
      });
    }
  });

  ref.listen<AsyncValue<List<ExamInfo>>>(allExamsProvider, (previous, next) {
    if (next.value != null && (previous?.value?.length != next.value?.length)) {
      final profile = ref.read(profileNotifierProvider).profile;
      if (profile != null) {
        Future.microtask(() async {
          await notifier.computeAll(profile, next.value!);
        });
      }
    }
  });

  return notifier;
});

class EligibilityNotifier extends StateNotifier<EligibilityState> {
  final Ref ref;
  EligibilityNotifier(this.ref) : super(const EligibilityState());

  final EligibilityService _engine = EligibilityService.instance;

  void toggleExamSelection(String examId) {
    final selected = Set<String>.from(state.selectedExamIds);
    if (selected.contains(examId)) {
      selected.remove(examId);
    } else {
      selected.add(examId);
    }
    state = state.copyWith(selectedExamIds: selected, clearError: true);
  }

  void setSelectedExams(Set<String> examIds) {
    state = state.copyWith(
      selectedExamIds: Set<String>.from(examIds),
      clearError: true,
    );
  }

  Future<void> computeForSelected(UserProfileModel? profile, List<ExamInfo> allExams) async {
    if (profile == null) {
      state = state.copyWith(
        errorMessage: 'Please complete your profile before checking eligibility.',
      );
      return;
    }

    final selected = state.selectedExamIds;
    if (selected.isEmpty) {
      state = state.copyWith(errorMessage: 'Select at least one exam.');
      return;
    }

    await _compute(profile: profile, examIds: selected, allExams: allExams);
  }

  Future<void> computeAll(UserProfileModel? profile, List<ExamInfo> allExams) async {
    if (profile == null) {
      state = state.copyWith(
        errorMessage: 'Please complete your profile before checking eligibility.',
      );
      return;
    }
    await _compute(
      profile: profile,
      examIds: allExams.map((e) => e.id).toSet(),
      allExams: allExams,
      primaryGoal: profile.primaryExamGoal,
    );
  }

  Future<void> _compute({
    required UserProfileModel profile,
    required Set<String> examIds,
    List<ExamInfo>? allExams,
    String primaryGoal = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, primaryGoal: primaryGoal);

    try {
      final user = ref.read(currentUserProvider);
      final uid = user?.uid;
      final docs = HiveService.getAllDocs(uid: uid);
      final attempts = await _loadAttemptCounts();
      final examsList = allExams ?? ExamData.allExams;
      List<EligibilityEvaluation> rawEvaluations;
      if (!ApiService.instance.simulateRealtime) {
        rawEvaluations = await _computeFromBackend(
          profile: profile,
          docs: docs,
          attemptsByExam: attempts,
          examIds: examIds,
          allExams: examsList,
        );
        if (rawEvaluations.isEmpty) {
          rawEvaluations = _engine.evaluate(
            profile: profile,
            docs: docs,
            attemptsByExam: attempts,
            examIds: examIds,
            allExams: examsList,
          );
        }
      } else {
        rawEvaluations = _engine.evaluate(
          profile: profile,
          docs: docs,
          attemptsByExam: attempts,
          examIds: examIds,
          allExams: examsList,
        );
      }

      // Sort: goal-match+eligible → other eligible → goal-match+ineligible → rest ineligible
      final goal = primaryGoal.trim();
      final sorted = List<EligibilityEvaluation>.from(rawEvaluations);
      sorted.sort((a, b) {
        final aGoal = goal.isNotEmpty && ProfileValidators.matchesGoal(goal, a.exam.name, a.exam.code);
        final bGoal = goal.isNotEmpty && ProfileValidators.matchesGoal(goal, b.exam.name, b.exam.code);

        // Priority: 0 = goal+eligible, 1 = eligible, 2 = goal+ineligible, 3 = ineligible
        int priority(EligibilityEvaluation e, bool isGoal) {
          if (isGoal && e.isEligible) return 0;
          if (!isGoal && e.isEligible) return 1;
          if (isGoal && !e.isEligible) return 2;
          return 3;
        }

        return priority(a, aGoal).compareTo(priority(b, bGoal));
      });

      for (final evaluation in sorted) {
        await HiveService.saveEligibilityResult(
          EligibilityResultModel(
            examId: evaluation.exam.id,
            isEligible: evaluation.isEligible,
            missingCriteria: evaluation.missingCriteria,
            matchPercent: evaluation.matchPercent,
            checkedAt: DateTime.now(),
          ),
          uid: uid,
        );
      }

      state = state.copyWith(
        isLoading: false,
        evaluations: sorted,
        lastComputedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Eligibility check failed. Please try again.',
      );
    }
  }

  Future<Map<String, int>> _loadAttemptCounts() async {
    final counts = <String, int>{};
    final box = Hive.isBoxOpen('attemptHistory')
        ? Hive.box('attemptHistory')
        : await Hive.openBox('attemptHistory');

    for (final value in box.values) {
      if (value is! Map) continue;
      final record = Map<String, dynamic>.from(value);
      final examName = (record['exam'] ?? '').toString().trim();
      if (examName.isEmpty) continue;

      final matchedExam = ExamData.allExams.where((exam) {
        final lower = examName.toLowerCase();
        return lower.contains(exam.code.toLowerCase()) ||
            lower.contains(exam.name.toLowerCase());
      }).toList();

      if (matchedExam.isEmpty) continue;
      final examId = matchedExam.first.id;
      counts[examId] = (counts[examId] ?? 0) + 1;
    }

    return counts;
  }

  Future<List<EligibilityEvaluation>> _computeFromBackend({
    required UserProfileModel profile,
    required List<dynamic> docs,
    required Map<String, int> attemptsByExam,
    required Set<String> examIds,
    required List<ExamInfo> allExams,
  }) async {
    try {
      final student = _backendStudentPayload(
        profile: profile,
        docs: docs,
        attemptsByExam: attemptsByExam,
        allExams: allExams,
      );
      final response = await ApiService.instance.checkEligibility(student: student);
      final results = (response['results'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((item) => _evaluationFromBackend(item, attemptsByExam, allExams))
          .where((evaluation) =>
              examIds.isEmpty || examIds.contains(evaluation.exam.id))
          .toList();
      return results;
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _backendStudentPayload({
    required UserProfileModel profile,
    required List<dynamic> docs,
    required Map<String, int> attemptsByExam,
    required List<ExamInfo> allExams,
  }) {
    final tenthDoc = _firstDoc(docs, '10');
    final twelfthDoc = _firstDoc(docs, '12');
    final gradDoc = _firstDoc(docs, 'grad');
    final attemptsByShortName = <String, int>{};
    for (final exam in allExams) {
      final used = attemptsByExam[exam.id];
      if (used != null) {
        attemptsByShortName[exam.code] = used;
        attemptsByShortName[exam.name] = used;
      }
    }

    return {
      'dob': profile.dateOfBirth,
      'category': _backendCategory(profile.category),
      'is_pwbd': profile.category.trim().toUpperCase() == 'PWD',
      'gender': profile.gender.toUpperCase(),
      'percentage_10': _percentageFrom(profile.tenthPercentage, tenthDoc?.aggregate),
      'board_10': _firstNonEmpty(profile.tenthBoard, tenthDoc?.board),
      'year_10': _intFrom(_firstNonEmpty(profile.tenthYear, tenthDoc?.year)),
      'percentage_12': _percentageFrom(profile.twelfthPercentage, twelfthDoc?.aggregate),
      'board_12': _firstNonEmpty(profile.twelfthBoard, twelfthDoc?.board),
      'year_12': _intFrom(_firstNonEmpty(profile.twelfthYear, twelfthDoc?.year)),
      'stream_12': _firstNonEmpty(twelfthDoc?.stream, ''),
      'subjects_12': <String, double>{},
      'graduation_status': _graduationStatus(profile),
      'degree': profile.gradCourse.isNotEmpty ? profile.gradCourse : null,
      'graduation_percentage': _percentageFrom(profile.gradPercentage, gradDoc?.aggregate),
      'graduation_year': _intFrom(_firstNonEmpty(profile.gradYear, gradDoc?.year)),
      'attempts_used': attemptsByShortName,
    };
  }

  dynamic _firstDoc(List<dynamic> docs, String marker) {
    final lower = marker.toLowerCase();
    for (final doc in docs) {
      final type = (doc.docType as String).toLowerCase();
      if (type.contains(lower)) return doc;
    }
    return null;
  }

  EligibilityEvaluation _evaluationFromBackend(
    Map<String, dynamic> item,
    Map<String, int> attemptsByExam,
    List<ExamInfo> allExams,
  ) {
    final shortName = (item['exam_short_name'] ?? '').toString();
    final fullName = (item['exam_full_name'] ?? shortName).toString();
    final exam = _examFromBackend(shortName, fullName, item, allExams);
    final eligible = item['eligible'] == true;
    final failReasons = (item['reasons_fail'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final passReasons = (item['reasons_pass'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final criteria = {
      'Age': !failReasons.any((r) => r.toLowerCase().contains('age')),
      'Qualification': !failReasons.any((r) {
        final lower = r.toLowerCase();
        return lower.contains('education') ||
            lower.contains('qualification') ||
            lower.contains('percentage') ||
            lower.contains('stream') ||
            lower.contains('subject') ||
            lower.contains('degree');
      }),
      'Attempts': !failReasons.any((r) => r.toLowerCase().contains('attempt')),
      'Documents': true,
      'Category': true,
    };
    final attemptsRemaining = item['attempts_remaining'] is int
        ? item['attempts_remaining'] as int
        : int.tryParse('${item['attempts_remaining']}') ?? -1;
    final attemptsUsed = attemptsByExam[exam.id] ?? 0;
    final attemptsAllowed = attemptsRemaining == -1 ? -1 : attemptsUsed + attemptsRemaining;
    final matchPercent = eligible
        ? 100
        : ((criteria.values.where((value) => value).length / criteria.length) * 100)
            .round();

    return EligibilityEvaluation(
      exam: exam,
      isEligible: eligible,
      status: eligible ? 'ELIGIBLE' : 'INELIGIBLE',
      matchPercent: matchPercent,
      criteria: criteria,
      missingCriteria: failReasons,
      age: item['age_at_cutoff'] is int
          ? item['age_at_cutoff'] as int
          : int.tryParse('${item['age_at_cutoff']}') ?? 0,
      minAge: exam.minAge,
      maxAge: exam.maxAgeGeneral,
      attemptsUsed: attemptsUsed,
      attemptsAllowed: attemptsAllowed,
      nextSteps: [
        if ((item['apply_url'] ?? '').toString().isNotEmpty)
          'Open registration portal: ${item['apply_url']}',
        if ((item['official_url'] ?? '').toString().isNotEmpty)
          'Review official info: ${item['official_url']}',
        if (passReasons.isNotEmpty) passReasons.first,
      ],
    );
  }

  ExamInfo _examFromBackend(
    String shortName,
    String fullName,
    Map<String, dynamic> item,
    List<ExamInfo> allExams,
  ) {
    final lowerShort = shortName.toLowerCase();
    for (final exam in allExams) {
      if (exam.code.toLowerCase() == lowerShort ||
          exam.name.toLowerCase().contains(lowerShort) ||
          lowerShort.contains(exam.code.toLowerCase())) {
        return exam;
      }
    }

    final id = shortName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+$'), '');
    return ExamInfo(
      id: id.isEmpty ? fullName.toLowerCase().replaceAll(' ', '_') : id,
      name: fullName,
      code: shortName.isEmpty ? fullName : shortName,
      conductingBody: (item['conducting_body'] ?? '').toString(),
      qualification: 'Official criteria',
      minAge: 0,
      maxAgeGeneral: 0,
      maxAgeOBC: 0,
      maxAgeSC: 0,
      maxAgeST: 0,
      maxAttemptsGeneral: -1,
      maxAttemptsOBC: -1,
      maxAttemptsSCST: -1,
      category: (item['exam_category'] ?? 'Other').toString(),
      description: 'Synced from Yogya eligibility backend',
      registrationUrl: (item['apply_url'] ?? '').toString(),
      officialInfoUrl: (item['official_url'] ?? '').toString(),
    );
  }

  String _backendCategory(String category) {
    final upper = category.trim().toUpperCase();
    if (upper == 'GENERAL' || upper == 'OBC' || upper == 'SC' || upper == 'ST' || upper == 'EWS') {
      return upper;
    }
    return 'GENERAL';
  }

  String _graduationStatus(UserProfileModel profile) {
    final status = profile.graduationStatus.trim().toLowerCase();
    if (status.contains('complete')) return 'COMPLETED';
    if (status.contains('pursu')) return 'PURSUING';
    final gradYear = int.tryParse(profile.gradYear.trim());
    if (profile.gradCourse.isNotEmpty && gradYear != null) {
      return gradYear <= DateTime.now().year ? 'COMPLETED' : 'PURSUING';
    }
    if (profile.gradCourse.isNotEmpty) return 'PURSUING';
    return 'NOT_APPLICABLE';
  }

  String _firstNonEmpty(String? first, String? second) {
    final a = (first ?? '').trim();
    if (a.isNotEmpty) return a;
    return (second ?? '').trim();
  }

  int? _intFrom(String raw) => int.tryParse(raw.trim());

  double? _percentageFrom(String? first, String? second) {
    final raw = _firstNonEmpty(first, second);
    if (raw.isEmpty) return null;
    final lower = raw.toLowerCase();
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
    if (match == null) return null;
    final parsed = double.tryParse(match.group(1)!);
    if (parsed == null) return null;
    if (lower.contains('cgpa')) return parsed * 9.5;
    return parsed;
  }

  void reset() {
    state = const EligibilityState();
  }
}
