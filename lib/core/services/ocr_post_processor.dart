import 'ocr_service.dart';

/// Post-processes OcrResult from AI to fix common mistakes.
/// All rules are format-independent — they work for any Indian board/university.
class OcrPostProcessor {
  OcrPostProcessor._();

  /// Validate and fix an OcrResult. Returns a corrected copy.
  static OcrResult process(OcrResult result) {
    var r = result;
    r = _fixSubjectMarks(r);
    r = _fixPercentage(r);
    r = _fixCgpa(r);
    r = _fixNameSwaps(r);
    r = _fixDocLevel(r);
    r = _fixGraduationStatus(r);
    r = _recalculateConfidence(r);
    return r;
  }

  // ── Fix Subject Marks ─────────────────────────────────────
  /// - total_marks must be <= max_marks
  /// - max_marks per subject is typically 100, 70, 80, 150 (not 500, 1000)
  /// - If total_marks > max_marks, swap them
  static OcrResult _fixSubjectMarks(OcrResult r) {
    if (r.subjectMarks.isEmpty) return r;

    final fixed = <String, String>{};
    for (final entry in r.subjectMarks.entries) {
      final key = entry.key;
      final value = entry.value;

      // Parse "75/100" format
      final parts = value.split('/');
      if (parts.length == 2) {
        var obtained = int.tryParse(parts[0].trim().split(' ').first);
        var max = int.tryParse(parts[1].trim().split(' ').first);

        if (obtained != null && max != null) {
          // Swap if obtained > max
          if (obtained > max && max > 0) {
            final temp = obtained;
            obtained = max;
            max = temp;
          }

          // If max_marks is impossibly large for a single subject (>200), skip fix
          // but flag it — likely total row misidentified as subject
          if (max > 200) {
            // This is probably the total row, skip it
            continue;
          }

          // Negative marks → make 0
          if (obtained < 0) obtained = 0;

          // Rebuild value, preserving grade if present
          final gradeMatch = RegExp(r'\(([^)]+)\)').firstMatch(value);
          String newValue = '$obtained/$max';
          if (gradeMatch != null) newValue += ' (${gradeMatch.group(1)})';
          fixed[key] = newValue;
          continue;
        }
      }
      // Grade-only subject (Kerala SSLC etc.) — keep as-is
      // Values like "A+", "B", "C Only" are valid grade-only entries
      if (RegExp(r'^[A-E][+\-]?\s*(Plus|Only)?$', caseSensitive: false).hasMatch(value.trim())) {
        fixed[key] = value.trim();
        continue;
      }
      // Keep as-is if can't parse
      fixed[key] = value;
    }
    return r.copyWith(subjectMarks: fixed);
  }

  // ── Fix Percentage ────────────────────────────────────────
  /// - Must be 0-100
  /// - If we have total_obtained/total_max, verify math
  static OcrResult _fixPercentage(OcrResult r) {
    final aggregate = r.aggregate.trim();
    if (aggregate.isEmpty || aggregate.startsWith('CGPA')) return r;

    // Extract numeric percentage
    final pctMatch = RegExp(r'([\d.]+)%').firstMatch(aggregate);
    if (pctMatch == null) return r;

    final pct = double.tryParse(pctMatch.group(1)!);
    if (pct == null) return r;

    // If percentage > 100 or < 0, it's wrong
    if (pct > 100 || pct < 0) {
      // Try recalculating from subject marks
      final recalculated = _calculateFromSubjects(r);
      if (recalculated != null) {
        return r.copyWith(aggregate: '${recalculated.toStringAsFixed(1)}%');
      }
      return r.copyWith(aggregate: ''); // Can't fix, clear it
    }

    // Cross-check with subject totals if available
    final fromSubjects = _calculateFromSubjects(r);
    if (fromSubjects != null) {
      final diff = (pct - fromSubjects).abs();
      // If difference > 5%, prefer calculated value
      if (diff > 5.0) {
        return r.copyWith(aggregate: '${fromSubjects.toStringAsFixed(1)}%');
      }
    }

    return r;
  }

  /// Calculate percentage from subject marks
  static double? _calculateFromSubjects(OcrResult r) {
    if (r.subjectMarks.isEmpty) return null;

    double totalObtained = 0;
    double totalMax = 0;
    int validSubjects = 0;

    for (final value in r.subjectMarks.values) {
      final parts = value.split('/');
      if (parts.length == 2) {
        final obtained = double.tryParse(parts[0].trim().split(' ').first);
        final max = double.tryParse(parts[1].trim().split(' ').first);
        if (obtained != null && max != null && max > 0 && obtained <= max) {
          totalObtained += obtained;
          totalMax += max;
          validSubjects++;
        }
      }
    }

    if (validSubjects >= 3 && totalMax > 0) {
      return (totalObtained / totalMax) * 100;
    }
    return null;
  }

  // ── Fix CGPA ──────────────────────────────────────────────
  /// - Must be 0.0 to 10.0
  static OcrResult _fixCgpa(OcrResult r) {
    if (!r.aggregate.startsWith('CGPA')) return r;

    final cgpaMatch = RegExp(r'CGPA\s+([\d.]+)').firstMatch(r.aggregate);
    if (cgpaMatch == null) return r;

    final cgpa = double.tryParse(cgpaMatch.group(1)!);
    if (cgpa == null) return r;

    if (cgpa < 0 || cgpa > 10) {
      // Maybe it's percentage stored as CGPA — convert if > 10
      if (cgpa > 10 && cgpa <= 100) {
        return r.copyWith(aggregate: '${cgpa.toStringAsFixed(1)}%');
      }
      return r.copyWith(aggregate: ''); // Can't fix
    }

    return r;
  }

  // ── Fix Name Swaps ────────────────────────────────────────
  /// - student_name should not equal father_name or mother_name
  /// - student_name should not contain digits
  /// - Names shouldn't contain subject names
  static OcrResult _fixNameSwaps(OcrResult r) {
    var name = r.candidateName;
    final father = r.fatherName;
    final mother = r.motherName;

    // If name contains digits, it's probably wrong
    if (RegExp(r'\d').hasMatch(name)) {
      name = name.replaceAll(RegExp(r'[0-9]'), '').trim();
    }

    // If student name equals parent name, clear it
    if (name.isNotEmpty && OcrService.namesMatch(name, father) && father.isNotEmpty) {
      return r.copyWith(candidateName: '');
    }
    if (name.isNotEmpty && OcrService.namesMatch(name, mother) && mother.isNotEmpty) {
      return r.copyWith(candidateName: '');
    }

    // Check for subject names accidentally in name field
    final subjectKeywords = RegExp(
      r'\b(HINDI|ENGLISH|SANSKRIT|MATHEMATICS|SCIENCE|SOCIAL|PHYSICS|CHEMISTRY|BIOLOGY|ECONOMICS|ACCOUNTANCY|TOTAL|GRAND|MARKS|SUBJECT)\b',
      caseSensitive: false,
    );
    if (subjectKeywords.hasMatch(name)) {
      return r.copyWith(candidateName: '');
    }

    return r.copyWith(candidateName: name);
  }

  // ── Fix Doc Level ─────────────────────────────────────────
  /// Cross-check doc_level with raw text content
  static OcrResult _fixDocLevel(OcrResult r) {
    if (r.rawText.isEmpty) return r;
    final raw = r.rawText.toLowerCase();
    final current = r.docType;

    // If current is "unknown" or empty, try to detect
    if (current == 'unknown' || current.isEmpty) {
      return r.copyWith(docType: OcrService.canonicalDocType(_inferDocLevelFromText(raw)));
    }

    // Sanity check: if doc says "graduation" but text clearly has "class x" / "10th"
    if (current == 'graduation' &&
        (raw.contains('class x ') || raw.contains('class 10') || raw.contains('matric')) &&
        !raw.contains('bachelor') && !raw.contains('degree') && !raw.contains('university')) {
      return r.copyWith(docType: '10th');
    }

    // Sanity check: if doc says "10th" but text clearly says "intermediate" / "12th" / "higher secondary"
    if (current == '10th' &&
        (raw.contains('intermediate') || raw.contains('higher secondary') || raw.contains('senior secondary') ||
         raw.contains('class xii') || raw.contains('12th') || raw.contains('उच्च माध्यमिक') ||
         raw.contains('hsc') || raw.contains('pre-university'))) {
      return r.copyWith(docType: '12th');
    }

    return r;
  }

  static String _inferDocLevelFromText(String lower) {
    // Graduation / UG
    if (lower.contains('bachelor') || lower.contains('b.tech') || lower.contains('b.sc') ||
        lower.contains('b.com') || lower.contains('b.a.') || lower.contains('bba') ||
        lower.contains('bca') || lower.contains('degree') || lower.contains('cgpa') ||
        lower.contains('स्नातक')) return 'graduation';
    // PG
    if (lower.contains('master') || lower.contains('m.tech') || lower.contains('m.sc') ||
        lower.contains('m.com') || lower.contains('m.a.') || lower.contains('mba') ||
        lower.contains('mca') || lower.contains('post graduate') ||
        lower.contains('स्नातकोत्तर')) return 'pg';
    // 12th — check BEFORE 10th because "secondary" appears in both
    if (lower.contains('senior secondary') || lower.contains('higher secondary') ||
        lower.contains('class xii') || lower.contains('12th') || lower.contains('intermediate') ||
        lower.contains('hsc') || lower.contains('pre-university') || lower.contains('puc') ||
        lower.contains('उच्च माध्यमिक') || lower.contains('+2') ||
        lower.contains('inter science') || lower.contains('inter arts') ||
        lower.contains('inter commerce')) return '12th';
    // 10th
    if (lower.contains('secondary school leaving') || lower.contains('class x ') ||
        lower.contains('class x,') || lower.contains('(class - x)') ||
        lower.contains('10th') || lower.contains('matric') || lower.contains('sslc') ||
        lower.contains('madhyamik') || lower.contains('माध्यमिक') ||
        lower.contains('high school') || lower.contains('x standard')) return '10th';
    // Diploma
    if (lower.contains('diploma') || lower.contains('polytechnic')) return 'diploma';
    return 'unknown';
  }

  // ── Fix Graduation Status ─────────────────────────────────
  static OcrResult _fixGraduationStatus(OcrResult r) {
    if (r.docType != 'graduation' && r.docType != 'pg') return r;
    // Already handled well in the services, just ensure it's not empty
    if (r.graduationStatus.isEmpty) {
      return r.copyWith(graduationStatus: 'Pursuing');
    }
    return r;
  }

  // ── Recalculate Confidence ────────────────────────────────
  /// Calculate real confidence based on how many fields look valid.
  static OcrResult _recalculateConfidence(OcrResult r) {
    double score = 0.0;

    // Doc type detected
    if (r.docType.isNotEmpty && r.docType != 'unknown') score += 0.12;

    // Student name present and reasonable
    if (r.candidateName.isNotEmpty && r.candidateName.length >= 3 && !RegExp(r'\d').hasMatch(r.candidateName)) {
      score += 0.12;
    }

    // At least one parent name
    if (r.fatherName.isNotEmpty || r.motherName.isNotEmpty) score += 0.08;

    // Board/university
    if (r.board.isNotEmpty) score += 0.10;

    // Year
    if (r.year.isNotEmpty) score += 0.08;

    // Aggregate/percentage
    if (r.aggregate.isNotEmpty) score += 0.12;

    // Roll/registration number
    if (r.rollNumber.isNotEmpty || r.registrationNumber.isNotEmpty) score += 0.08;

    // Subject marks present
    if (r.subjectMarks.isNotEmpty && r.subjectMarks.length >= 3) score += 0.12;

    // Percentage math consistency check
    if (r.aggregate.contains('%') && r.subjectMarks.isNotEmpty) {
      final fromSubjects = _calculateFromSubjects(r);
      final pctMatch = RegExp(r'([\d.]+)%').firstMatch(r.aggregate);
      if (fromSubjects != null && pctMatch != null) {
        final pct = double.tryParse(pctMatch.group(1)!);
        if (pct != null && (pct - fromSubjects).abs() < 3.0) {
          score += 0.10; // Math checks out!
        }
      }
    } else if (r.aggregate.startsWith('CGPA')) {
      final cgpaMatch = RegExp(r'CGPA\s+([\d.]+)').firstMatch(r.aggregate);
      if (cgpaMatch != null) {
        final cgpa = double.tryParse(cgpaMatch.group(1)!);
        if (cgpa != null && cgpa >= 0 && cgpa <= 10) score += 0.10;
      }
    }

    // DOB present (only for 10th)
    if (r.docType == '10th') {
      if (r.dateOfBirth.isNotEmpty) score += 0.08;
    }

    return r.copyWith(confidence: score.clamp(0.0, 1.0));
  }
}
