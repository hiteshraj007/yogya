import 'ocr_service.dart';

/// Merges results from two AI models (Groq + Gemini) into one best result.
/// Logic: Where both agree → high confidence. Where they disagree → pick
/// the one that looks more valid based on heuristic rules.
class AiConsensusMerger {
  AiConsensusMerger._();

  /// Merge two OcrResults into one best result.
  /// [primary] is typically the first to respond (e.g., Groq).
  /// [secondary] is the other model (e.g., Gemini).
  static OcrResult merge(OcrResult primary, OcrResult secondary) {
    return OcrResult(
      success: true,
      rawText: primary.rawText.isNotEmpty ? primary.rawText : secondary.rawText,
      docType: _pickDocType(primary, secondary),
      board: _pickNonEmpty(primary.board, secondary.board),
      year: _pickYear(primary.year, secondary.year),
      aggregate: _pickAggregate(primary.aggregate, secondary.aggregate),
      stream: _pickNonEmpty(primary.stream, secondary.stream),
      dateOfBirth: _pickDob(primary.dateOfBirth, secondary.dateOfBirth),
      university: _pickNonEmpty(primary.university, secondary.university),
      courseName: _pickNonEmpty(primary.courseName, secondary.courseName),
      graduationStatus: _pickNonEmpty(primary.graduationStatus, secondary.graduationStatus),
      examName: _pickNonEmpty(primary.examName, secondary.examName),
      rollNumber: _pickNonEmpty(primary.rollNumber, secondary.rollNumber),
      registrationNumber: _pickNonEmpty(primary.registrationNumber, secondary.registrationNumber),
      candidateName: _pickName(primary.candidateName, secondary.candidateName, primary.fatherName, primary.motherName),
      fatherName: _pickNonEmpty(primary.fatherName, secondary.fatherName),
      motherName: _pickNonEmpty(primary.motherName, secondary.motherName),
      subjectMarks: _pickSubjectMarks(primary.subjectMarks, secondary.subjectMarks),
      confidence: 0.0, // Will be recalculated by post-processor
      imagePath: primary.imagePath ?? secondary.imagePath,
    );
  }

  // ── Pick best doc_type ──────────────────────────────────
  static String _pickDocType(OcrResult a, OcrResult b) {
    if (a.docType == b.docType) return a.docType;
    // If one is "unknown" and other is specific, pick specific
    if (a.docType == 'unknown' || a.docType.isEmpty) return b.docType;
    if (b.docType == 'unknown' || b.docType.isEmpty) return a.docType;
    // Both have different valid types — prefer the one that has more supporting data
    final aScore = _docTypeSupport(a);
    final bScore = _docTypeSupport(b);
    return aScore >= bScore ? a.docType : b.docType;
  }

  static int _docTypeSupport(OcrResult r) {
    int score = 0;
    if (r.board.isNotEmpty) score++;
    if (r.candidateName.isNotEmpty) score++;
    if (r.subjectMarks.isNotEmpty) score++;
    if (r.aggregate.isNotEmpty) score++;
    if (r.year.isNotEmpty) score++;
    return score;
  }

  // ── Pick non-empty ─────────────────────────────────────
  static String _pickNonEmpty(String a, String b) {
    if (a.isNotEmpty && b.isNotEmpty) {
      // Both have values — prefer longer (usually more complete)
      return a.length >= b.length ? a : b;
    }
    return a.isNotEmpty ? a : b;
  }

  // ── Pick Year ──────────────────────────────────────────
  static String _pickYear(String a, String b) {
    if (a == b) return a;
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    // Both present but different — pick more recent (likely exam year)
    final ya = int.tryParse(a) ?? 0;
    final yb = int.tryParse(b) ?? 0;
    final currentYear = DateTime.now().year;
    // Prefer the one closer to current year but not in future
    if (ya <= currentYear && yb > currentYear) return a;
    if (yb <= currentYear && ya > currentYear) return b;
    return ya >= yb ? a : b;
  }

  // ── Pick Aggregate ─────────────────────────────────────
  static String _pickAggregate(String a, String b) {
    if (a == b) return a;
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;

    // Both have values — validate each
    final aValid = _isValidAggregate(a);
    final bValid = _isValidAggregate(b);

    if (aValid && !bValid) return a;
    if (bValid && !aValid) return b;

    // Both valid — prefer percentage over CGPA for consistency
    if (a.contains('%') && b.startsWith('CGPA')) return a;
    if (b.contains('%') && a.startsWith('CGPA')) return b;

    return a; // Default to primary
  }

  static bool _isValidAggregate(String val) {
    if (val.contains('%')) {
      final pct = double.tryParse(RegExp(r'([\d.]+)').firstMatch(val)?.group(1) ?? '');
      return pct != null && pct >= 0 && pct <= 100;
    }
    if (val.startsWith('CGPA')) {
      final cgpa = double.tryParse(RegExp(r'([\d.]+)').firstMatch(val)?.group(1) ?? '');
      return cgpa != null && cgpa >= 0 && cgpa <= 10;
    }
    return val.isNotEmpty;
  }

  // ── Pick DOB ───────────────────────────────────────────
  static String _pickDob(String a, String b) {
    if (a == b) return a;
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    // Both present — prefer the one in DD/MM/YYYY format
    final aFormat = RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(a);
    final bFormat = RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(b);
    if (aFormat && !bFormat) return a;
    if (bFormat && !aFormat) return b;
    return a;
  }

  // ── Pick Name ──────────────────────────────────────────
  static String _pickName(String a, String b, String fatherName, String motherName) {
    if (a == b) return a;
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;

    // Disqualify if name matches parent
    final aIsParent = OcrService.namesMatch(a, fatherName) || OcrService.namesMatch(a, motherName);
    final bIsParent = OcrService.namesMatch(b, fatherName) || OcrService.namesMatch(b, motherName);
    if (aIsParent && !bIsParent) return b;
    if (bIsParent && !aIsParent) return a;

    // Disqualify if name has digits
    if (RegExp(r'\d').hasMatch(a) && !RegExp(r'\d').hasMatch(b)) return b;
    if (RegExp(r'\d').hasMatch(b) && !RegExp(r'\d').hasMatch(a)) return a;

    // Prefer the one with more words (full name vs partial)
    final aWords = a.trim().split(RegExp(r'\s+')).length;
    final bWords = b.trim().split(RegExp(r'\s+')).length;
    if (aWords >= 2 && bWords < 2) return a;
    if (bWords >= 2 && aWords < 2) return b;

    return a; // Default to primary
  }

  // ── Pick Subject Marks ─────────────────────────────────
  static Map<String, String> _pickSubjectMarks(Map<String, String> a, Map<String, String> b) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    // Prefer the one with more subjects (more complete extraction)
    if (a.length > b.length) return a;
    if (b.length > a.length) return b;
    // Same count — prefer primary
    return a;
  }
}
