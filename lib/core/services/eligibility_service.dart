import '../../data/models/academic_doc_model.dart';
import '../../data/models/user_profile_model.dart';
import '../constants/exam_data.dart';

class EligibilityEvaluation {
  final ExamInfo exam;
  final bool isEligible;
  final String status; // ELIGIBLE | PARTIAL | INELIGIBLE
  final int matchPercent;
  final Map<String, bool> criteria;
  final List<String> missingCriteria;
  final int age;
  final int minAge;
  final int maxAge;
  final int attemptsUsed;
  final int attemptsAllowed;
  final List<String> nextSteps;

  const EligibilityEvaluation({
    required this.exam,
    required this.isEligible,
    required this.status,
    required this.matchPercent,
    required this.criteria,
    required this.missingCriteria,
    required this.age,
    required this.minAge,
    required this.maxAge,
    required this.attemptsUsed,
    required this.attemptsAllowed,
    required this.nextSteps,
  });
}

class FutureEligibilityProjection {
  final ExamInfo exam;
  final int year;
  final bool projectedEligible;
  final int projectedAge;
  final int minAge;
  final int maxAge;
  final int yearsToEligibility;
  final List<String> blockers;
  final String summary;

  const FutureEligibilityProjection({
    required this.exam,
    required this.year,
    required this.projectedEligible,
    required this.projectedAge,
    required this.minAge,
    required this.maxAge,
    required this.yearsToEligibility,
    required this.blockers,
    required this.summary,
  });
}

class EligibilityService {
  EligibilityService._();
  static final EligibilityService instance = EligibilityService._();

  List<EligibilityEvaluation> evaluate({
    required UserProfileModel profile,
    required List<AcademicDocModel> docs,
    required Map<String, int> attemptsByExam,
    Set<String>? examIds,
    List<ExamInfo>? allExams,
  }) {
    final list = allExams ?? ExamData.allExams;
    final targetExams = list
        .where((exam) => examIds == null || examIds.contains(exam.id))
        .toList();

    final results = <EligibilityEvaluation>[];

    for (final exam in targetExams) {
      final evaluation = _evaluateOne(
        exam: exam,
        profile: profile,
        docs: docs,
        attemptsByExam: attemptsByExam,
        referenceDate: null,
      );
      results.add(evaluation);
    }

    results.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return results;
  }

  EligibilityEvaluation _evaluateOne({
    required ExamInfo exam,
    required UserProfileModel profile,
    required List<AcademicDocModel> docs,
    required Map<String, int> attemptsByExam,
    required DateTime? referenceDate,
  }) {
    final category = _normalizeCategory(profile.category);
    final age = _calculateAge(profile.dateOfBirth, onDate: referenceDate);
    final maxAge = _maxAgeForCategory(exam, category);
    final baseAttemptsAllowed = _attemptLimitForCategory(exam, category);
    final attemptsUsed = attemptsByExam[exam.id] ?? 0;

    int effectiveAge = age < exam.minAge ? exam.minAge : age;
    int remainingDueToAge = 0;
    if (effectiveAge <= maxAge) {
      remainingDueToAge = ((maxAge - effectiveAge) + 1) * exam.annualFrequency;
    }

    int fixedRemaining = baseAttemptsAllowed == -1
        ? remainingDueToAge
        : (baseAttemptsAllowed - attemptsUsed);

    if (fixedRemaining < 0) fixedRemaining = 0;

    int actualRemaining = remainingDueToAge < fixedRemaining
        ? remainingDueToAge
        : fixedRemaining;

    int calculatedAttemptsAllowed = attemptsUsed + actualRemaining;

    final qualificationOk = _checkQualification(exam, profile, docs);
    final ageOk = age >= exam.minAge && age <= maxAge;
    final attemptsOk = baseAttemptsAllowed == -1 || attemptsUsed < baseAttemptsAllowed;
    final docsOk = _checkDocs(exam, docs, profile);
    final categoryOk = category.isNotEmpty;

    final criteria = <String, bool>{
      'Age': ageOk,
      'Qualification': qualificationOk,
      'Attempts': attemptsOk,
      'Documents': docsOk,
      'Category': categoryOk,
    };

    final missing = criteria.entries
        .where((entry) => !entry.value)
        .map((entry) => _missingReason(entry.key, exam, calculatedAttemptsAllowed))
        .toList();

    final trueCount = criteria.values.where((v) => v).length;
    final matchPercent = ((trueCount / criteria.length) * 100).round();

    final isEligible = criteria.values.every((v) => v);
    
    // Check if they can be eligible in the near future (Upcoming)
    bool isUpcoming = false;
    if (!isEligible) {
      bool canFixAge = !ageOk && age < exam.minAge; // Too young
      bool canFixQual = !qualificationOk && profile.graduationStatus == 'Pursuing'; // Pursuing graduation
      
      // If the ONLY missing criteria are fixable by time
      isUpcoming = criteria.entries.every((e) {
        if (e.value) return true; // It's passed
        if (e.key == 'Age' && canFixAge) return true;
        if (e.key == 'Qualification' && canFixQual) return true;
        return false;
      });
      // But if they failed due to overage, they can NEVER be eligible
      if (!ageOk && age > maxAge) isUpcoming = false;
    }

    final status = isEligible
        ? 'ELIGIBLE'
        : isUpcoming
            ? 'UPCOMING'
            : 'INELIGIBLE';

    return EligibilityEvaluation(
      exam: exam,
      isEligible: isEligible,
      status: status,
      matchPercent: matchPercent,
      criteria: criteria,
      missingCriteria: missing,
      age: age,
      minAge: exam.minAge,
      maxAge: maxAge,
      attemptsUsed: attemptsUsed,
      attemptsAllowed: calculatedAttemptsAllowed,
      nextSteps: _buildNextSteps(exam, isEligible),
    );
  }

  List<FutureEligibilityProjection> projectFutureEligibility({
    required UserProfileModel profile,
    required List<AcademicDocModel> docs,
    required Map<String, int> attemptsByExam,
    Set<String>? examIds,
    List<ExamInfo>? allExams,
    int yearsAhead = 2,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final list = allExams ?? ExamData.allExams;
    final targetExams = list
        .where((exam) => examIds == null || examIds.contains(exam.id))
        .toList();

    final projections = <FutureEligibilityProjection>[];

    for (final exam in targetExams) {
      final yearlyEvaluations = <EligibilityEvaluation>[];
      for (var offset = 0; offset <= yearsAhead; offset++) {
        final refDate = DateTime(
          now.year + offset,
          now.month,
          now.day,
        );
        yearlyEvaluations.add(
          _evaluateOne(
            exam: exam,
            profile: profile,
            docs: docs,
            attemptsByExam: attemptsByExam,
            referenceDate: refDate,
          ),
        );
      }

      final firstEligible = yearlyEvaluations.cast<EligibilityEvaluation?>().firstWhere(
            (evaluation) => evaluation!.isEligible,
            orElse: () => null,
          );

      final chosen = firstEligible ?? yearlyEvaluations.last;
      final chosenIndex = yearlyEvaluations.indexOf(chosen);
      final yearsToEligibility = firstEligible == null ? -1 : chosenIndex;
      final blockers = chosen.missingCriteria;

      projections.add(
        FutureEligibilityProjection(
          exam: exam,
          year: now.year + chosenIndex,
          projectedEligible: chosen.isEligible,
          projectedAge: chosen.age,
          minAge: chosen.minAge,
          maxAge: chosen.maxAge,
          yearsToEligibility: yearsToEligibility,
          blockers: blockers,
          summary: _projectionSummary(
            exam: exam,
            projectionYear: now.year + chosenIndex,
            isEligible: chosen.isEligible,
            blockers: blockers,
          ),
        ),
      );
    }

    projections.sort((a, b) {
      if (a.projectedEligible != b.projectedEligible) {
        return a.projectedEligible ? -1 : 1;
      }
      return a.year.compareTo(b.year);
    });
    return projections;
  }

  String _projectionSummary({
    required ExamInfo exam,
    required int projectionYear,
    required bool isEligible,
    required List<String> blockers,
  }) {
    if (isEligible) {
      return '${exam.code}: eligible by $projectionYear';
    }
    if (blockers.isEmpty) {
      return '${exam.code}: not eligible by $projectionYear';
    }
    return '${exam.code}: ${blockers.first}';
  }

  int _calculateAge(String dob, {DateTime? onDate}) {
    if (dob.trim().isEmpty) return 0;
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return 0;
      final birth = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      final now = onDate ?? DateTime.now();
      var age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  String _normalizeCategory(String category) {
    final c = category.trim().toUpperCase();
    if (c == 'GENERAL') return 'GENERAL';
    if (c == 'OBC') return 'OBC';
    if (c == 'SC') return 'SC';
    if (c == 'ST') return 'ST';
    if (c == 'EWS') return 'EWS';
    return c;
  }

  int _maxAgeForCategory(ExamInfo exam, String category) {
    switch (category) {
      case 'OBC':
        return exam.maxAgeOBC;
      case 'SC':
        return exam.maxAgeSC;
      case 'ST':
        return exam.maxAgeST;
      default:
        return exam.maxAgeGeneral;
    }
  }

  int _attemptLimitForCategory(ExamInfo exam, String category) {
    switch (category) {
      case 'OBC':
        return exam.maxAttemptsOBC;
      case 'SC':
      case 'ST':
        return exam.maxAttemptsSCST;
      default:
        return exam.maxAttemptsGeneral;
    }
  }

  bool _checkQualification(
    ExamInfo exam,
    UserProfileModel profile,
    List<AcademicDocModel> docs,
  ) {
    final userLevel = _qualificationLevel(profile.qualification, docs);
    final requiredLevel = _requiredQualificationLevel(exam.qualification);
    if (userLevel < requiredLevel) return false;

    if (exam.qualification.toLowerCase().contains('60%')) {
      final pct = _bestPercentage(profile, docs);
      if (pct == null || pct < 60) return false;
    }

    return true;
  }

  bool _checkDocs(ExamInfo exam, List<AcademicDocModel> docs, UserProfileModel profile) {
    final has10th = docs.any((d) => d.docType == '10th');
    final has12th = docs.any((d) => d.docType == '12th');
    final hasGrad = docs.any((d) => d.docType == 'graduation');

    final qual = profile.qualification.toLowerCase();
    final hasQualificationFallback = qual.contains('10') ||
        qual.contains('12') ||
        qual.contains('grad');

    if (exam.qualification.contains('Graduation')) {
      return hasGrad || qual.contains('grad');
    }
    if (exam.qualification.contains('12th')) {
      return has12th || hasGrad || qual.contains('12') || qual.contains('grad');
    }
    if (exam.qualification.contains('10th')) {
      return has10th || has12th || hasGrad || hasQualificationFallback;
    }
    return hasQualificationFallback || docs.isNotEmpty;
  }

  int _qualificationLevel(String qualification, List<AcademicDocModel> docs) {
    final q = qualification.toLowerCase();
    if (q.contains('phd')) return 5;
    if (q.contains('post')) return 4;
    if (q.contains('grad')) return 3;
    if (q.contains('12')) return 2;
    if (q.contains('10')) return 1;

    final hasGrad = docs.any((d) => d.docType == 'graduation');
    final has12 = docs.any((d) => d.docType == '12th');
    final has10 = docs.any((d) => d.docType == '10th');

    if (hasGrad) return 3;
    if (has12) return 2;
    if (has10) return 1;
    return 0;
  }

  int _requiredQualificationLevel(String requirement) {
    final req = requirement.toLowerCase();
    if (req.contains('graduation')) return 3;
    if (req.contains('12th')) return 2;
    if (req.contains('10th')) return 1;
    return 0;
  }

  double? _bestPercentage(UserProfileModel profile, List<AcademicDocModel> docs) {
    final values = <double>[];
    final fromProfile = _normalizePercentage(profile.percentage);
    if (fromProfile != null) values.add(fromProfile);

    for (final doc in docs) {
      final p = _normalizePercentage(doc.aggregate);
      if (p != null) values.add(p);
    }

    if (values.isEmpty) return null;
    values.sort();
    return values.last;
  }

  double? _normalizePercentage(String raw) {
    if (raw.trim().isEmpty) return null;
    final value = raw.trim().toLowerCase();

    if (value.contains('cgpa')) {
      final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
      if (match == null) return null;
      final cgpa = double.tryParse(match.group(1)!);
      if (cgpa == null) return null;
      return cgpa * 9.5;
    }

    final numeric = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
    if (numeric == null) return null;
    return double.tryParse(numeric.group(1)!);
  }

  String _missingReason(String key, ExamInfo exam, int attemptsAllowed) {
    switch (key) {
      case 'Age':
        return 'Age is outside ${exam.minAge}-${exam.maxAgeGeneral} range';
      case 'Qualification':
        return 'Required qualification: ${exam.qualification}';
      case 'Attempts':
        return attemptsAllowed == -1
            ? 'Attempts data unavailable'
            : 'Attempt limit reached (max $attemptsAllowed)';
      case 'Documents':
        return 'Required academic documents not verified';
      case 'Category':
        return 'Social category is missing';
      default:
        return 'Some eligibility criteria are not satisfied';
    }
  }

  List<String> _buildNextSteps(ExamInfo exam, bool isEligible) {
    if (!isEligible) {
      return [
        'Update profile and re-check eligibility',
        'Verify missing documents in Documents tab',
      ];
    }

    return [
      'Open registration portal: ${exam.registrationUrl}',
      'Review official info: ${exam.officialInfoUrl}',
      ..._requiredDocuments(exam.id),
    ];
  }

  List<String> _requiredDocuments(String examId) {
    switch (examId) {
      case 'upsc_cse':
      case 'cds':
        return [
          '10th certificate (age proof)',
          'Graduation certificate/marksheets',
          'Category certificate (if applicable)',
        ];
      case 'nda':
        return [
          '12th marksheet/certificate',
          'Photo ID',
          'Category certificate (if applicable)',
        ];
      case 'afcat':
        return [
          'Graduation marksheets (min 60%)',
          '10th/12th certificates',
          'Government photo ID',
        ];
      case 'ibps_po':
      case 'ibps_clerk':
      case 'sbi_po':
      case 'rbi_grade_b':
        return [
          'Graduation certificate',
          'Photo ID',
          'Category certificate (if applicable)',
        ];
      case 'ssc_cgl':
      case 'ssc_chsl':
        return [
          'Academic qualification certificate',
          'Photo ID',
          'Category certificate (if applicable)',
        ];
      default:
        return ['Academic certificates', 'Photo ID'];
    }
  }
}
