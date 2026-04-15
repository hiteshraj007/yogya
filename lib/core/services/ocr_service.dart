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

// ── Extracted data structure ───────────────────────────────
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
  final String examName;
  final String rollNumber;
  final String registrationNumber;

  final String candidateName;
  final String fatherName;
  final String motherName;
  final Map<String, String> subjectMarks;

  final double confidence;
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
    this.examName = '',
    this.rollNumber = '',
    this.registrationNumber = '',
    this.candidateName = '',
    this.fatherName = '',
    this.motherName = '',
    this.subjectMarks = const {},
    this.confidence = 0.0,
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
        examName = '',
        rollNumber = '',
        registrationNumber = '',
        candidateName = '',
        fatherName = '',
        motherName = '',
        subjectMarks = const {},
        confidence = 0.0;
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
          toolbarTitle: 'Adjust Document',
          toolbarColor: const Color(0xFF131317),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
          activeControlsWidgetColor: const Color(0xFF6C5CE7),
          dimmedLayerColor: Colors.black.withOpacity(0.8),
        ),
        IOSUiSettings(
          title: 'Adjust Document',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );
    if (croppedFile != null) return File(croppedFile.path);
    return null;
  }

  Future<File?> pickFromCamera() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return null;
      return _cropImage(File(picked.path));
    } catch (_) {
      return null;
    }
  }

  Future<File?> pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null) return null;
      return _cropImage(File(picked.path));
    } catch (_) {
      return null;
    }
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

      if (rawText.trim().isEmpty) {
        return const OcrResult.failure('No text found. Please take a clearer photo.');
      }

      return _parseText(rawText);
    } catch (e) {
      return OcrResult.failure('OCR failed: ${e.toString()}');
    } finally {
      if (processedFile != null && await processedFile.exists()) {
        await processedFile.delete();
      }
    }
  }

  OcrResult _parseText(String text) {
    final normalizedText = _normalizeHindiDigits(text);

    final docType = _detectDocType(normalizedText);
    final dob = _extractDOB(normalizedText);
    final board = _extractBoard(normalizedText);
    final year = _extractYear(normalizedText);

    final aggregate = _extractAggregate(normalizedText, docType, board);
    final stream = _extractStream(normalizedText);
    final university = _extractUniversity(normalizedText);

    final candidateName = _extractCandidateName(normalizedText);
    final fatherName = _extractFatherName(normalizedText);
    final motherName = _extractMotherName(normalizedText);
    final registrationNumber = _extractRegistrationNumber(normalizedText);
    final subjectMarks = _extractSubjectMarks(normalizedText);

    String examName = '';
    String rollNumber = _extractRollNumber(normalizedText);
    if (docType == 'admit_card') {
      examName = _extractAdmitCardExamName(normalizedText);
    }

    final confidence = _calculateConfidence(
      dob: dob,
      board: board,
      year: year,
      aggregate: aggregate,
      docType: docType,
      candidateName: candidateName,
      rollNumber: rollNumber,
      registrationNumber: registrationNumber,
      subjectMarks: subjectMarks,
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
      examName: examName,
      rollNumber: rollNumber,
      registrationNumber: registrationNumber,
      candidateName: candidateName,
      fatherName: fatherName,
      motherName: motherName,
      subjectMarks: subjectMarks,
      confidence: confidence,
    );
  }

  String _normalizeHindiDigits(String input) {
    const map = {
      '०': '0',
      '१': '1',
      '२': '2',
      '३': '3',
      '४': '4',
      '५': '5',
      '६': '6',
      '७': '7',
      '८': '8',
      '९': '9',
    };
    var out = input;
    map.forEach((k, v) => out = out.replaceAll(k, v));
    return out;
  }

  String _detectDocType(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('admit card') ||
        lowerText.contains('hall ticket') ||
        lowerText.contains('e-admit') ||
        lowerText.contains('call letter') ||
        lowerText.contains('प्रवेश पत्र')) {
      return 'admit_card';
    }

    if (lowerText.contains('senior secondary') ||
        lowerText.contains('higher secondary') ||
        lowerText.contains('intermediate') ||
        lowerText.contains('class xii') ||
        lowerText.contains('class 12') ||
        lowerText.contains('12th') ||
        lowerText.contains('hsc') ||
        lowerText.contains('उच्च माध्यमिक') ||
        lowerText.contains('वरिष्ठ माध्यमिक')) {
      return '12th';
    }

    if (lowerText.contains('secondary') ||
        lowerText.contains('class x') ||
        lowerText.contains('class 10') ||
        lowerText.contains('10th') ||
        lowerText.contains('matric') ||
        lowerText.contains('sslc') ||
        lowerText.contains('माध्यमिक परीक्षा')) {
      return '10th';
    }

    if (lowerText.contains('bachelor') ||
        lowerText.contains('degree') ||
        lowerText.contains('graduation') ||
        lowerText.contains('university') ||
        lowerText.contains('cgpa') ||
        lowerText.contains('स्नातक')) {
      return 'graduation';
    }

    return 'unknown';
  }

  // ── DOB extraction (FIXED GLOBAL) ──────────────────────
  String _extractDOB(String text) {
    final normalized = _normalizeHindiDigits(text);
    final lower = normalized.toLowerCase();

    final dobLabels = [
      'date of birth',
      'dob',
      'd.o.b',
      'birth date',
      'जन्म तिथि',
      'जन्मतिथि',
      'जन्म दिनांक',
    ];

    final dmy = RegExp(r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})\b');
    final ymd = RegExp(r'\b(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})\b');

    // 1) Label-based extraction first
    for (final label in dobLabels) {
      final idx = lower.indexOf(label);
      if (idx == -1) continue;

      final start = idx;
      final end = (idx + 140).clamp(0, normalized.length);
      final window = normalized.substring(start, end);

      final m1 = dmy.firstMatch(window);
      if (m1 != null) {
        final dd = int.tryParse(m1.group(1) ?? '') ?? 0;
        final mm = int.tryParse(m1.group(2) ?? '') ?? 0;
        final yyyy = int.tryParse(m1.group(3) ?? '') ?? 0;
        if (_isValidDob(dd, mm, yyyy)) {
          return '${dd.toString().padLeft(2, '0')}/${mm.toString().padLeft(2, '0')}/$yyyy';
        }
      }

      final m2 = ymd.firstMatch(window);
      if (m2 != null) {
        final yyyy = int.tryParse(m2.group(1) ?? '') ?? 0;
        final mm = int.tryParse(m2.group(2) ?? '') ?? 0;
        final dd = int.tryParse(m2.group(3) ?? '') ?? 0;
        if (_isValidDob(dd, mm, yyyy)) {
          return '${dd.toString().padLeft(2, '0')}/${mm.toString().padLeft(2, '0')}/$yyyy';
        }
      }
    }

    // 2) fallback: plausible oldest DOB
    DateTime? best;
    for (final m in dmy.allMatches(normalized)) {
      final dd = int.tryParse(m.group(1) ?? '') ?? 0;
      final mm = int.tryParse(m.group(2) ?? '') ?? 0;
      final yyyy = int.tryParse(m.group(3) ?? '') ?? 0;
      if (!_isValidDob(dd, mm, yyyy)) continue;

      final dt = DateTime(yyyy, mm, dd);
      if (!_isPlausibleAge(dt)) continue;
      if (best == null || dt.isBefore(best)) best = dt;
    }

    for (final m in ymd.allMatches(normalized)) {
      final yyyy = int.tryParse(m.group(1) ?? '') ?? 0;
      final mm = int.tryParse(m.group(2) ?? '') ?? 0;
      final dd = int.tryParse(m.group(3) ?? '') ?? 0;
      if (!_isValidDob(dd, mm, yyyy)) continue;

      final dt = DateTime(yyyy, mm, dd);
      if (!_isPlausibleAge(dt)) continue;
      if (best == null || dt.isBefore(best)) best = dt;
    }

    if (best != null) {
      return '${best.day.toString().padLeft(2, '0')}/${best.month.toString().padLeft(2, '0')}/${best.year}';
    }

    return '';
  }

  bool _isValidDob(int dd, int mm, int yyyy) {
    if (dd < 1 || dd > 31) return false;
    if (mm < 1 || mm > 12) return false;
    final nowYear = DateTime.now().year;
    if (yyyy < 1950 || yyyy > nowYear) return false;

    final dt = DateTime(yyyy, mm, dd);
    return dt.year == yyyy && dt.month == mm && dt.day == dd;
  }

  bool _isPlausibleAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age >= 10 && age <= 80;
  }

  String _extractBoard(String text) {
    final lower = text.toLowerCase();

    if ((lower.contains('माध्यमिक शिक्षा बोर्ड') && lower.contains('राजस्थान')) ||
        lower.contains('board of secondary education, rajasthan') ||
        lower.contains('rbse')) {
      return 'RBSE (Rajasthan)';
    }

    if (lower.contains('cbse') || lower.contains('central board of secondary')) return 'CBSE';
    if (lower.contains('icse') || lower.contains('council for the indian')) return 'ICSE';
    if (lower.contains('isc') || lower.contains('indian school certificate')) return 'ISC';
    if (lower.contains('up board') || lower.contains('uttar pradesh madhyamik')) return 'UP Board';
    if (lower.contains('bihar') || lower.contains('bseb')) return 'Bihar Board';
    if (lower.contains('maharashtra') || lower.contains('msbshse')) return 'Maharashtra State Board';
    if (lower.contains('karnataka') || lower.contains('kseeb')) return 'Karnataka Board';
    if (lower.contains('gujarat') || lower.contains('gseb')) return 'Gujarat Board';

    return '';
  }

  String _extractYear(String text) {
    final lowerText = text.toLowerCase();
    final yearKeywords = ['session', 'year of passing', 'exam year', 'passing year', 'परीक्षा', 'वर्ष'];

    String searchArea = text;
    for (final kw in yearKeywords) {
      final idx = lowerText.indexOf(kw);
      if (idx != -1) {
        searchArea = text.substring(idx, (idx + 80).clamp(0, text.length));
        break;
      }
    }

    final yearPattern = RegExp(r'\b(20\d{2})\b');
    final areaMatches = yearPattern.allMatches(searchArea).toList();
    if (areaMatches.isNotEmpty) return areaMatches.last.group(1)!;

    final matches = yearPattern.allMatches(text).toList();
    if (matches.isEmpty) return '';

    final years = matches
        .map((m) => int.tryParse(m.group(1) ?? '') ?? 0)
        .where((y) => y >= 2000 && y <= DateTime.now().year + 1)
        .toList()
      ..sort();

    return years.isNotEmpty ? years.last.toString() : '';
  }

  String _extractAggregate(String text, String docType, String board) {
    if (docType == 'admit_card') return '';

    final normalized = text
        .toLowerCase()
        .replaceAll('o/', '0/')
        .replaceAll('o ', '0 ')
        .replaceAll(' l ', ' 1 ');

    final hindiTotalPercent = RegExp(
      r'(?:कुल\s*प्राप्तांक|total\s*marks\s*obtained)\s*[:\-]?\s*(\d{2,4})\s+(\d{2,3}(?:\.\d{1,2})?)\s*%',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (hindiTotalPercent != null) return '${hindiTotalPercent.group(2)}%';

    final pairPercent = _percentageFromObtainedTotal(normalized);
    if (pairPercent != null) return '${pairPercent.toStringAsFixed(1)}%';

    final cgpaPatterns = [
      RegExp(r'cgpa\s*[:\-]?\s*(\d+[\.,]\d{1,2})', caseSensitive: false),
      RegExp(r'gpa\s*[:\-]?\s*(\d+[\.,]\d{1,2})', caseSensitive: false),
      RegExp(r'(\d+[\.,]\d{1,2})\s*(?:cgpa|gpa)', caseSensitive: false),
      RegExp(r'(\d+[\.,]\d{1,2})\s*\/\s*10'),
    ];

    for (final pattern in cgpaPatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) return 'CGPA ${match.group(1)!.replaceAll(',', '.')}';
    }

    final percentPatterns = [
      RegExp(r'(\d{2,3}[\.,]\d{1,2})\s*%'),
      RegExp(r'percentage\s*[:\-]?\s*(\d{2,3}[\.,]?\d{0,2})', caseSensitive: false),
      RegExp(r'\b(\d{2,3})\s*%'),
    ];

    for (final pattern in percentPatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) return '${match.group(1)!.replaceAll(',', '.')}%';
    }

    final subjectWisePercent = _subjectWiseComputedPercentage(normalized);
    if (subjectWisePercent != null) return '${subjectWisePercent.toStringAsFixed(1)}%';

    return '';
  }

  double? _percentageFromObtainedTotal(String text) {
    final totalPairs = RegExp(r'(\d{2,4})\s*\/\s*(\d{2,4})').allMatches(text);

    double? best;
    for (final match in totalPairs) {
      final obtained = double.tryParse(match.group(1) ?? '');
      final total = double.tryParse(match.group(2) ?? '');
      if (obtained == null || total == null || total <= 0) continue;
      if (obtained > total) continue;
      if (total < 100 || total > 1200) continue;

      final pct = (obtained / total) * 100;
      if (pct < 20 || pct > 100) continue;
      if (best == null || pct > best) best = pct;
    }
    return best;
  }

  double? _subjectWiseComputedPercentage(String text) {
    final lines = text.split('\n');
    var obtainedSum = 0.0;
    var totalSum = 0.0;
    var hits = 0;

    for (final line in lines) {
      final match = RegExp(r'(\d{2,3})\s*\/\s*(\d{2,3})').firstMatch(line);
      if (match == null) continue;

      final obtained = double.tryParse(match.group(1) ?? '');
      final total = double.tryParse(match.group(2) ?? '');
      if (obtained == null || total == null || total <= 0) continue;
      if (obtained > total) continue;
      if (total > 200) continue;

      obtainedSum += obtained;
      totalSum += total;
      hits++;
    }

    if (hits < 3 || totalSum <= 0) return null;
    final pct = (obtainedSum / totalSum) * 100;
    if (pct < 20 || pct > 100) return null;
    return pct;
  }

  String _extractAdmitCardExamName(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('upsc') || lower.contains('civil services')) return 'upsc_cse';
    if (lower.contains('ssc cgl') || lower.contains('combined graduate level')) return 'ssc_cgl';
    if (lower.contains('ssc chsl') || lower.contains('higher secondary level')) return 'ssc_chsl';
    if (lower.contains('ibps po') || lower.contains('probationary officer')) return 'ibps_po';
    if (lower.contains('sbi po')) return 'sbi_po';
    if (lower.contains('nda') || lower.contains('national defence academy')) return 'nda';
    if (lower.contains('cds') || lower.contains('combined defence services')) return 'cds';
    if (lower.contains('afcat') || lower.contains('air force common admission')) return 'afcat';
    if (lower.contains('rrb ntpc') || lower.contains('non technical popular')) return 'rrb_ntpc';
    if (lower.contains('rbi grade b')) return 'rbi_grade_b';
    return '';
  }

  String _extractRollNumber(String text) {
    final patterns = [
      RegExp(
        r'(?:roll no|roll number|नामांक|अनुक्रमांक)[\s:\-\.]*([A-Z0-9\-\/]{5,20})',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1) ?? '';
    }
    return '';
  }

  String _extractRegistrationNumber(String text) {
    final p = RegExp(
      r'(?:registration no|reg no|enrollment no|enrolment no|संदर्भ संख्या|पंजीकरण संख्या)[\s:\-\.]*([A-Z0-9\-\/]{4,20})',
      caseSensitive: false,
    );
    final m = p.firstMatch(text);
    return m?.group(1) ?? '';
  }

  String _extractStream(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('science') || lower.contains('विज्ञान')) {
      if (lower.contains('mathematics') || lower.contains('maths') || lower.contains('गणित')) {
        return 'PCM';
      }
      if (lower.contains('biology') || lower.contains('bio') || lower.contains('जीवविज्ञान')) {
        return 'PCB';
      }
      return 'Science';
    }

    if (lower.contains('commerce') || lower.contains('वाणिज्य')) return 'Commerce';
    if (lower.contains('arts') || lower.contains('humanities') || lower.contains('कला')) return 'Arts';

    return '';
  }

  String _extractUniversity(String text) {
    final keywords = [
      'university',
      'board',
      'माध्यमिक शिक्षा बोर्ड',
      'विभाग',
      'परिषद',
      'विद्यालय',
      'vishwavidyalaya',
      'mahavidyalaya',
    ];

    final lines = text.split('\n');
    for (final line in lines) {
      final l = line.trim().toLowerCase();
      for (final k in keywords) {
        if (l.contains(k) && l.length > 5) {
          return line.trim().replaceAll(RegExp(r'\s+'), ' ');
        }
      }
    }
    return '';
  }

  String _extractCandidateName(String text) {
    final patterns = [
      RegExp(
        r'(?:name of candidate|candidate name|student name|name|प्रमाणित किया जाता है कि)\s*[:\-]?\s*([A-Z\u0900-\u097F ]{3,60})',
        caseSensitive: false,
      ),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final val = m.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (val.length >= 3) return val;
      }
    }
    return '';
  }

  String _extractFatherName(String text) {
    final patterns = [
      RegExp(
        r"(?:father[\' ]?s name|father name|पिता का नाम)\s*[:\-]?\s*([A-Z\u0900-\u097F ]{2,50})",
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
    }
    return '';
  }

  String _extractMotherName(String text) {
    final patterns = [
      RegExp(
        r"(?:mother[\' ]?s name|mother name|माता का नाम)\s*[:\-]?\s*([A-Z\u0900-\u097F ]{2,50})",
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
    }
    return '';
  }

  Map<String, String> _extractSubjectMarks(String text) {
    final aliases = <String, List<String>>{
      'HINDI': ['hindi', 'हिन्दी', 'हिंदी'],
      'ENGLISH': ['english', 'अंग्रेजी'],
      'MATHEMATICS': ['mathematics', 'maths', 'गणित'],
      'SCIENCE': ['science', 'विज्ञान'],
      'SOCIAL SCIENCE': ['social science', 'समाजिक विज्ञान', 'सामाजिक विज्ञान'],
      'PHYSICS': ['physics', 'भौतिकी'],
      'CHEMISTRY': ['chemistry', 'रसायन'],
      'BIOLOGY': ['biology', 'जीवविज्ञान'],
      'SANSKRIT': ['sanskrit', 'संस्कृत'],
    };

    final result = <String, String>{};
    final lines = text.split('\n');

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      for (final entry in aliases.entries) {
        final canonical = entry.key;
        final keys = entry.value;
        final matched = keys.any((k) => lowerLine.contains(k));
        if (!matched) continue;

        final m = RegExp(r'(\d{1,3})\s*(?:\/\s*(\d{1,3}))?').firstMatch(line);
        if (m != null) {
          final value = m.group(2) != null ? '${m.group(1)}/${m.group(2)}' : m.group(1)!;
          result[canonical] = value;
        }
      }
    }

    return result;
  }

  double _calculateConfidence({
    required String dob,
    required String board,
    required String year,
    required String aggregate,
    required String docType,
    required String candidateName,
    required String rollNumber,
    required String registrationNumber,
    required Map<String, String> subjectMarks,
  }) {
    double score = 0.0;
    if (docType != 'unknown') score += 0.20;
    if (board.isNotEmpty) score += 0.15;
    if (year.isNotEmpty) score += 0.10;
    if (aggregate.isNotEmpty) score += 0.18;
    if (dob.isNotEmpty) score += 0.08;
    if (candidateName.isNotEmpty) score += 0.10;
    if (rollNumber.isNotEmpty) score += 0.07;
    if (registrationNumber.isNotEmpty) score += 0.05;
    if (subjectMarks.isNotEmpty) score += 0.07;
    return score.clamp(0.0, 1.0);
  }

  void dispose() {
    _textRecognizer.close();
  }
}