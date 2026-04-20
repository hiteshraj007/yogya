import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/eligibility_service.dart';
import '../../core/utils/profile_validators.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/eligibility_result_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../core/constants/exam_data.dart';

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
  return EligibilityNotifier();
});

class EligibilityNotifier extends StateNotifier<EligibilityState> {
  EligibilityNotifier() : super(const EligibilityState());

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

  Future<void> computeForSelected(UserProfileModel? profile) async {
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

    await _compute(profile: profile, examIds: selected);
  }

  Future<void> computeAll(UserProfileModel? profile) async {
    if (profile == null) {
      state = state.copyWith(
        errorMessage: 'Please complete your profile before checking eligibility.',
      );
      return;
    }
    await _compute(
      profile: profile,
      examIds: ExamData.allExams.map((e) => e.id).toSet(),
      primaryGoal: profile.primaryExamGoal,
    );
  }

  Future<void> _compute({
    required UserProfileModel profile,
    required Set<String> examIds,
    String primaryGoal = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, primaryGoal: primaryGoal);

    try {
      final docs = HiveService.getAllDocs();
      final attempts = await _loadAttemptCounts();
      final rawEvaluations = _engine.evaluate(
        profile: profile,
        docs: docs,
        attemptsByExam: attempts,
        examIds: examIds,
      );

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

  void reset() {
    state = const EligibilityState();
  }
}
