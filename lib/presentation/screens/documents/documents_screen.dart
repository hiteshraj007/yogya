import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_animations.dart';
import '../../../data/providers/ocr_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/local/hive_service.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'widgets/scanned_doc_card.dart';
import 'widgets/ocr_progress_card.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/pdf_parser_service.dart';
import 'ocr_review_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/strings.dart';
import '../../../data/models/academic_doc_model.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  bool _isSearching = false;
  String _searchQuery = '';
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
    final uid = ref.watch(currentUserProvider)?.uid;
    final hiveDocs = HiveService.getAllDocs(uid: uid);
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
    var all = _allDocs;
    if (_searchQuery.isNotEmpty) {
      all = all.where((d) => 
        d['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_currentTab == 0) return all;
    if (_currentTab == 1) {
      return all.where((d) => d['status'] == 'Verified').toList();
    }
    return all.where((d) => d['status'] != 'Verified').toList();
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrProvider);
    final profileState = ref.watch(profileNotifierProvider);

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
              child: OcrProgressCard(
                ocrState: ocrState,
                onCancel: () {
                  ref.read(ocrProvider.notifier).reset();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Scanning cancelled.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF4A4A6A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      );
    }

    if (profileState.isLoading) {
      return Scaffold(
        backgroundColor: context.colors.bgDark,
        body: Center(
          child: CircularProgressIndicator(
            color: context.colors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: TextStyle(color: context.colors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
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
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: context.colors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
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
                      _buildTab('Verified', 1),
                      _buildTab('Action Needed', 2),
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
           Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor.withValues(alpha: 0.8))),
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
                'Add Document',
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
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
                  _buildScanOption(
                    Icons.picture_as_pdf_rounded,
                    'Upload PDF',
                    'From your files',
                    const Color(0xFFE17055),
                    () async {
                      Navigator.pop(ctx);
                      await _uploadPdf();
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
    await _handleOcrResult(result);
  }

  /// Picks a PDF file and routes its bytes through the PDF parser microservice.
  Future<void> _uploadPdf() async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file picker: $e',
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            backgroundColor: context.colors.urgencyHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not read PDF file.',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            backgroundColor: context.colors.urgencyHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final ocrNotifier = ref.read(ocrProvider.notifier);
    final result = await ocrNotifier.parsePdfBytes(bytes, file.name);

    if (result == null) {
      // Error already stored in ocrState; show it
      final errMsg = ref.read(ocrProvider).errorMessage ?? 'PDF parsing failed.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg,
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            backgroundColor: context.colors.urgencyHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(ocrProvider.notifier).reset();
      }
      return;
    }

    // Reuse the same post-scan pipeline as image OCR
    await _handleOcrResult(result);
  }

  /// Common post-OCR handler shared between image scan and PDF upload flows.
  Future<void> _handleOcrResult(OcrResult result) async {
    if (result.docType == '12th' || result.docType == 'graduation') {
      final uid = ref.read(currentUserProvider)?.uid;
      final allDocs = HiveService.getAllDocs(uid: uid);
      final has10th = allDocs.any((d) => d.docType == '10th' || d.docType == '10th Pass');
      if (!has10th) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please upload your 10th marksheet first.',
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

    // DOB is exclusively sourced from the 10th marksheet — do NOT compare it
    // against 12th/graduation documents which rarely contain it reliably.
    if (profile != null && (result.docType == '12th' || result.docType == 'graduation' || result.docType == 'pg')) {
      if (profile.name.trim().isNotEmpty && result.candidateName.trim().isNotEmpty) {
        if (!PdfParserService.namesMatch(profile.name, result.candidateName)) {
          isMismatch = true;
          warningMsg = 'Name mismatch detected! "${result.candidateName}" does not match the name on your 10th marksheet.';
        }
      }
    }

    final ocrState = ref.read(ocrProvider);
    // User requested to ALWAYS show extracted details and ask if it is correct,
    // and handle situations where fields are missing.
    final hasMissingFields = result.candidateName.isEmpty || 
                             result.dateOfBirth.isEmpty || 
                             result.university.isEmpty || 
                             result.aggregate.isEmpty || 
                             result.subjectMarks.isEmpty;

    final forceReview = ocrState.needsReview || isMismatch || hasMissingFields || true; // Always force review as requested

    if (forceReview) {
      if (!mounted) return;
      final action = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => OcrReviewScreen(
            result: result,
            warningMessage: warningMsg ?? (hasMissingFields ? 'Some fields could not be extracted. Please review carefully or re-upload.' : null),
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
              final u = ref.read(currentUserProvider);
              if (u != null) {
                await ref.read(profileNotifierProvider.notifier).updateFromOcr(
                      uid: u.uid,
                      docType: docType,
                      dateOfBirth: dateOfBirth,
                      university: university,
                      board: result.board,
                      percentage: percentage,
                      passingYear: passingYear,
                      extractedName: extractedName,
                      primaryExamGoal: '',
                      courseName: courseName,
                      graduationStatus: graduationStatus,
                      isVerified: true,
                      confidenceLevel: 1.0,
                    );
              }
            },
          ),
        ),
      );

      if (action == 'save') {
        final uid = ref.read(currentUserProvider)?.uid;
        final allDocs = HiveService.getAllDocs(uid: uid);
        final sameTypeDocs = allDocs.where((d) => d.docType == result.docType).toList();
        
        AcademicDocModel? docToSave;
        
        // Find the newest unverified doc to keep
        final unverifiedDocs = sameTypeDocs.where((d) => !d.isVerified).toList();
        if (unverifiedDocs.isNotEmpty) {
          docToSave = unverifiedDocs.last;
          docToSave.isVerified = true;
          await HiveService.saveDoc(docToSave, uid: uid);
        }
        
        // Delete ALL other documents of this type (old verified ones, and old unverified ones)
        for (var d in sameTypeDocs) {
          if (docToSave == null || d.id != docToSave.id) {
            await HiveService.deleteDoc(d.id, uid: uid);
          }
        }
        
        ref.read(ocrProvider.notifier).markReviewed();
        ref.read(ocrProvider.notifier).reset();
        
        // Force profile reload so it shows the new data
        if (uid != null) {
          ref.read(profileNotifierProvider.notifier).loadProfile(uid);
        }

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Document updated successfully.',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
              backgroundColor: context.colors.eligible,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (action == 'reupload' || action == 'cancel') {
        final uid = ref.read(currentUserProvider)?.uid;
        final allDocs = HiveService.getAllDocs(uid: uid);
        // Find the newly added unverified doc and delete it so it doesn't clutter
        final unverifiedDocs = allDocs.where((d) => d.docType == result.docType && !d.isVerified).toList();
        if (unverifiedDocs.isNotEmpty) {
          await HiveService.deleteDoc(unverifiedDocs.last.id, uid: uid);
        }
        
        ref.read(ocrProvider.notifier).reset();
        
        if (action == 'reupload' && mounted) {
          _showScanSheet();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Review cancelled. Document not saved.',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
              backgroundColor: context.colors.urgencyMedium,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {});
        }
      }
      return;
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
                  color: color.withValues(alpha: 0.15),
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
