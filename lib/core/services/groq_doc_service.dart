import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../constants/ai_config.dart';
import 'ai_doc_prompt.dart';
import 'ocr_service.dart';

class GroqDocService {
  GroqDocService._();
  static final GroqDocService instance = GroqDocService._();

  final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.groq.com/openai/v1',
    headers: {
      'Authorization': 'Bearer ${AiConfig.groqApiKey}',
      'Content-Type': 'application/json',
    },
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  Future<OcrResult?> analyzeDocument(Uint8List imageBytes, {String ocrRawText = ''}) async {
    if (AiConfig.groqApiKey.isEmpty) return null;

    try {
      final base64Image = base64Encode(imageBytes);
      
      // Use two-source prompt if OCR text is available
      final prompt = ocrRawText.isNotEmpty
          ? AiDocPrompt.twoSourcePrompt(ocrRawText)
          : AiDocPrompt.systemPrompt;

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': AiConfig.groqModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  }
                }
              ]
            }
          ],
          'temperature': 0.1,
          'response_format': {'type': 'json_object'}
        },
      );

      if (response.statusCode == 200) {
        String content = response.data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> jsonResponse = jsonDecode(content);
        return _mapJsonToOcrResult(jsonResponse);
      }
    } catch (e) {
      print('Groq Vision API Error: $e');
    }
    return null;
  }

  OcrResult _mapJsonToOcrResult(Map<String, dynamic> json) {
    final docLevel = OcrService.canonicalDocType(_read(json['doc_level'], fallback: 'unknown'));
    final name = _read(json['student_name']);
    final fatherName = _read(json['father_name']);
    final motherName = _read(json['mother_name']);
    final dob = _read(json['date_of_birth']);
    final rollNumber = _read(json['roll_number']);
    final regNumber = _read(json['registration_number']);
    final board = _read(json['board_university']);
    final school = _read(json['school_institution']);
    final examName = _read(json['exam_name']);
    final year = _read(json['year']);
    final courseName = _read(json['course_name']);
    final stream = _read(json['stream']);
    final graduationStatus = _inferGraduationStatus(json, docLevel);
    
    final cgpa = json['cgpa'];
    final percentage = json['percentage'];
    String aggregate = '';
    if (_hasValue(cgpa)) {
      aggregate = 'CGPA ${_read(cgpa)}';
    } else if (_hasValue(percentage)) {
      aggregate = '${_read(percentage)}%';
    } else {
      aggregate = _aggregateFromTotals(json);
    }

    final subjectDetails = (json['subject_details'] as List<dynamic>?) ?? [];
    final subjectMarks = <String, String>{};
    for (final item in subjectDetails) {
      final s = item as Map<String, dynamic>? ?? {};
      final sName = _read(s['name']);
      if (sName.isEmpty) continue;
      final total = s['total_marks'];
      final max = s['max_marks'];
      final grade = _read(s['grade']);
      
      String display = '';
      if (total != null && max != null) {
        display = '$total/$max';
        if (grade.isNotEmpty) display += ' ($grade)';
      } else if (total != null) {
        display = '$total';
        if (grade.isNotEmpty) display += ' ($grade)';
      } else if (grade.isNotEmpty) {
        display = grade;
      }
      subjectMarks[sName] = display;
    }

    double confidence = 0.0; // Recalculated by OcrPostProcessor

    return OcrResult(
      success: true,
      rawText: jsonEncode(json),
      docType: docLevel,
      board: board,
      year: year,
      aggregate: aggregate,
      stream: stream, 
      dateOfBirth: dob,
      university: school.isNotEmpty ? school : board,
      courseName: courseName,
      graduationStatus: graduationStatus,
      examName: examName,
      rollNumber: rollNumber,
      registrationNumber: regNumber,
      candidateName: _safeStudentName(name, fatherName, motherName),
      fatherName: fatherName,
      motherName: motherName,
      subjectMarks: subjectMarks,
      confidence: confidence,
    );
  }

  static String _read(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.toLowerCase() == 'null') return fallback;
    return text;
  }

  static bool _hasValue(dynamic value) => _read(value).isNotEmpty;

  static String _aggregateFromTotals(Map<String, dynamic> json) {
    final obtained = double.tryParse(_read(json['total_obtained']));
    final max = double.tryParse(_read(json['total_max']));
    if (obtained != null && max != null && max > 0 && obtained <= max) {
      return '${((obtained / max) * 100).toStringAsFixed(1)}%';
    }
    return '';
  }

  static String _safeStudentName(String name, String fatherName, String motherName) {
    final normalizedName = OcrService.normaliseNameForComparison(name);
    if (normalizedName.isEmpty) return '';
    if (OcrService.normaliseNameForComparison(fatherName) == normalizedName ||
        OcrService.normaliseNameForComparison(motherName) == normalizedName) {
      return '';
    }
    return name;
  }

  static String _inferGraduationStatus(Map<String, dynamic> json, String docLevel) {
    final raw = _read(json['graduation_status']);
    final allText = jsonEncode(json).toLowerCase();
    if (docLevel != 'graduation' && docLevel != 'pg') return raw;
    final hasFinalSignal = allText.contains('final year') ||
        allText.contains('8th sem') ||
        allText.contains('semester viii') ||
        allText.contains('degree certificate') ||
        allText.contains('provisional certificate') ||
        allText.contains('consolidated');
    if (hasFinalSignal) return 'Completed';
    final hasEarlySemester = RegExp(r'\b(semester|sem|part)\s*(i|ii|iii|iv|v|vi|vii|1|2|3|4|5|6|7)\b').hasMatch(allText) ||
        RegExp(r'\b(i|ii|iii|iv|v|vi|vii|1|2|3|4|5|6|7)\s*&\s*(ii|iii|iv|v|vi|vii|2|3|4|5|6|7)\b').hasMatch(allText);
    if (hasEarlySemester) return 'Pursuing';
    return raw.isEmpty ? 'Pursuing' : raw;
  }
}
