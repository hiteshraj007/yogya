// import 'dart:io';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;

// import 'package:image_cropper/image_cropper.dart';
// import 'package:flutter/material.dart';

// // ── Extracted data ka structure ───────────────────────────
// class OcrResult {
//   final bool success;
//   final String rawText;
//   final String docType;
//   final String board;
//   final String year;
//   final String aggregate;
//   final String stream;
//   final String dateOfBirth;
//   final String university; 
//   final String examName; // For Admit Card
//   final String rollNumber; // For Admit Card
//   final double confidence;
//   final String? errorMessage;

//   const OcrResult({
//     required this.success,
//     required this.rawText,
//     this.docType = '',
//     this.board = '',
//     this.year = '',
//     this.aggregate = '',
//     this.stream = '',
//     this.dateOfBirth = '',
//     this.university = '', 
//     this.examName = '', 
//     this.rollNumber = '', 
//     this.confidence = 0.0,
//     this.errorMessage,
//   });

//   const OcrResult.failure(this.errorMessage)
//       : success = false,
//         rawText = '',
//         docType = '',
//         board = '',
//         year = '',
//         aggregate = '',
//         stream = '',
//         dateOfBirth = '',
//         university = '', 
//         examName = '',
//         rollNumber = '',
//         confidence = 0.0;
// }

// class OcrService {
//   OcrService._();
//   static final OcrService instance = OcrService._();

//   final _textRecognizer = TextRecognizer(
//     script: TextRecognitionScript.latin,
//   );

//   final _imagePicker = ImagePicker();

//   // ── Smart Cropper (Phase 1) ───────────────────────────
//   Future<File?> _cropImage(File imageFile) async {
//     final croppedFile = await ImageCropper().cropImage(
//       sourcePath: imageFile.path,
//       compressQuality: 100, // OCR needs high quality
//       uiSettings: [
//         AndroidUiSettings(
//             toolbarTitle: 'Adjust Document',
//             toolbarColor: const Color(0xFF131317),
//             toolbarWidgetColor: Colors.white,
//             initAspectRatio: CropAspectRatioPreset.original,
//             lockAspectRatio: false,
//             hideBottomControls: false,
//             activeControlsWidgetColor: const Color(0xFF6C5CE7), // Primary Yogya
//             dimmedLayerColor: Colors.black.withOpacity(0.8),
//         ),
//         IOSUiSettings(
//           title: 'Adjust Document',
//           aspectRatioLockEnabled: false,
//           resetAspectRatioEnabled: true,
//         ),
//       ],
//     );
//     if (croppedFile != null) {
//       return File(croppedFile.path);
//     }
//     return null;
//   }

//   // ── Camera se image lo ────────────────────────────────
//   Future<File?> pickFromCamera() async {
//     try {
//       final picked = await _imagePicker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 100, // Important for OCR
//         preferredCameraDevice: CameraDevice.rear,
//       );
//       if (picked == null) return null;
//       return _cropImage(File(picked.path));
//     } catch (e) {
//       return null;
//     }
//   }

//   // ── Gallery se image lo ───────────────────────────────
//   Future<File?> pickFromGallery() async {
//     try {
//       final picked = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 100,
//       );
//       if (picked == null) return null;
//       return _cropImage(File(picked.path));
//     } catch (e) {
//       return null;
//     }
//   }

//   // ── Main OCR function (Layer 1 & 2 Included) ──────────
//   Future<OcrResult> extractText(File imageFile) async {
//     try {
//       // ── Layer 1: Image Pre-processing ───────────────────
//       final bytes = await imageFile.readAsBytes();
//       var image = img.decodeImage(bytes);
      
//       if (image != null) {
//         // Grayscale conversion
//         image = img.grayscale(image);
//         // Contrast adjustment
//         image = img.adjustColor(image, contrast: 1.5);
        
//         final processedPath = '${imageFile.path}_processed.jpg';
//         final processedFile = File(processedPath);
//         await processedFile.writeAsBytes(img.encodeJpg(image, quality: 90));
        
//         // Pass processed image to vision
//         imageFile = processedFile;
//       }
      
//       final inputImage = InputImage.fromFile(imageFile);
//       final recognized = await _textRecognizer.processImage(inputImage);
      
//       // ── Layer 2: Layout Sensing & Parsing ────────────────
//       // We gather structured text blocks to maintain layout order
//       final rawText = recognized.blocks.map((b) => b.text).join('\n');

//       if (rawText.trim().isEmpty) {
//         return const OcrResult.failure(
//           'No text found. Please take a clearer photo.',
//         );
//       }

//       final result = _parseText(rawText);

//       // Privacy — raw image purge karo
//       await imageFile.delete();

//       return result;
//     } catch (e) {
//       return OcrResult.failure('OCR failed: ${e.toString()}');
//     }
//   }

//   // ── Text parser ───────────────────────────────────────
//   OcrResult _parseText(String text) {
//     // ── DATA PARSING ─────────────────────────────────────
//     String docType = _detectDocType(text);
//     String dob = _extractDOB(text);
//     String board = _extractBoard(text);
//     String year = _extractYear(text);
    
//     // Applying Layout Intelligence based on board
//     String aggregate = _extractAggregate(text, docType, board);
//     String stream = _extractStream(text);
//     String university = _extractUniversity(text);
    
//     // Admit Card specifics
//     String examName = '';
//     String rollNumber = '';
//     if (docType == 'admit_card') {
//       examName = _extractAdmitCardExamName(text);
//       rollNumber = _extractRollNumber(text);
//     }

//     final confidence = _calculateConfidence(
//       dob,
//       board,
//       year,
//       aggregate,
//       docType,
//     );

//     return OcrResult(
//       success: true,
//       rawText: text,
//       docType: docType,
//       board: board,
//       year: year,
//       aggregate: aggregate,
//       stream: stream,
//       dateOfBirth: dob,
//       university: university,
//       examName: examName,
//       rollNumber: rollNumber,
//       confidence: confidence,
//     );
//   }

//   // ── Doc type detect ───────────────────────────────────
//   String _detectDocType(String text) {
//     final lowerText = text.toLowerCase();
    
//     if (lowerText.contains('admit card') || 
//         lowerText.contains('hall ticket') || 
//         lowerText.contains('e-admit') || 
//         lowerText.contains('call letter')) {
//       return 'admit_card';
//     }

//     if (lowerText.contains('senior secondary') ||
//         lowerText.contains('higher secondary') ||
//         lowerText.contains('intermediate') ||
//         lowerText.contains('class xii') ||
//         lowerText.contains('class 12') ||
//         lowerText.contains('12th') ||
//         lowerText.contains('hsc') ||
//         lowerText.contains('std. xii') ||
//         lowerText.contains('std xii') ||
//         lowerText.contains('grade xii') ||
//         lowerText.contains('grade 12') ||
//         lowerText.contains('plus two') ||
//         lowerText.contains('+2')) {
//       return '12th';
//     }

//     if (lowerText.contains('secondary') ||
//         lowerText.contains('class x') ||
//         lowerText.contains('class 10') ||
//         lowerText.contains('10th') ||
//         lowerText.contains('matric') ||
//         lowerText.contains('sslc') ||
//         lowerText.contains('std. x') ||
//         lowerText.contains('std x') ||
//         lowerText.contains('grade x') ||
//         lowerText.contains('grade 10') ||
//         lowerText.contains('high school')) {
//       return '10th';
//     }

//     if (lowerText.contains('bachelor') ||
//         lowerText.contains('degree') ||
//         lowerText.contains('graduation') ||
//         lowerText.contains('university') ||
//         lowerText.contains('cgpa') ||
//         lowerText.contains('b.tech') ||
//         lowerText.contains('b.sc') ||
//         lowerText.contains('b.com') ||
//         lowerText.contains('b.a')) {
//       return 'graduation';
//     }

//     if (lowerText.contains('marks statement') ||
//         lowerText.contains('statement of marks') ||
//         lowerText.contains('marksheet') ||
//         lowerText.contains('mark sheet')) {
//       if (lowerText.contains('xii') || lowerText.contains('12')) return '12th';
//       if (lowerText.contains('x') || lowerText.contains('10')) return '10th';
//     }

//     return 'unknown';
//   }

//   // ── DOB extract — improved ────────────────────────────
//   String _extractDOB(String text) {
//     final lowerText = text.toLowerCase();
    
//     final dobKeywords = [
//       'date of birth', 'dob', 'd.o.b', 'birth date',
//       'जन्म तिथि', 'जन्मतिथि', 'birth dt', 'dt of birth'
//     ];

//     String searchArea = text;
//     for (final keyword in dobKeywords) {
//       final idx = lowerText.indexOf(keyword);
//       if (idx != -1) {
//         searchArea = text.substring(
//           idx,
//           (idx + 100).clamp(0, text.length),
//         );
//         break;
//       }
//     }

//     final patterns = [
//       // Standard DD/MM/YYYY
//       RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b'),
//       // YYYY/MM/DD
//       RegExp(r'\b(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})\b'),
//       // 15th August 2000
//       RegExp(
//         r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(\d{4})\b',
//         caseSensitive: false,
//       ),
//       // August 15, 2000
//       RegExp(
//         r'\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(\d{1,2})(?:st|nd|rd|th)?\,?\s+(\d{4})\b',
//         caseSensitive: false,
//       ),
//     ];

//     for (final pattern in patterns) {
//       final match = pattern.firstMatch(searchArea);
//       if (match != null) return _formatDate(match, pattern.pattern);
//     }

//     for (final pattern in patterns) {
//       final match = pattern.firstMatch(text);
//       if (match != null) return _formatDate(match, pattern.pattern);
//     }

//     return '';
//   }

//   // ── Date format helper ────────────────────────────────
//   String _formatDate(RegExpMatch match, String pattern) {
//     // DD Month YYYY format
//     if (pattern.contains('january|february')) {
//       final months = {
//         'january': '01',
//         'february': '02',
//         'march': '03',
//         'april': '04',
//         'may': '05',
//         'june': '06',
//         'july': '07',
//         'august': '08',
//         'september': '09',
//         'october': '10',
//         'november': '11',
//         'december': '12',
//       };
//       final month = months[match.group(2)!.toLowerCase()] ?? '00';
//       return '${match.group(1)!.padLeft(2, '0')}/$month/${match.group(3)}';
//     }
//     // YYYY/MM/DD → DD/MM/YYYY
//     if (pattern.startsWith(r'\b(\d{4})')) {
//       return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
//     }
//     // DD/MM/YYYY ya DD/MM/YY
//     return '${match.group(1)}/${match.group(2)}/${match.group(3)}';
//   }

//   // ── Board extract ─────────────────────────────────────
//   String _extractBoard(String text) {
//     final lower = text.toLowerCase();
//     if (lower.contains('cbse') || lower.contains('central board of secondary')) return 'CBSE';
//     if (lower.contains('icse') || lower.contains('council for the indian')) return 'ICSE';
//     if (lower.contains('isc') || lower.contains('indian school certificate')) return 'ISC';
//     if (lower.contains('nios') || lower.contains('national institute of open')) return 'NIOS';
//     if (lower.contains('cisce')) return 'CISCE';
    
//     if (lower.contains('rajasthan') || lower.contains('rbse') || lower.contains('ajmer')) return 'RBSE (Rajasthan)';
//     if (lower.contains('up board') || lower.contains('uttar pradesh madhyamik') || lower.contains('allahabad') || lower.contains('prayagraj')) return 'UP Board';
//     if (lower.contains('delhi')) return 'Delhi Board';
//     if (lower.contains('maharashtra') || lower.contains('msbshse')) return 'Maharashtra State Board';
//     if (lower.contains('karnataka') || lower.contains('kseeb') || lower.contains('pue')) return 'Karnataka Board';
//     if (lower.contains('tamil') || lower.contains('tn board')) return 'Tamil Nadu Board';
//     if (lower.contains('gujarat') || lower.contains('gseb')) return 'Gujarat Board';
//     if (lower.contains('bihar') || lower.contains('bseb')) return 'Bihar Board';
//     if (lower.contains('mp board') || lower.contains('madhya pradesh') || lower.contains('mpbse')) return 'MP Board';
//     if (lower.contains('west bengal') || lower.contains('wbchse')) return 'West Bengal Board';
//     if (lower.contains('telangana') || lower.contains('tsbie')) return 'Telangana Board';
//     if (lower.contains('andhra') || lower.contains('bieap')) return 'Andhra Pradesh Board';
//     if (lower.contains('punjab') || lower.contains('pseb')) return 'Punjab Board';
//     if (lower.contains('haryana') || lower.contains('hbse')) return 'Haryana Board';
//     if (lower.contains('jharkhand') || lower.contains('jac board') || lower.contains('jac ranchi')) return 'Jharkhand Board';
//     if (lower.contains('chhattisgarh') || lower.contains('cgbse')) return 'Chhattisgarh Board';
//     if (lower.contains('odisha') || lower.contains('orissa') || lower.contains('chse odisha') || lower.contains('bse odisha')) return 'Odisha Board';
//     if (lower.contains('kerala') || lower.contains('dhse') || lower.contains('vhse')) return 'Kerala Board';
//     if (lower.contains('assam') || lower.contains('ahsec') || lower.contains('seba')) return 'Assam Board';
//     if (lower.contains('jammu') || lower.contains('kashmir') || lower.contains('jkbose')) return 'JKBOSE';
//     if (lower.contains('himachal') || lower.contains('hpbose')) return 'HP Board';
//     if (lower.contains('uttarakhand') || lower.contains('ubse')) return 'Uttarakhand Board';
//     if (lower.contains('goa board') || lower.contains('gbshse')) return 'Goa Board';
//     if (lower.contains('manipur') || lower.contains('bsem') || lower.contains('cohsem')) return 'Manipur Board';
//     if (lower.contains('tripura') || lower.contains('tbse')) return 'Tripura Board';
//     if (lower.contains('meghalaya') || lower.contains('mbose')) return 'Meghalaya Board';
//     if (lower.contains('nagaland') || lower.contains('nbse')) return 'Nagaland Board';
//     if (lower.contains('mizoram') || lower.contains('mbse')) return 'Mizoram Board';
//     if (lower.contains('sikkim') || lower.contains('sbse')) return 'Sikkim Board';
//     if (lower.contains('arunachal') || lower.contains('apse')) return 'Arunachal Pradesh Board';
    
//     return '';
//   }

//   // ── Year extract ──────────────────────────────────────
//   String _extractYear(String text) {
//     final lowerText = text.toLowerCase();
    
//     // Search for keywords like Session, Year, Exam Year
//     final yearKeywords = ['session', 'year of passing', 'exam year', 'year:', 'passing year'];
//     String searchArea = text;
//     for (final kw in yearKeywords) {
//       final idx = lowerText.indexOf(kw);
//       if (idx != -1) {
//         searchArea = text.substring(idx, (idx + 50).clamp(0, text.length));
//         break;
//       }
//     }

//     final yearPattern = RegExp(r'\b(20\d{2})\b');
    
//     // First in searchArea
//     final areaMatches = yearPattern.allMatches(searchArea).toList();
//     if (areaMatches.isNotEmpty) {
//       return areaMatches.last.group(1)!;
//     }

//     // Then in full text
//     final matches = yearPattern.allMatches(text).toList();
//     if (matches.isEmpty) return '';
//     final years = matches
//         .map((m) => int.tryParse(m.group(1) ?? '') ?? 0)
//         .where((y) => y >= 2000 && y <= DateTime.now().year + 1)
//         .toList()
//       ..sort();
//     return years.isNotEmpty ? years.last.toString() : '';
//   }

//   // ── Aggregate/CGPA extract — Layout Intelligence ────────
//   String _extractAggregate(String text, String docType, String board) {
//     if (docType == 'admit_card') return ''; 

//     final normalized = text
//         .toLowerCase()
//         .replaceAll('o/', '0/')
//         .replaceAll('o ', '0 ')
//         .replaceAll(' l ', ' 1 ');

//     // 1) Board-specific known patterns
//     if (board == 'CBSE' || board == 'ICSE' || board == 'ISC') {
//       final boardCgpa = RegExp(
//         r'(overall|total)?\s*cgpa\s*[:\-]?\s*(\d+(?:[\.,]\d{1,2})?)',
//         caseSensitive: false,
//       ).firstMatch(normalized);
//       if (boardCgpa != null) {
//         return 'CGPA ${boardCgpa.group(2)!.replaceAll(',', '.')}';
//       }
//     }

//     // 2) Marks obtained / max marks style (common across state boards)
//     final pairPercent = _percentageFromObtainedTotal(normalized);
//     if (pairPercent != null) return '${pairPercent.toStringAsFixed(1)}%';

//     // 3) CGPA / GPA patterns
//     final cgpaPatterns = [
//       RegExp(r'cgpa\s*[:\-]?\s*(\d+[\.,]\d{1,2})', caseSensitive: false),
//       RegExp(r'gpa\s*[:\-]?\s*(\d+[\.,]\d{1,2})', caseSensitive: false),
//       RegExp(r'(\d+[\.,]\d{1,2})\s*(?:cgpa|gpa)', caseSensitive: false),
//       RegExp(r'(\d+[\.,]\d{1,2})\s*\/\s*10'),
//     ];

//     for (final pattern in cgpaPatterns) {
//       final match = pattern.firstMatch(text);
//       if (match != null) {
//         return 'CGPA ${match.group(1)!.replaceAll(',', '.')}';
//       }
//     }

//     // 4) Explicit percentage labels
//     final percentPatterns = [
//       RegExp(r'(\d{2,3}[\.,]\d{1,2})\s*%'),
//       RegExp(r'percentage\s*[:\-]?\s*(\d{2,3}[\.,]?\d{0,2})', caseSensitive: false),
//       RegExp(r'\b(\d{2,3})\s*%'),
//     ];

//     for (final pattern in percentPatterns) {
//       final match = pattern.firstMatch(normalized);
//       if (match != null) {
//         return '${match.group(1)!.replaceAll(',', '.')}%';
//       }
//     }

//     // 5) Subject-wise totals fallback
//     final subjectWisePercent = _subjectWiseComputedPercentage(normalized);
//     if (subjectWisePercent != null) {
//       return '${subjectWisePercent.toStringAsFixed(1)}%';
//     }

//     return '';
//   }

//   double? _percentageFromObtainedTotal(String text) {
//     final totalPairs = RegExp(
//       r'(\d{2,4})\s*\/\s*(\d{2,4})',
//       caseSensitive: false,
//     ).allMatches(text);

//     double? best;
//     for (final match in totalPairs) {
//       final obtained = double.tryParse(match.group(1) ?? '');
//       final total = double.tryParse(match.group(2) ?? '');
//       if (obtained == null || total == null || total <= 0) continue;
//       if (obtained > total) continue;
//       if (total < 100 || total > 1200) continue;

//       final pct = (obtained / total) * 100;
//       if (pct < 20 || pct > 100) continue;
//       if (best == null || pct > best) best = pct;
//     }
//     return best;
//   }

//   double? _subjectWiseComputedPercentage(String text) {
//     final lines = text.split('\n');
//     var obtainedSum = 0.0;
//     var totalSum = 0.0;
//     var hits = 0;

//     for (final line in lines) {
//       final match = RegExp(r'(\d{2,3})\s*\/\s*(\d{2,3})').firstMatch(line);
//       if (match == null) continue;

//       final obtained = double.tryParse(match.group(1) ?? '');
//       final total = double.tryParse(match.group(2) ?? '');
//       if (obtained == null || total == null || total <= 0) continue;
//       if (obtained > total) continue;
//       if (total > 200) continue;

//       obtainedSum += obtained;
//       totalSum += total;
//       hits++;
//     }

//     if (hits < 3 || totalSum <= 0) return null;
//     final pct = (obtainedSum / totalSum) * 100;
//     if (pct < 20 || pct > 100) return null;
//     return pct;
//   }

//   // ── Admit Card Extractors (Phase 4) ────────────────────
//   String _extractAdmitCardExamName(String text) {
//     final lower = text.toLowerCase();
//     if (lower.contains('upsc') || lower.contains('civil services')) return 'upsc_cse';
//     if (lower.contains('ssc cgl') || lower.contains('combined graduate level')) return 'ssc_cgl';
//     if (lower.contains('ssc chsl') || lower.contains('higher secondary level')) return 'ssc_chsl';
//     if (lower.contains('ibps po') || lower.contains('probationary officer')) return 'ibps_po';
//     if (lower.contains('sbi po')) return 'sbi_po';
//     if (lower.contains('nda') || lower.contains('national defence academy')) return 'nda';
//     if (lower.contains('cds') || lower.contains('combined defence services')) return 'cds';
//     if (lower.contains('afcat') || lower.contains('air force common admission')) return 'afcat';
//     if (lower.contains('rrb ntpc') || lower.contains('non technical popular')) return 'rrb_ntpc';
//     if (lower.contains('rbi grade b')) return 'rbi_grade_b';
//     return ''; // Unknown exam
//   }

//   String _extractRollNumber(String text) {
//     final rollNoPattern = RegExp(r'(?:roll no|roll number|registration no|reg no)[\s:\-\.]*([A-Z0-9]{5,15})', caseSensitive: false);
//     final match = rollNoPattern.firstMatch(text);
//     return match?.group(1) ?? '';
//   }

//   // ── Stream extract ────────────────────────────────────
//   String _extractStream(String text) {
//     final lower = text.toLowerCase();
//     if (lower.contains('science') &&
//         (lower.contains('physics') ||
//             lower.contains('chemistry') ||
//             lower.contains('mathematics') ||
//             lower.contains('biology'))) {
//       if (lower.contains('mathematics') || lower.contains('maths')) {
//         return 'PCM';
//       }
//       if (lower.contains('biology') || lower.contains('bio')) {
//         return 'PCB';
//       }
//       return 'Science';
//     }
//     if (lower.contains('commerce') ||
//         lower.contains('accountancy') ||
//         lower.contains('economics')) return 'Commerce';
//     if (lower.contains('arts') ||
//         lower.contains('humanities') ||
//         lower.contains('history') ||
//         lower.contains('political')) return 'Arts';
//     return '';
//   }

//   // ── University extract — NAYA ─────────────────────────
//   String _extractUniversity(String text) {
//     final uniKeywords = [
//       'university', 'uni.', 'vishwavidyalaya', 'mahavidyalaya', 'vidyapith',
//       'institute of technology', 'iit', 'nit', 'bits', 'iiit',
//       'engineering college', 'medical college', 'polytechnic',
//       'deemed university', 'central university', 'state university',
//       'institute of management', 'iim', 'academy of higher education',
//       'manipal', 'amity', 'srm', 'vit', 'lpu', 'cu', 'nmims', 'symbiosis'
//     ];

//     final lines = text.split('\n');
//     for (final line in lines) {
//       final trimmed = line.trim().toLowerCase();
//       for (final keyword in uniKeywords) {
//         if (trimmed.contains(keyword) && trimmed.length > 5) {
//           // Line clean karke return karo — max 6 words
//           return line
//               .trim()
//               .replaceAll(RegExp(r'\s+'), ' ')
//               .split(' ')
//               .take(6)
//               .join(' ');
//         }
//       }
//     }
//     return '';
//   }

//   // ── Confidence calculate ──────────────────────────────
//   double _calculateConfidence(
//     String dob,
//     String board,
//     String year,
//     String aggregate,
//     String docType,
//   ) {
//     double score = 0.0;
//     if (docType != 'unknown') score += 0.3;
//     if (board.isNotEmpty) score += 0.2;
//     if (year.isNotEmpty) score += 0.15;
//     if (aggregate.isNotEmpty) score += 0.25;
//     if (dob.isNotEmpty) score += 0.1;
//     return score;
//   }

//   void dispose() {
//     _textRecognizer.close();
//   }
// }


import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class OcrResult {
  final bool success;
  final String rawText;
  final String docType;
  final String board;
  final String year;
  final String aggregate;
  final String stream;
  final String dateOfBirth;
  final String university;
  final String courseName;
  final String graduationStatus;
  final String examName;
  final String rollNumber;
  final String registrationNumber;
  final String candidateName;
  final String fatherName;
  final String motherName;
  final Map<String, String> subjectMarks;
  final double confidence;
  final String? imagePath;
  final String? errorMessage;

  const OcrResult({
    required this.success,
    required this.rawText,
    this.docType = '',
    this.board = '',
    this.year = '',
    this.aggregate = '',
    this.stream = '',
    this.dateOfBirth = '',
    this.university = '',
    this.courseName = '',
    this.graduationStatus = '',
    this.examName = '',
    this.rollNumber = '',
    this.registrationNumber = '',
    this.candidateName = '',
    this.fatherName = '',
    this.motherName = '',
    this.subjectMarks = const {},
    this.confidence = 0.0,
    this.imagePath,
    this.errorMessage,
  });

  const OcrResult.failure(this.errorMessage)
      : success = false,
        rawText = '',
        docType = '',
        board = '',
        year = '',
        aggregate = '',
        stream = '',
        dateOfBirth = '',
        university = '',
        courseName = '',
        graduationStatus = '',
        examName = '',
        rollNumber = '',
        registrationNumber = '',
        candidateName = '',
        fatherName = '',
        motherName = '',
        subjectMarks = const {},
        confidence = 0.0,
        imagePath = null;
}

class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Document', toolbarColor: const Color(0xFF131317), toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: false, hideBottomControls: false,
          activeControlsWidgetColor: const Color(0xFF6C5CE7), dimmedLayerColor: Colors.black.withOpacity(0.8),
        ),
        IOSUiSettings(title: 'Adjust Document', aspectRatioLockEnabled: false, resetAspectRatioEnabled: true),
      ],
    );
    if (croppedFile != null) return File(croppedFile.path);
    return null;
  }

  Future<File?> pickFromCamera() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 100, preferredCameraDevice: CameraDevice.rear);
      if (picked == null) return null;
      return _cropImage(File(picked.path));
    } catch (_) { return null; }
  }

  Future<File?> pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (picked == null) return null;
      return _cropImage(File(picked.path));
    } catch (_) { return null; }
  }

  Future<OcrResult> extractText(File imageFile) async {
    File? processedFile;
    try {
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image != null) {
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.5);
        final processedPath = '${imageFile.path}_processed.jpg';
        processedFile = File(processedPath);
        await processedFile.writeAsBytes(img.encodeJpg(image, quality: 90));
      }
      final inputImage = InputImage.fromFile(processedFile ?? imageFile);
      final recognized = await _textRecognizer.processImage(inputImage);
      final rawText = recognized.blocks.map((b) => b.text).join('\n');
      if (rawText.trim().isEmpty) return const OcrResult.failure('No text found. Please take a clearer photo.');
      return _parseText(rawText, imageFile.path);
    } catch (e) {
      return OcrResult.failure('OCR failed: ${e.toString()}');
    } finally {
      // Note: Hum image file delete nahi kar rahe abhi kyunki 
      // OcrReviewScreen ko ye path display ke liye chahiye.
      // Navigator pop ke baad clean up kiya jata hai in documents_screen.dart logic
      if (processedFile != null && await processedFile.exists()) await processedFile.delete();
    }
  }

  OcrResult _parseText(String text, String? imagePath) {
    final normalizedText = _normalizeHindiDigits(text);
    final docType = _detectDocType(normalizedText);
    final dob = _extractDOB(normalizedText, docType);
    final board = _extractBoard(normalizedText);
    final year = _extractYear(normalizedText);
    final aggregate = _extractAggregate(normalizedText, docType, board);
    final stream = _extractStream(normalizedText);
    final university = _extractUniversity(normalizedText);

    String courseName = ''; String graduationStatus = '';
    if (docType == 'graduation') {
      courseName = _extractCourseName(text);
      graduationStatus = _extractGraduationStatus(normalizedText);
    }

    final candidateName = _extractCandidateName(normalizedText, docType);
    final fatherName = _extractFatherName(normalizedText);
    final motherName = _extractMotherName(normalizedText);
    final registrationNumber = _extractRegistrationNumber(normalizedText);
    final subjectMarks = _extractSubjectMarks(normalizedText);

    String examName = '';
    final rollNumber = _extractRollNumber(normalizedText);
    if (docType == 'admit_card') examName = _extractAdmitCardExamName(normalizedText);

    final confidence = _calculateConfidence(
      dob: dob, board: board, year: year, aggregate: aggregate, docType: docType,
      candidateName: candidateName, rollNumber: rollNumber, registrationNumber: registrationNumber, subjectMarks: subjectMarks,
    );

    return OcrResult(
      success: true,
      rawText: text,
      docType: docType,
      board: board,
      year: year,
      aggregate: aggregate,
      stream: stream,
      dateOfBirth: dob,
      university: university,
      courseName: courseName,
      graduationStatus: graduationStatus,
      examName: examName,
      rollNumber: rollNumber,
      registrationNumber: registrationNumber,
      candidateName: candidateName,
      fatherName: fatherName,
      motherName: motherName,
      subjectMarks: subjectMarks,
      confidence: confidence,
      imagePath: imagePath,
    );
  }

  String _normalizeHindiDigits(String input) {
    const map = {'०':'0','१':'1','२':'2','३':'3','४':'4','५':'5','६':'6','७':'7','८':'8','९':'9'};
    var out = input;
    map.forEach((k, v) => out = out.replaceAll(k, v));
    return out;
  }

  String _detectDocType(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('admit card') || lowerText.contains('hall ticket') || lowerText.contains('e-admit') || lowerText.contains('call letter') || lowerText.contains('प्रवेश पत्र')) return 'admit_card';
    if (lowerText.contains('senior secondary') || lowerText.contains('higher secondary') || lowerText.contains('intermediate') || lowerText.contains('class xii') || lowerText.contains('class 12') || lowerText.contains('12th') || lowerText.contains('hsc') || lowerText.contains('उच्च माध्यमिक') || lowerText.contains('वरिष्ठ माध्यमिक')) return '12th';
    if ((lowerText.contains('secondary') && !lowerText.contains('senior') && !lowerText.contains('higher')) || lowerText.contains('class x') || lowerText.contains('class 10') || lowerText.contains('10th') || lowerText.contains('matric') || lowerText.contains('sslc') || lowerText.contains('माध्यमिक परीक्षा')) return '10th';
    if (lowerText.contains('bachelor') || lowerText.contains('degree') || lowerText.contains('graduation') || lowerText.contains('university') || lowerText.contains('cgpa') || lowerText.contains('स्नातक')) return 'graduation';
    return 'unknown';
  }

  String _extractDOB(String text, String docType) {
    if (docType == '12th' || docType == 'graduation') return '';
    final patterns = [
      RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b'),
      RegExp(r'\b(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})\b'),
      RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(\d{4})\b', caseSensitive: false),
      RegExp(r'\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(\d{1,2})(?:st|nd|rd|th)?\,?\s+(\d{4})\b', caseSensitive: false),
    ];
    final allDates = <String>[];
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) allDates.add(_formatDate(match, pattern.pattern));
    }
    if (allDates.isEmpty) return '';
    String bestDate = allDates.first;
    int minYear = 9999;
    for (final dateStr in allDates) {
      try {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final year = int.parse(parts[2]);
          if (year > 1950 && year < DateTime.now().year && year < minYear) { minYear = year; bestDate = dateStr; }
        }
      } catch (_) {}
    }
    return bestDate;
  }

  String _formatDate(RegExpMatch match, String pattern) {
    if (pattern.contains('january|february')) {
      final months = {'january': '01', 'february': '02', 'march': '03', 'april': '04', 'may': '05', 'june': '06', 'july': '07', 'august': '08', 'september': '09', 'october': '10', 'november': '11', 'december': '12'};
      final month = months[match.group(2)!.toLowerCase()] ?? '00';
      return '${match.group(1)!.padLeft(2, '0')}/$month/${match.group(3)}';
    }
    if (pattern.startsWith(r'\b(\d{4})')) return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
    return '${match.group(1)}/${match.group(2)}/${match.group(3)}';
  }

  String _extractBoard(String text) {
    final lower = text.toLowerCase();
    if ((lower.contains('माध्यमिक शिक्षा बोर्ड') && lower.contains('राजस्थान')) || lower.contains('board of secondary education, rajasthan') || lower.contains('rbse')) return 'RBSE (Rajasthan)';
    if (lower.contains('cbse') || lower.contains('central board of secondary')) return 'CBSE';
    if (lower.contains('icse') || lower.contains('council for the indian')) return 'ICSE';
    if (lower.contains('isc') || lower.contains('indian school certificate')) return 'ISC';
    return '';
  }

  String _extractYear(String text) {
    final matches = RegExp(r'\b(20\d{2})\b').allMatches(text).toList();
    if (matches.isEmpty) return '';
    final examYearMatch = RegExp(r'(?:examination|परीक्षा)\s*[-:]?\s*(20\d{2})', caseSensitive: false).firstMatch(text);
    if (examYearMatch != null) return examYearMatch.group(1)!;
    int maxYear = 0;
    for(var m in matches) {
      final y = int.tryParse(m.group(1)!) ?? 0;
      if (y > maxYear && y <= DateTime.now().year) maxYear = y;
    }
    return maxYear > 0 ? maxYear.toString() : '';
  }

  String _extractAggregate(String text, String docType, String board) {
    if (docType == 'admit_card') return '';
    final normalized = text.toLowerCase().replaceAll('o/', '0/').replaceAll('o ', '0 ').replaceAll(' l ', ' 1 ');
    if (docType == 'graduation') {
      final gradCgpaPatterns = [
        RegExp(r'\bcgpa\b[^\d]{0,12}(\d+(?:[\.,]\d{1,2})?)', caseSensitive: false),
        RegExp(r'\bgpa\b[^\d]{0,12}(\d+(?:[\.,]\d{1,2})?)', caseSensitive: false),
        RegExp(r'(\d+(?:[\.,]\d{1,2})?)\s*(?:cgpa|gpa)\b', caseSensitive: false),
        RegExp(r'\b(\d+(?:[\.,]\d{1,2})?)\s*\/\s*10\b'),
      ];
      for (final p in gradCgpaPatterns) {
        final m = p.firstMatch(normalized);
        if (m != null) {
          final v = m.group(1)!.replaceAll(',', '.');
          final n = double.tryParse(v);
          if (n != null && n >= 0 && n <= 10) return 'CGPA ${n.toStringAsFixed(2)}';
        }
      }
    }
    final pairPercent = _percentageFromObtainedTotal(normalized);
    if (pairPercent != null) return '${pairPercent.toStringAsFixed(1)}%';
    final cgpa = RegExp(r'cgpa\s*[:\-]?\s*(\d+[\.,]\d{1,2})', caseSensitive: false).firstMatch(normalized);
    if (cgpa != null) return 'CGPA ${cgpa.group(1)!.replaceAll(',', '.')}';
    final pct = RegExp(r'(\d{2,3}(?:[\.,]\d{1,2})?)\s*%').firstMatch(normalized);
    if (pct != null) return '${pct.group(1)!.replaceAll(',', '.')}%';
    return '';
  }

  double? _percentageFromObtainedTotal(String text) {
    final totalPairs = RegExp(r'(\d{2,4})\s*\/\s*(\d{2,4})').allMatches(text);
    double? best;
    for (final match in totalPairs) {
      final obtained = double.tryParse(match.group(1) ?? '');
      final total = double.tryParse(match.group(2) ?? '');
      if (obtained == null || total == null || total <= 0 || obtained > total) continue;
      final pct = (obtained / total) * 100;
      if (pct >= 20 && pct <= 100 && (best == null || pct > best)) best = pct;
    }
    return best;
  }

  String _extractCandidateName(String text, String docType) {
    if (docType == '12th' || docType == 'graduation') return '';
    final cleanText = text.replaceAll(RegExp(r'\n+'), ' ');
    final subjectBlacklist = RegExp(r'\b(HINDI|ENGLISH|SANSKRIT|MATHEMATICS|SCIENCE|SOCIAL|HISTORY|GEOGRAPHY|PHYSICS|CHEMISTRY|BIOLOGY|ECONOMICS|ACCOUNTANCY|BUSINESS)\b', caseSensitive: false);
    
    final certRegex = RegExp(r'(?:certify that|किया जाता है कि)\s+([A-Z\s]{4,40})', caseSensitive: false);
    final match = certRegex.firstMatch(cleanText);
    if (match != null) {
      final possibleName = match.group(1)!.trim();
      if (!possibleName.toLowerCase().contains('mother') && !possibleName.toLowerCase().contains('father') && !subjectBlacklist.hasMatch(possibleName)) {
        return possibleName.split(RegExp(r'माता|पिता|mother|father|date|birth', caseSensitive: false)).first.trim();
      }
    }
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if ((line.contains('name:') || line.contains('candidate name:')) && !subjectBlacklist.hasMatch(lines[i])) {
        final val = lines[i].split(':').last.trim();
        if (val.length > 3 && !subjectBlacklist.hasMatch(val)) return val;
      }
    }
    return '';
  }

  String _extractCourseName(String text) {
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.toUpperCase().contains(RegExp(r'(BACHELOR|MASTER|B\.TECH|M\.TECH|B\.SC|M\.SC|B\.A|M\.A|DEGREE IN)'))) {
        if (line.length > 5 && line.length < 80) return line.trim();
      }
    }
    return '';
  }

  String _extractGraduationStatus(String text) {
    if (text.contains('semester examination') || text.contains('statement of marks')) {
      if (text.contains('final year') || text.contains('convocation') || text.contains('degree certificate')) return 'Completed';
      return 'Pursuing';
    }
    return '';
  }

  String _extractUniversity(String text) {
    final uniKeywords = ['university', 'vishwavidyalaya', 'institute of technology', 'college'];
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim().toLowerCase();
      for (final keyword in uniKeywords) {
        if (trimmed.contains(keyword) && trimmed.length > 5 && trimmed.length < 60) return line.trim();
      }
    }
    return '';
  }

  String _extractAdmitCardExamName(String text) => ''; String _extractRollNumber(String text) => ''; String _extractRegistrationNumber(String text) => ''; String _extractStream(String text) => ''; String _extractFatherName(String text) => ''; String _extractMotherName(String text) => ''; Map<String, String> _extractSubjectMarks(String text) => {};

  double _calculateConfidence({required String dob, required String board, required String year, required String aggregate, required String docType, required String candidateName, required String rollNumber, required String registrationNumber, required Map<String, String> subjectMarks}) {
    double score = 0.0;
    if (docType != 'unknown') score += 0.20; if (board.isNotEmpty) score += 0.15; if (year.isNotEmpty) score += 0.10; if (aggregate.isNotEmpty) score += 0.18; if (dob.isNotEmpty) score += 0.08; if (candidateName.isNotEmpty) score += 0.10; if (rollNumber.isNotEmpty) score += 0.07; if (registrationNumber.isNotEmpty) score += 0.05; if (subjectMarks.isNotEmpty) score += 0.07;
    return score.clamp(0.0, 1.0);
  }
  void dispose() => _textRecognizer.close();
}