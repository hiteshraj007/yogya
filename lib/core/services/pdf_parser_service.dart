import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

import 'ocr_service.dart';

/// Configuration for the deployed PDF parser microservice.
class PdfParserConfig {
  // Replace the link below with the exact URL from your Render dashboard 
  // (check if it has any extra characters like '-iarw' at the end)
  static String get baseUrl => 'https://yogya-pdf-parser-iarw.onrender.com';
}


/// Service that calls the local Python Flask PDF-parser microservice and
/// maps the JSON response to [OcrResult].
class PdfParserService {
  PdfParserService._();
  static final PdfParserService instance = PdfParserService._();

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  // ── Health check ──────────────────────────────────────────────────────────

  Future<bool> isServerAvailable() async {
    try {
      final resp = await _dio.get('${PdfParserConfig.baseUrl}/health');
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Parse PDF ─────────────────────────────────────────────────────────────

  Future<OcrResult> parsePdf(
    Uint8List pdfBytes, {
    String method = 'auto',
    int dpi = 300,
    String lang = 'eng',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(pdfBytes, filename: 'document.pdf'),
      });

      final resp = await _dio.post(
        '${PdfParserConfig.baseUrl}/parse-pdf',
        data: formData,
        queryParameters: {
          'method': method,
          'dpi': dpi.toString(),
          'lang': lang,
        },
      );

      if (resp.statusCode != 200) {
        return const OcrResult.failure(
          'PDF server returned an error. Is the server running?',
        );
      }

      final json = resp.data as Map<String, dynamic>?;
      if (json == null) {
        return const OcrResult.failure('Empty response from PDF parser.');
      }
      if (json.containsKey('error')) {
        return OcrResult.failure('PDF parser error: ${json['error']}');
      }

      return _mapToOcrResult(json);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const OcrResult.failure(
          'Cannot connect to PDF parser service.\n'
          'Please start it with: cd tools/pdf_parser && start.bat',
        );
      }
      return OcrResult.failure('Network error: ${e.message}');
    } catch (e) {
      return OcrResult.failure('Unexpected error: $e');
    }
  }

  // ── Parse Image ───────────────────────────────────────────────────────────

  Future<OcrResult> parseImage(
    Uint8List imageBytes, {
    String lang = 'eng',
    String filename = 'image.jpg',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(imageBytes, filename: filename),
      });
      final resp = await _dio.post(
        '${PdfParserConfig.baseUrl}/parse-image',
        data: formData,
        queryParameters: {'lang': lang},
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json.containsKey('error')) {
        return OcrResult.failure(
          json?['error']?.toString() ?? 'Empty image parse response.',
        );
      }
      return _mapToOcrResult(json);
    } on DioException catch (e) {
      return OcrResult.failure('Network error: ${e.message}');
    } catch (e) {
      return OcrResult.failure('Unexpected error: $e');
    }
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  OcrResult _mapToOcrResult(Map<String, dynamic> json) {
    // ── Core fields ──────────────────────────────────────────────────────
    final name        = _str(json['name'] ?? json['student_name']);
    final fatherName  = _str(json['father_name']);
    final motherName  = _str(json['mother_name']);
    final dob         = _normaliseDob(_str(json['dob'] ?? json['date_of_birth']));
    final rollNumber  = _str(json['roll_number']);
    final regNumber   = _str(json['registration_number']);
    final rawBoard    = _str(json['board_university'] ?? json['university'] ?? json['board'] ?? json['school']);
    final year        = _str(json['year'] ?? json['passing_year'] ?? json['year_of_passing']);
    final examText    = _str(json['exam'] ?? json['exam_name']);
    final schoolRaw   = _str(json['school'] ?? json['institution'] ?? json['college']);
    final rawCourse   = _str(json['course'] ?? json['course_name'] ?? json['program'] ?? json['degree']);
    final branch      = _str(json['branch'] ?? json['specialization'] ?? json['major']);
    final semester    = _str(json['semester'] ?? json['current_semester']);

    // ── Aggregate / percentage ───────────────────────────────────────────
    final rawCgpa    = json['cgpa'];
    final rawPercent = json['percentage'];
    final percentCgpa = json['percentage_cgpa'];

    String aggregate = '';
    if (rawCgpa != null) {
      final n = rawCgpa is num ? rawCgpa : num.tryParse(rawCgpa.toString());
      if (n != null && n > 0) aggregate = 'CGPA ${n.toStringAsFixed(2)}';
    } else if (rawPercent != null) {
      final n = rawPercent is num ? rawPercent : num.tryParse(rawPercent.toString());
      if (n != null && n > 0) aggregate = '${n.toStringAsFixed(1)}%';
    } else if (percentCgpa != null) {
      final n = percentCgpa is num ? percentCgpa : num.tryParse(percentCgpa.toString());
      if (n != null && n > 0) aggregate = '${n.toStringAsFixed(1)}%';
    }

    // ── Subject details ──────────────────────────────────────────────────
    final subjectDetails =
        (json['subject_details'] as List<dynamic>?) ??
        (json['subjects'] as List<dynamic>?) ??
        [];

    final subjectMarks = <String, String>{};
    for (final item in subjectDetails) {
      final s     = item as Map<String, dynamic>? ?? {};
      final sName = _str(s['name'] ?? s['subject']);
      if (sName.isEmpty) continue;
      final total = s['total_marks'] ?? s['marks_obtained'] ?? s['marks'];
      final max   = s['max_marks'] ?? s['maximum_marks'];
      final grade = _str(s['grade']);
      String display = '';
      if (total != null) {
        display = max != null
            ? '${_numStr(total)}/${_numStr(max)}'
            : _numStr(total);
        if (grade.isNotEmpty) display += ' ($grade)';
      } else if (grade.isNotEmpty) {
        display = grade;
      }
      subjectMarks[sName] = display;
    }

    // Fallback: legacy subjects_and_marks map
    if (subjectMarks.isEmpty) {
      final legacyMap =
          json['subjects_and_marks'] as Map<String, dynamic>? ?? {};
      legacyMap.forEach((k, v) {
        final sub   = v as Map<String, dynamic>? ?? {};
        final marks = sub['marks'];
        final max   = sub['max'];
        final grade = _str(sub['grade']);
        String display = '';
        if (marks != null) {
          display = max != null
              ? '${_numStr(marks)}/${_numStr(max)}'
              : _numStr(marks);
          if (grade.isNotEmpty) display += ' ($grade)';
        } else if (grade.isNotEmpty) {
          display = grade;
        }
        subjectMarks[k] = display;
      });
    }

    // ── Subjects JSON (for Hive persistence) ────────────────────────────
    final subjectsJson =
        subjectDetails.isNotEmpty ? jsonEncode(subjectDetails) : '';

    // ── Doc type ─────────────────────────────────────────────────────────
    final pyDocLevel = _str(json['doc_level'] ?? json['document_level']);
    final docType = pyDocLevel.isNotEmpty && pyDocLevel != 'unknown'
        ? _canonicalDocType(pyDocLevel)
        : _inferDocType(examText, rawBoard, subjectMarks, json);

    // ── Board ────────────────────────────────────────────────────────────
    final board = _inferBoard(rawBoard);

    // ── School / Institution ─────────────────────────────────────────────
    final school = schoolRaw.isNotEmpty ? schoolRaw : _extractSchool(rawBoard, docType);

    // ── Stream ───────────────────────────────────────────────────────────
    final stream = _inferStream(subjectMarks, docType);
    final courseName = _inferCourseName(
      explicitCourse: rawCourse,
      branch: branch,
      examText: examText,
      boardOrUniversity: rawBoard,
      school: schoolRaw,
    );
    final graduationStatus = _inferGraduationStatus(
      explicitStatus: _str(json['graduation_status'] ?? json['status']),
      examText: examText,
      semester: semester,
      year: year,
      docType: docType,
      boardOrUniversity: rawBoard,
    );

    // ── Confidence ───────────────────────────────────────────────────────
    final confidence = _computeConfidence(
      name: name,
      dob: dob,
      board: board,
      year: year,
      aggregate: aggregate,
      docType: docType,
      rollNumber: rollNumber,
      registrationNumber: regNumber,
      subjectMarks: subjectMarks,
    );

    return OcrResult(
      success: true,
      rawText: _buildRawText(json),
      docType: docType,
      board: board,
      year: year,
      aggregate: aggregate,
      stream: stream,
      dateOfBirth: dob,
      university: school.isNotEmpty ? school : rawBoard,
      courseName: courseName,
      graduationStatus: graduationStatus,
      examName: examText,
      rollNumber: rollNumber,
      registrationNumber: regNumber,
      candidateName: name,
      fatherName: fatherName,
      motherName: motherName,
      subjectMarks: subjectMarks,
      subjectsJson: subjectsJson,
      confidence: confidence,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _str(dynamic v) => v?.toString().trim() ?? '';

  String _numStr(dynamic v) {
    if (v == null) return '';
    if (v is double && v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  /// Normalise a raw DOB string to DD/MM/YYYY.
  String _normaliseDob(String raw) {
    if (raw.isEmpty) return '';
    // Already DD/MM/YYYY
    if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(raw)) return raw;
    // YYYY-MM-DD  or YYYY/MM/DD
    final isoMatch = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(raw);
    if (isoMatch != null) {
      return '${isoMatch.group(3)}/${isoMatch.group(2)}/${isoMatch.group(1)}';
    }
    // DD-MM-YYYY
    final dmyMatch = RegExp(r'(\d{1,2})[-.](\d{1,2})[-.](\d{4})').firstMatch(raw);
    if (dmyMatch != null) {
      return '${dmyMatch.group(1)}/${dmyMatch.group(2)}/${dmyMatch.group(3)}';
    }
    return raw;
  }

  /// Convert Python doc_level value to a canonical string.
  String _canonicalDocType(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('10') || r == 'tenth' || r == 'sslc' || r == 'matric') return '10th';
    if (r.contains('12') || r == 'twelfth' || r == 'hsc' || r == 'intermediate') return '12th';
    if (r.contains('pg') || r.contains('post') || r.contains('master') || r.contains('mba') || r.contains('mca') || r.contains('msc') || r.contains('mtech')) return 'pg';
    if (r.contains('diploma')) return 'diploma';
    if (r.contains('grad') || r.contains('ug') || r.contains('bachelor') || r.contains('degree')) return 'graduation';
    return raw.isNotEmpty ? raw : 'unknown';
  }

  String _inferDocType(
    String exam,
    String university,
    Map<String, String> subjects,
    Map<String, dynamic> json,
  ) {
    final text = '${exam.toLowerCase()} ${university.toLowerCase()} ${(_str(json['course'])).toLowerCase()}';

    // ── PG / Masters ─────────────────────────────────────────────────────
    if (text.contains('master') ||
        text.contains(' mba') ||
        text.contains(' mca') ||
        text.contains(' m.tech') ||
        text.contains(' m.sc') ||
        text.contains(' m.com') ||
        text.contains(' m.a') ||
        text.contains('post graduate') ||
        text.contains('postgraduate') ||
        text.contains('post-graduate')) {
      return 'pg';
    }

    // ── 12th / Higher Secondary ───────────────────────────────────────────
    if (text.contains('senior secondary') ||
        text.contains('higher secondary') ||
        text.contains('intermediate') ||
        text.contains('class xii') ||
        text.contains('class 12') ||
        text.contains('std xii') ||
        text.contains('std. xii') ||
        text.contains('std-xii') ||
        text.contains('grade xii') ||
        text.contains('grade 12') ||
        text.contains('+2') ||
        text.contains('plus two') ||
        text.contains('hsc') ||
        text.contains('12th') ||
        RegExp(r'\bxii\b').hasMatch(text)) {
      return '12th';
    }

    // ── 10th / Secondary ──────────────────────────────────────────────────
    if (text.contains('secondary school') ||
        text.contains('class x ') ||
        text.contains('class 10') ||
        text.contains('std x ') ||
        text.contains('std. x') ||
        text.contains('grade x ') ||
        text.contains('grade 10') ||
        text.contains('high school') ||
        text.contains('matric') ||
        text.contains('sslc') ||
        text.contains('10th') ||
        RegExp(r'\bx\b').hasMatch(text)) {
      return '10th';
    }

    // ── Diploma ───────────────────────────────────────────────────────────
    if (text.contains('diploma') || text.contains('polytechnic')) {
      return 'diploma';
    }

    // ── Graduation / UG ───────────────────────────────────────────────────
    if (text.contains('bachelor') ||
        text.contains(' b.tech') ||
        text.contains(' b.sc') ||
        text.contains(' b.com') ||
        text.contains(' b.a') ||
        text.contains(' bca') ||
        text.contains(' bba') ||
        text.contains(' be ') ||
        text.contains('degree') ||
        text.contains('graduation') ||
        text.contains('university') ||
        text.contains('college')) {
      return 'graduation';
    }

    // ── Fingerprint via subjects ──────────────────────────────────────────
    final keys = subjects.keys.map((k) => k.toLowerCase()).toList();

    final has10th = keys.any((k) =>
        k.contains('social science') ||
        k.contains('mathematics standard') ||
        k.contains('science (theory)') ||
        k.contains('hindi (course') ||
        k.contains('english comm'));
    if (has10th) return '10th';

    final has12th = keys.any((k) =>
        k.contains('physics') ||
        k.contains('chemistry') ||
        k.contains('accountancy') ||
        k.contains('economics') ||
        k.contains('political science') ||
        k.contains('history') ||
        k.contains('geography') ||
        k.contains('computer science') ||
        k.contains('biology'));
    if (has12th) return '12th';

    if (subjects.length >= 8) return '10th';
    if (subjects.length >= 4) return '12th';

    return 'unknown';
  }

  /// Comprehensive Indian board detector.
  String _inferBoard(String rawBoard) {
    final u = rawBoard.toLowerCase();
    if (u.isEmpty) return '';

    // ── National ──────────────────────────────────────────────────────────
    if (u.contains('cbse') || u.contains('central board of secondary')) return 'CBSE';
    if (u.contains('cisce') || u.contains('council for the indian')) return 'CISCE';
    if (u.contains('icse') || u.contains('indian certificate of secondary')) return 'ICSE';
    if (u.contains('isc') || u.contains('indian school certificate')) return 'ISC';
    if (u.contains('nios') || u.contains('national institute of open')) return 'NIOS';
    if (u.contains('igcse') || u.contains('cambridge')) return 'Cambridge (IGCSE)';
    if (u.contains('ib ') || u.contains('international baccalaureate')) return 'IB';

    // ── State boards ──────────────────────────────────────────────────────
    if (u.contains('rbse') || (u.contains('rajasthan') && u.contains('board'))) return 'RBSE (Rajasthan)';
    if (u.contains('up board') || u.contains('upmsp') || u.contains('uttar pradesh madhyamik') || u.contains('prayagraj') || u.contains('allahabad')) return 'UP Board';
    if (u.contains('bseb') || (u.contains('bihar') && u.contains('board'))) return 'BSEB (Bihar)';
    if (u.contains('mpbse') || u.contains('mp board') || (u.contains('madhya pradesh') && u.contains('board'))) return 'MPBSE';
    if (u.contains('msbshse') || (u.contains('maharashtra') && u.contains('board'))) return 'Maharashtra Board';
    if (u.contains('kseeb') || u.contains('karnataka board') || u.contains('karnataka secondary')) return 'KSEEB (Karnataka)';
    if (u.contains('pue') || u.contains('pre university')) return 'Karnataka PU Board';
    if (u.contains('wbchse') || u.contains('wbbse') || (u.contains('west bengal') && u.contains('board'))) return 'West Bengal Board';
    if (u.contains('tnbse') || (u.contains('tamil nadu') && u.contains('board'))) return 'Tamil Nadu Board';
    if (u.contains('gseb') || (u.contains('gujarat') && u.contains('board'))) return 'GSEB (Gujarat)';
    if (u.contains('bieap') || u.contains('andhra pradesh board') || (u.contains('andhra') && u.contains('intermediate'))) return 'BIEAP (Andhra Pradesh)';
    if (u.contains('tsbie') || (u.contains('telangana') && u.contains('board'))) return 'TSBIE (Telangana)';
    if (u.contains('pseb') || (u.contains('punjab') && u.contains('board'))) return 'PSEB (Punjab)';
    if (u.contains('hbse') || (u.contains('haryana') && u.contains('board'))) return 'HBSE (Haryana)';
    if (u.contains('jkbose') || u.contains('jammu') || u.contains('kashmir')) return 'JKBOSE';
    if (u.contains('hpbose') || (u.contains('himachal') && u.contains('board'))) return 'HPBOSE';
    if (u.contains('ubse') || u.contains('uttarakhand board')) return 'UBSE (Uttarakhand)';
    if (u.contains('cgbse') || (u.contains('chhattisgarh') && u.contains('board'))) return 'CGBSE';
    if (u.contains('bse odisha') || u.contains('chse') || (u.contains('odisha') && u.contains('board'))) return 'BSE Odisha';
    if (u.contains('dhse') || u.contains('vhse') || (u.contains('kerala') && u.contains('board'))) return 'DHSE (Kerala)';
    if (u.contains('ahsec') || u.contains('seba') || (u.contains('assam') && u.contains('board'))) return 'AHSEC/SEBA (Assam)';
    if (u.contains('jac ') || u.contains('jac board') || (u.contains('jharkhand') && u.contains('board'))) return 'JAC (Jharkhand)';
    if (u.contains('gbshse') || (u.contains('goa') && u.contains('board'))) return 'GBSHSE (Goa)';
    if (u.contains('mbse') || (u.contains('mizoram') && u.contains('board'))) return 'MBSE (Mizoram)';
    if (u.contains('tbse') || (u.contains('tripura') && u.contains('board'))) return 'TBSE (Tripura)';
    if (u.contains('mbose') || (u.contains('meghalaya') && u.contains('board'))) return 'MBOSE (Meghalaya)';
    if (u.contains('nbse') || (u.contains('nagaland') && u.contains('board'))) return 'NBSE (Nagaland)';
    if (u.contains('bsem') || u.contains('cohsem') || (u.contains('manipur') && u.contains('board'))) return 'BSEM/COHSEM (Manipur)';
    if (u.contains('sbse') || (u.contains('sikkim') && u.contains('board'))) return 'SBSE (Sikkim)';
    if (u.contains('arunachal') || u.contains('apse')) return 'APSE (Arunachal Pradesh)';
    if (u.contains('delhi board') || u.contains('directorate of education')) return 'Delhi Board';

    // Return the raw value trimmed if it looks like a proper board name
    final cleaned = rawBoard.trim();
    return cleaned.length > 5 ? cleaned : '';
  }

  /// Extract school/institution name (for 10th) from the raw board text or JSON.
  String _extractSchool(String rawBoard, String docType) {
    if (docType != '10th' && docType != '12th') return '';
    // If the board field contains something that looks like a school/centre name
    final lower = rawBoard.toLowerCase();
    if (lower.contains('school') || lower.contains('vidyalaya') || lower.contains('centre') || lower.contains('center')) {
      return rawBoard.trim();
    }
    return '';
  }

  String _inferStream(Map<String, String> subjects, String docType) {
    if (docType != '12th' && docType != 'graduation') return '';
    final keys = subjects.keys.map((k) => k.toLowerCase()).toList();
    final hasMath  = keys.any((k) => k.contains('math'));
    final hasBio   = keys.any((k) => k.contains('bio'));
    final hasChem  = keys.any((k) => k.contains('chem'));
    final hasPhy   = keys.any((k) => k.contains('phy'));
    final hasComm  = keys.any((k) => k.contains('account') || k.contains('commerce') || k.contains('business'));
    final hasArts  = keys.any((k) => k.contains('history') || k.contains('geography') || k.contains('political') || k.contains('sociology') || k.contains('psychology'));
    if (hasChem && hasPhy) {
      if (hasBio && !hasMath) return 'PCB';
      if (hasMath && !hasBio) return 'PCM';
      if (hasMath && hasBio) return 'PCMB';
      return 'Science';
    }
    if (hasComm) return 'Commerce';
    if (hasArts) return 'Arts / Humanities';
    return '';
  }

  String _inferCourseName({
    required String explicitCourse,
    required String branch,
    required String examText,
    required String boardOrUniversity,
    required String school,
  }) {
    String course = explicitCourse.trim();
    final spec = branch.trim();

    if (course.isEmpty) {
      final source = '$examText $boardOrUniversity $school'.toLowerCase();
      if (RegExp(r'\bb\.?\s*tech\b').hasMatch(source)) {
        course = 'B.Tech';
      } else if (RegExp(r'\bb\.?\s*e\.?\b').hasMatch(source)) {
        course = 'B.E.';
      } else if (RegExp(r'\bbca\b').hasMatch(source)) {
        course = 'BCA';
      } else if (RegExp(r'\bb\.?\s*sc\b').hasMatch(source)) {
        course = 'B.Sc';
      } else if (RegExp(r'\bb\.?\s*com\b').hasMatch(source)) {
        course = 'B.Com';
      } else if (RegExp(r'\bb\.?\s*a\.?\b').hasMatch(source)) {
        course = 'B.A.';
      }
    }

    if (course.isNotEmpty &&
        spec.isNotEmpty &&
        !course.toLowerCase().contains(spec.toLowerCase())) {
      return '$course in $spec';
    }
    return course;
  }

  String _inferGraduationStatus({
    required String explicitStatus,
    required String examText,
    required String semester,
    required String year,
    required String docType,
    required String boardOrUniversity,
  }) {
    final status = explicitStatus.trim();
    if (status.isNotEmpty) return status;
    if (docType != 'graduation' && docType != 'pg') return '';

    final source = '$examText $semester $boardOrUniversity'.toLowerCase();
    if (RegExp(r'\bsem(?:ester)?[\s.\-]?\d*\b').hasMatch(source) ||
        source.contains('sessional') ||
        source.contains('statement of marks')) {
      return 'Pursuing';
    }
    if (source.contains('degree certificate') ||
        source.contains('provisional certificate') ||
        source.contains('convocation') ||
        source.contains('final year')) {
      return 'Completed';
    }

    return '';
  }

  String _buildRawText(Map<String, dynamic> json) {
    final buf = StringBuffer();
    void add(String label, dynamic val) {
      if (val != null && val.toString().isNotEmpty) buf.writeln('$label: $val');
    }
    add('Doc Level', json['doc_level']);
    add('Name', json['name'] ?? json['student_name']);
    add('Father Name', json['father_name']);
    add('Mother Name', json['mother_name']);
    add('DOB', json['dob'] ?? json['date_of_birth']);
    add('Roll No', json['roll_number']);
    add('Registration No', json['registration_number']);
    add('University/Board', json['board_university'] ?? json['university'] ?? json['board']);
    add('School/Institution', json['school'] ?? json['institution']);
    add('Exam', json['exam'] ?? json['exam_name']);
    add('Year', json['year'] ?? json['passing_year']);
    add('Percentage', json['percentage']);
    add('CGPA', json['cgpa']);
    add('Total Marks', json['total_marks_obtained_outoff']);

    final subjects =
        (json['subject_details'] as List<dynamic>?) ??
        (json['subjects'] as List<dynamic>?) ??
        [];
    if (subjects.isNotEmpty) {
      buf.writeln('\nSubjects:');
      for (final item in subjects) {
        final s     = item as Map<String, dynamic>? ?? {};
        final name  = s['name'] ?? s['subject'] ?? '';
        final total = s['total_marks'] ?? s['marks_obtained'] ?? s['marks'];
        final max   = s['max_marks'] ?? s['maximum_marks'];
        final grade = s['grade'] ?? '';
        buf.writeln('  $name: $total/$max  Grade: $grade');
      }
    }
    return buf.toString().trim();
  }

  double _computeConfidence({
    required String name,
    required String dob,
    required String board,
    required String year,
    required String aggregate,
    required String docType,
    required String rollNumber,
    required String registrationNumber,
    required Map<String, String> subjectMarks,
  }) {
    double score = 0.0;
    if (docType != 'unknown') score += 0.22;
    if (board.isNotEmpty) score += 0.15;
    if (year.isNotEmpty) score += 0.10;
    if (aggregate.isNotEmpty) score += 0.18;
    if (dob.isNotEmpty) score += 0.10;
    if (name.isNotEmpty) score += 0.10;
    if (rollNumber.isNotEmpty) score += 0.07;
    if (registrationNumber.isNotEmpty) score += 0.04;
    if (subjectMarks.isNotEmpty) score += 0.04;
    return score.clamp(0.0, 1.0);
  }

  // ── Public name-normalisation utility (used for cross-doc consistency) ────

  /// Strips punctuation, lowercases, and collapses spaces for fuzzy matching.
  static String normaliseNameForComparison(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z\s]"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Returns true if [a] and [b] are likely the same person's name.
  static bool namesMatch(String a, String b) {
    if (a.isEmpty || b.isEmpty) return true; // can't contradict
    final na = normaliseNameForComparison(a);
    final nb = normaliseNameForComparison(b);
    if (na == nb) return true;
    // Containment check (e.g. "Rahul Kumar Sharma" vs "Rahul Kumar")
    if (na.contains(nb) || nb.contains(na)) return true;
    // Token overlap: at least 2 tokens must match
    final ta = na.split(' ').toSet();
    final tb = nb.split(' ').toSet();
    final common = ta.intersection(tb).where((t) => t.length > 1);
    return common.length >= 2;
  }
}
