// import '../../../core/theme/theme_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import '../../../core/constants/colors.dart';
// import '../../../core/constants/strings.dart';
// import '../../../core/constants/app_animations.dart';
// import '../../../core/constants/exam_data.dart';
// import '../../../data/providers/ocr_provider.dart';
// import '../../../data/providers/auth_provider.dart';
// import '../../../data/local/hive_service.dart';
// import '../../providers/profile_provider.dart';
// import '../../widgets/common/empty_state_widget.dart';
// import 'widgets/scanned_doc_card.dart';
// import 'widgets/ocr_progress_card.dart';
// import '../../../core/services/ocr_service.dart';

// // â”€â”€ Change 1: ConsumerStatefulWidget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// class DocumentsScreen extends ConsumerStatefulWidget {
//   DocumentsScreen({super.key});

//   @override
//   ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
// }

// // â”€â”€ Change 2: ConsumerState â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
//     with SingleTickerProviderStateMixin {
//   int _currentTab = 0;
//   late AnimationController _ctrl;
//   late Animation<double> _fadeAnim;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync:    this,
//       duration: Duration(milliseconds: 600),
//     );
//     _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
//     _ctrl.forward();
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   // â”€â”€ Change 3: Mock docs hata ke real Hive docs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   List<Map<String, dynamic>> get _allDocs {
//     final hiveDocs = HiveService.getAllDocs();
//     return hiveDocs.map((doc) {
//       IconData icon;
//       switch (doc.docType) {
//         case '10th':
//           icon = Icons.description_rounded;
//           break;
//         case '12th':
//           icon = Icons.description_rounded;
//           break;
//         case 'graduation':
//           icon = Icons.school_rounded;
//           break;
//         default:
//           icon = Icons.insert_drive_file_rounded;
//       }

//       return {
//         'name':   doc.docType == '10th'
//             ? '10th Marksheet'
//             : doc.docType == '12th'
//                 ? '12th Marksheet'
//                 : doc.docType == 'graduation'
//                     ? 'Graduation Certificate'
//                     : 'Document',
//         'type':   'Marksheet',
//         'date':   '${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}',
//         'status': doc.isVerified ? 'Verified' : 'Processing',
//         'icon':   icon,
//         'id':     doc.id,
//       };
//     }).toList();
//   }

//   List<Map<String, dynamic>> get _filteredDocs {
//     final all = _allDocs;
//     if (_currentTab == 0) return all;
//     if (_currentTab == 1) {
//       return all
//           .where((d) =>
//               d['type'] == 'Marksheet' || d['type'] == 'Certificate')
//           .toList();
//     }
//     return all.where((d) => d['type'] == 'ID Proof').toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // â”€â”€ Change 4: OCR state watch karo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//     final ocrState = ref.watch(ocrProvider);

//     // OCR processing chal raha hai to progress card dikhao
//     if (ocrState.status == OcrStatus.processing ||
//         ocrState.status == OcrStatus.picking) {
//       return Scaffold(
//         backgroundColor: context.colors.bgDark,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           title: Text(
//             'Scanning Document',
//             style: TextStyle(
//               color:      context.colors.textPrimary,
//               fontSize:   20,
//               fontWeight: FontWeight.w600,
//               fontFamily: 'Poppins',
//             ),
//           ),
//         ),
//         body: SafeArea(
//           child: Center(
//             child: Padding(
//               padding: EdgeInsets.all(20),
//               child: OcrProgressCard(ocrState: ocrState),
//             ),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: context.colors.bgDark,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text(
//           'My Documents',
//           style: TextStyle(
//             color:      context.colors.textPrimary,
//             fontSize:   20,
//             fontWeight: FontWeight.w600,
//             fontFamily: 'Poppins',
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Container(
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color:        context.colors.glassWhite,
//                 borderRadius: BorderRadius.circular(10),
//                 border:       Border.all(color: context.colors.glassBorder),
//               ),
//               child: Icon(Icons.search_rounded,
//                   color: context.colors.textPrimary, size: 20),
//             ),
//             onPressed: () {},
//           ),
//           SizedBox(width: 8),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             SizedBox(height: 8),

//             // Tabs
//             FadeTransition(
//               opacity: _fadeAnim,
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20),
//                 child: Container(
//                   padding: EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color:        context.colors.bgCard,
//                     borderRadius: BorderRadius.circular(14),
//                     border:       Border.all(color: context.colors.glassBorder),
//                   ),
//                   child: Row(
//                     children: [
//                       _buildTab('All', 0),
//                       _buildTab('Scanned', 1),
//                       _buildTab('Uploaded', 2),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             SizedBox(height: 20),

//             // Documents list
//             Expanded(
//               child: _filteredDocs.isEmpty
//                   ? EmptyStateWidget(
//                       icon:        Icons.document_scanner_rounded,
//                       title:       AppStrings.noDocumentsTitle,
//                       subtitle:    AppStrings.noDocumentsSubtitle,
//                       actionLabel: 'Scan Document',
//                       onAction:    _showScanSheet,
//                     )
//                   : ListView.builder(
//                       physics: BouncingScrollPhysics(),
//                       padding: EdgeInsets.symmetric(horizontal: 20),
//                       itemCount: _filteredDocs.length,
//                       itemBuilder: (context, index) {
//                         final doc = _filteredDocs[index];
//                         return TweenAnimationBuilder<double>(
//                           tween:    Tween(begin: 0.0, end: 1.0),
//                           duration: Duration(
//                               milliseconds: 400 + (index * 100)),
//                           curve: Curves.easeOutCubic,
//                           builder: (context, value, child) {
//                             return Opacity(
//                               opacity: value,
//                               child: Transform.translate(
//                                 offset: Offset(0, 20 * (1 - value)),
//                                 child: child,
//                               ),
//                             );
//                           },
//                           child: ScannedDocCard(
//                             name:     doc['name'],
//                             type:     doc['type'],
//                             date:     doc['date'],
//                             status:   doc['status'],
//                             icon:     doc['icon'],
//                             onTap:    () {},
//                             onDelete: () async {
//                               await HiveService.deleteDoc(doc['id']);
//                               setState(() {});
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed:       _showScanSheet,
//         backgroundColor: context.colors.primary,
//         elevation:       8,
//         child: Icon(Icons.camera_alt_rounded, color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildTab(String label, int index) {
//     final isSelected = _currentTab == index;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _currentTab = index),
//         child: AnimatedContainer(
//           duration: AppAnimations.fast,
//           padding: EdgeInsets.symmetric(vertical: 10),
//           decoration: BoxDecoration(
//             color:        isSelected ? context.colors.primary : Colors.transparent,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               color:      isSelected ? Colors.white : context.colors.textHint,
//               fontSize:   13,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//               fontFamily: 'Poppins',
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       ),
//     );
//   }

//   // â”€â”€ Change 5: Real scan sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   void _showScanSheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: context.colors.bgCard,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (ctx) {
//         return Padding(
//           padding: EdgeInsets.all(28),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width:  40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color:        context.colors.glassBorder,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               SizedBox(height: 24),
//               Text(
//                 'Scan Document',
//                 style: TextStyle(
//                   color:      context.colors.textPrimary,
//                   fontSize:   20,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Poppins',
//                 ),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 'Choose how to add your document',
//                 style: TextStyle(
//                   color:      context.colors.textHint,
//                   fontSize:   13,
//                   fontFamily: 'Poppins',
//                 ),
//               ),
//               SizedBox(height: 28),
//               Row(
//                 children: [
//                   // â”€â”€ Camera â€” REAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//                   _buildScanOption(
//                     Icons.camera_alt_rounded,
//                     'Camera',
//                     'Take a photo',
//                     Color(0xFF6C5CE7),
//                     () async {
//                       Navigator.pop(ctx);
//                       await _scanDocument(fromCamera: true);
//                     },
//                   ),
//                   SizedBox(width: 16),
//                   // â”€â”€ Gallery â€” REAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//                   _buildScanOption(
//                     Icons.photo_library_rounded,
//                     'Gallery',
//                     'Pick from gallery',
//                     Color(0xFF00B894),
//                     () async {
//                       Navigator.pop(ctx);
//                       await _scanDocument(fromCamera: false);
//                     },
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // â”€â”€ Change 6: Real OCR scan function â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   Future<void> _scanDocument({required bool fromCamera}) async {
//     final ocrNotifier = ref.read(ocrProvider.notifier);

//     final result = fromCamera
//         ? await ocrNotifier.scanFromCamera()
//         : await ocrNotifier.scanFromGallery();

//     if (result == null) return;

//     final attemptLogged = await _autoLogAttemptFromAdmitCard(result);

//     // OCR result -> Profile auto-fill
//     if (result.dateOfBirth.isNotEmpty || result.aggregate.isNotEmpty) {
//       final user = ref.read(currentUserProvider);
//       if (user != null) {
//         String qual = '';
//         if (result.docType == 'graduation') qual = 'Graduation';
//         if (result.docType == '12th') qual = '12th Pass';
//         if (result.docType == '10th') qual = '10th Pass';

//         await ref.read(profileNotifierProvider.notifier).updateFromOcr(
//               uid: user.uid,
//               docType: qual,
//               dateOfBirth: result.dateOfBirth,
//               university: result.university,
//               percentage: result.aggregate,
//               passingYear: result.year,
//               primaryExamGoal: result.examName,
//             );
//       }
//     }

//     if (mounted) {
//       setState(() {});

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               const Icon(Icons.check_circle_rounded,
//                   color: Colors.white, size: 18),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   result.docType.isNotEmpty
//                       ? '${result.docType.toUpperCase()} document scanned! '
//                           'Confidence: ${(result.confidence * 100).toInt()}%'
//                           '${attemptLogged ? ' | Attempt auto-logged' : ''}'
//                       : 'Document scanned successfully!',
//                   style: const TextStyle(
//                     fontFamily: 'Poppins',
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           backgroundColor: context.colors.eligible,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     }

//     ref.read(ocrProvider.notifier).reset();
//   }

//   Future<bool> _autoLogAttemptFromAdmitCard(OcrResult result) async {
//     if (result.docType != 'admit_card') return false;
//     if (result.examName.trim().isEmpty) return false;

//     final examId = result.examName.trim();
//     final matchedExams =
//         ExamData.allExams.where((exam) => exam.id == examId).toList();
//     if (matchedExams.isEmpty) return false;
//     final exam = matchedExams.first;

//     final box = Hive.isBoxOpen('attemptHistory')
//         ? Hive.box('attemptHistory')
//         : await Hive.openBox('attemptHistory');

//     final roll = result.rollNumber.trim();
//     final year = result.year.trim().isEmpty
//         ? DateTime.now().year.toString()
//         : result.year.trim();

//     if (roll.isNotEmpty) {
//       final duplicate = box.values.any((raw) {
//         if (raw is! Map) return false;
//         final entry = Map<String, dynamic>.from(raw);
//         return entry['examId'] == examId &&
//             (entry['year']?.toString() ?? '') == year &&
//             (entry['rollNumber']?.toString() ?? '') == roll;
//       });
//       if (duplicate) return false;
//     }

//     var attemptCount = 0;
//     for (final raw in box.values) {
//       if (raw is! Map) continue;
//       final entry = Map<String, dynamic>.from(raw);
//       if ((entry['examId'] ?? '').toString() == examId) {
//         attemptCount++;
//       }
//     }

//     await box.add({
//       'exam': exam.code,
//       'examId': exam.id,
//       'year': year,
//       'result': 'Pending',
//       'stage': _extractAttemptStage(result.rawText),
//       'score': 'N/A',
//       'attemptNumber': attemptCount + 1,
//       'icon': _iconForExam(exam),
//       'rollNumber': roll,
//       'source': 'ocr_admit_card',
//       'createdAt': DateTime.now().toIso8601String(),
//     });

//     return true;
//   }

//   String _extractAttemptStage(String rawText) {
//     final text = rawText.toLowerCase();
//     if (text.contains('interview')) return 'Interview';
//     if (text.contains('mains')) return 'Mains';
//     if (text.contains('tier ii') || text.contains('tier 2')) return 'Tier II';
//     if (text.contains('tier i') || text.contains('tier 1')) return 'Tier I';
//     if (text.contains('prelims') || text.contains('preliminary')) {
//       return 'Prelims';
//     }
//     return 'Prelims';
//   }

//   String _iconForExam(ExamInfo exam) {
//     switch (exam.category.toLowerCase()) {
//       case 'upsc':
//         return '🏛️';
//       case 'ssc':
//         return '📋';
//       case 'banking':
//         return '🏦';
//       case 'defence':
//         return '⚔️';
//       case 'railways':
//         return '🚆';
//       default:
//         return '📝';
//     }
//   }

//   Widget _buildScanOption(
//     IconData icon,
//     String   label,
//     String   subtitle,
//     Color    color,
//     VoidCallback onTap,
//   ) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 20),
//           decoration: BoxDecoration(
//             color:        context.colors.bgCardLight,
//             borderRadius: BorderRadius.circular(16),
//             border:       Border.all(color: context.colors.glassBorder),
//           ),
//           child: Column(
//             children: [
//               Container(
//                 width:  48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color:        color.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: Icon(icon, color: color, size: 24),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color:      context.colors.textPrimary,
//                   fontSize:   12,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Poppins',
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/exam_data.dart';
import '../../../data/providers/ocr_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/local/hive_service.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'widgets/scanned_doc_card.dart';
import 'widgets/ocr_progress_card.dart';
import '../../../core/services/ocr_service.dart';
import 'ocr_review_screen.dart';
import 'dart:io';

class DocumentsScreen extends ConsumerStatefulWidget {
  DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allDocs {
    final hiveDocs = HiveService.getAllDocs();
    return hiveDocs.map((doc) {
      IconData icon;
      switch (doc.docType) {
        case '10th':
        case '12th':
          icon = Icons.description_rounded;
          break;
        case 'graduation':
          icon = Icons.school_rounded;
          break;
        case 'admit_card':
          icon = Icons.badge_rounded;
          break;
        default:
          icon = Icons.insert_drive_file_rounded;
      }

      return {
        'name': doc.docType == '10th'
            ? '10th Marksheet'
            : doc.docType == '12th'
                ? '12th Marksheet'
                : doc.docType == 'graduation'
                    ? 'Graduation Certificate'
                    : doc.docType == 'admit_card'
                        ? 'Admit Card'
                        : 'Document',
        'type': 'Marksheet',
        'date':
            '${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}',
        'status': doc.isVerified ? 'Verified' : 'Needs Review',
        'icon': icon,
        'id': doc.id,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredDocs {
    final all = _allDocs;
    if (_currentTab == 0) return all;
    if (_currentTab == 1) {
      return all
          .where((d) => d['type'] == 'Marksheet' || d['type'] == 'Certificate')
          .toList();
    }
    return all.where((d) => d['type'] == 'ID Proof').toList();
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrProvider);

    if (ocrState.status == OcrStatus.processing ||
        ocrState.status == OcrStatus.picking) {
      return Scaffold(
        backgroundColor: context.colors.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Scanning Document',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: OcrProgressCard(ocrState: ocrState),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Documents',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.glassWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.glassBorder),
              ),
              child: Icon(
                Icons.search_rounded,
                color: context.colors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      _buildTab('All', 0),
                      _buildTab('Scanned', 1),
                      _buildTab('Uploaded', 2),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredDocs.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.document_scanner_rounded,
                      title: AppStrings.noDocumentsTitle,
                      subtitle: AppStrings.noDocumentsSubtitle,
                      actionLabel: 'Scan Document',
                      onAction: _showScanSheet,
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = _filteredDocs[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: ScannedDocCard(
                            name: doc['name'],
                            type: doc['type'],
                            date: doc['date'],
                            status: doc['status'],
                            icon: doc['icon'],
                            onTap: () => _showDocumentDetails(doc['id']),
                            onDelete: () async {
                              await HiveService.deleteDoc(doc['id']);
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScanSheet,
        backgroundColor: context.colors.primary,
        elevation: 8,
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.colors.textHint,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showDocumentDetails(String docId) {
    final doc = HiveService.getDoc(docId);
    if (doc == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        if (doc.fileName.isNotEmpty) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(doc.fileName),
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Center(
                    child: Text('Image not available', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          );
        }

        return AlertDialog(
          backgroundColor: context.colors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            doc.docType.toUpperCase(),
            style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Poppins'),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Status', doc.isVerified ? 'Verified' : 'Needs Review', context.colors.textPrimary),
                _detailRow('Uploaded At', '${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}', context.colors.textHint),
                const Divider(),
                _detailRow('Extracted Data', '', context.colors.primaryLight),
                const SizedBox(height: 8),
                Text(
                  doc.extractedText.isNotEmpty ? doc.extractedText : 'No raw text available.',
                  style: TextStyle(color: context.colors.textHint, fontSize: 12, fontFamily: 'Monospace'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor.withOpacity(0.8))),
           Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: valueColor))),
         ]
      ),
    );
  }

  void _showScanSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Scan Document',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how to add your document',
                style: TextStyle(
                  color: context.colors.textHint,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _buildScanOption(
                    Icons.camera_alt_rounded,
                    'Camera',
                    'Take a photo',
                    const Color(0xFF6C5CE7),
                    () async {
                      Navigator.pop(ctx);
                      await _scanDocument(fromCamera: true);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildScanOption(
                    Icons.photo_library_rounded,
                    'Gallery',
                    'Pick from gallery',
                    const Color(0xFF00B894),
                    () async {
                      Navigator.pop(ctx);
                      await _scanDocument(fromCamera: false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanDocument({required bool fromCamera}) async {
    final ocrNotifier = ref.read(ocrProvider.notifier);

    final result = fromCamera
        ? await ocrNotifier.scanFromCamera()
        : await ocrNotifier.scanFromGallery();

    if (result == null) return;

    if (result.docType == '12th' || result.docType == 'graduation') {
       final allDocs = HiveService.getAllDocs();
       final has10th = allDocs.any((d) => d.docType == '10th' || d.docType == '10th Pass');
       if (!has10th) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: const Text(
                 'Please upload your 10th marksheet first. It is the base document for identity verification.',
                 style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
               ),
               backgroundColor: context.colors.urgencyHigh,
               behavior: SnackBarBehavior.floating,
             ),
           );
         }
         ref.read(ocrProvider.notifier).reset();
         return;
       }
    }

    final user = ref.read(currentUserProvider);
    final profile = user != null ? HiveService.getUserProfile(user.uid) : null;
    
    bool isMismatch = false;
    String? warningMsg;

    if (profile != null && (result.docType == '12th' || result.docType == 'graduation')) {
        if (profile.dateOfBirth.isNotEmpty && result.dateOfBirth.isNotEmpty && profile.dateOfBirth != result.dateOfBirth) {
            isMismatch = true;
            warningMsg = 'Mismatch detected! DOB does not match your 10th base document.';
        }
        if (!isMismatch && profile.name.isNotEmpty && result.candidateName.isNotEmpty) {
             final pName = profile.name.toLowerCase().replaceAll(' ', '');
             final rName = result.candidateName.toLowerCase().replaceAll(' ', '');
             if (!pName.contains(rName) && !rName.contains(pName)) {
                 isMismatch = true;
                 warningMsg = 'Mismatch detected! Name does not match your 10th base document.';
             }
        }
    }

    final ocrState = ref.read(ocrProvider);
    bool forceReview = ocrState.needsReview || isMismatch;

    // LOW CONFIDENCE or MISMATCH => REVIEW
    if (forceReview) {
      if (!mounted) return;

      final action = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => OcrReviewScreen(
            result: result,
            warningMessage: warningMsg,
            onConfirm: ({
              required String docType,
              required String dateOfBirth,
              required String university,
              required String percentage,
              required String passingYear,
              required String extractedName,
              String? courseName,
              String? graduationStatus,
            }) async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref.read(profileNotifierProvider.notifier).updateFromOcr(
                      uid: user.uid,
                      docType: docType,
                      dateOfBirth: dateOfBirth,
                      university: university,
                      percentage: percentage,
                      passingYear: passingYear,
                      extractedName: extractedName,
                      primaryExamGoal: result.examName,
                      courseName: courseName,
                      graduationStatus: graduationStatus,
                      isVerified: true,
                      confidenceLevel: 1.0, // Manually reviewed counts as highly confident
                    );
              }
            },
          ),
        ),
      );

      if (action == 'save') {
        final allDocs = HiveService.getAllDocs();
        final unverifiedDocs = allDocs.where((d) => d.docType == result.docType && !d.isVerified).toList();
        if (unverifiedDocs.isNotEmpty) {
           final doc = unverifiedDocs.last;
           doc.isVerified = true;
           await HiveService.saveDoc(doc);
        }

        ref.read(ocrProvider.notifier).markReviewed();
        ref.read(ocrProvider.notifier).reset();

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Reviewed and saved successfully.',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
              ),
              backgroundColor: context.colors.eligible,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (action == 'reupload') {
        ref.read(ocrProvider.notifier).reset();
        if (mounted) {
             _showScanSheet();
        }
        return;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Review cancelled. Data not saved.',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
              ),
              backgroundColor: context.colors.urgencyMedium,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    // HIGH CONFIDENCE => DIRECT SAVE
    final attemptLogged = await _autoLogAttemptFromAdmitCard(result);

    if (result.dateOfBirth.isNotEmpty ||
        result.aggregate.isNotEmpty ||
        result.candidateName.isNotEmpty) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        String qual = '';
        if (result.docType == 'graduation') qual = 'Graduation';
        if (result.docType == '12th') qual = '12th Pass';
        if (result.docType == '10th') qual = '10th Pass';

        await ref.read(profileNotifierProvider.notifier).updateFromOcr(
              uid: user.uid,
              docType: qual,
              dateOfBirth: result.dateOfBirth,
              university: result.university,
              percentage: result.aggregate,
              passingYear: result.year,
              extractedName: result.candidateName,
              primaryExamGoal: result.examName,
              courseName: result.courseName,
              graduationStatus: result.graduationStatus,
              isVerified: true,
              confidenceLevel: result.confidence,
            );
      }
    }

    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.docType.isNotEmpty
                    ? '${result.docType.toUpperCase()} document scanned! Confidence: ${(result.confidence * 100).toInt()}%'
                        '${attemptLogged ? ' | Attempt auto-logged' : ''}'
                    : 'Document scanned successfully!',
                style:
                    const TextStyle(fontFamily: 'Poppins', color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: context.colors.eligible,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    ref.read(ocrProvider.notifier).reset();
  }

  Future<bool> _autoLogAttemptFromAdmitCard(OcrResult result) async {
    if (result.docType != 'admit_card') return false;
    if (result.examName.trim().isEmpty) return false;

    final examId = result.examName.trim();
    final matchedExams =
        ExamData.allExams.where((exam) => exam.id == examId).toList();
    if (matchedExams.isEmpty) return false;
    final exam = matchedExams.first;

    final box = Hive.isBoxOpen('attemptHistory')
        ? Hive.box('attemptHistory')
        : await Hive.openBox('attemptHistory');

    final roll = result.rollNumber.trim();
    final year = result.year.trim().isEmpty
        ? DateTime.now().year.toString()
        : result.year.trim();

    if (roll.isNotEmpty) {
      final duplicate = box.values.any((raw) {
        if (raw is! Map) return false;
        final entry = Map<String, dynamic>.from(raw);
        return entry['examId'] == examId &&
            (entry['year']?.toString() ?? '') == year &&
            (entry['rollNumber']?.toString() ?? '') == roll;
      });
      if (duplicate) return false;
    }

    var attemptCount = 0;
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      if ((entry['examId'] ?? '').toString() == examId) {
        attemptCount++;
      }
    }

    await box.add({
      'exam': exam.code,
      'examId': exam.id,
      'year': year,
      'result': 'Pending',
      'stage': _extractAttemptStage(result.rawText),
      'score': 'N/A',
      'attemptNumber': attemptCount + 1,
      'icon': _iconForExam(exam),
      'rollNumber': roll,
      'source': 'ocr_admit_card',
      'createdAt': DateTime.now().toIso8601String(),
    });

    return true;
  }

  String _extractAttemptStage(String rawText) {
    final text = rawText.toLowerCase();
    if (text.contains('interview')) return 'Interview';
    if (text.contains('mains')) return 'Mains';
    if (text.contains('tier ii') || text.contains('tier 2')) return 'Tier II';
    if (text.contains('tier i') || text.contains('tier 1')) return 'Tier I';
    if (text.contains('prelims') || text.contains('preliminary'))
      return 'Prelims';
    return 'Prelims';
  }

  String _iconForExam(ExamInfo exam) {
    switch (exam.category.toLowerCase()) {
      case 'upsc':
        return '🏛️';
      case 'ssc':
        return '📋';
      case 'banking':
        return '🏦';
      case 'defence':
        return '⚔️';
      case 'railways':
        return '🚆';
      default:
        return '📝';
    }
  }

  Widget _buildScanOption(
    IconData icon,
    String label,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: context.colors.bgCardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.glassBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
