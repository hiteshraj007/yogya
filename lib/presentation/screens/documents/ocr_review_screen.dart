import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/ocr_profile_validator.dart';
import '../../../core/theme/theme_colors.dart';
import '../../widgets/common/app_button.dart';

class OcrReviewScreen extends StatefulWidget {
  final OcrResult result;
  final Future<void> Function({
    required String docType,
    required String dateOfBirth,
    required String university,
    required String percentage,
    required String passingYear,
    required String extractedName,
    String? courseName,
    String? graduationStatus,
  }) onConfirm;
  final String? warningMessage;

  const OcrReviewScreen({
    super.key,
    required this.result,
    required this.onConfirm,
    this.warningMessage,
  });

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  late final TextEditingController _name;
  late final TextEditingController _dob;
  late final TextEditingController _uni;
  late final TextEditingController _year;
  late final TextEditingController _score;
  late final TextEditingController _course;
  late final TextEditingController _status;

  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.result.candidateName);
    _dob = TextEditingController(text: widget.result.dateOfBirth);
    _uni = TextEditingController(text: widget.result.university);
    _year = TextEditingController(text: widget.result.year);
    _score = TextEditingController(text: widget.result.aggregate);
    _course = TextEditingController(text: widget.result.courseName);
    _status = TextEditingController(text: widget.result.graduationStatus);
  }

  @override
  void dispose() {
    _name.dispose(); _dob.dispose(); _uni.dispose(); _year.dispose();
    _score.dispose(); _course.dispose(); _status.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final isGrad = widget.result.docType == 'graduation';

    final e2 = OcrProfileValidator.validateYear(_year.text);
    final e3 = OcrProfileValidator.validatePercentageOrCgpa(_score.text, isGraduation: isGrad);
    
    // Validate DOB only if it's 10th
    String? e1;
    if (widget.result.docType != '12th' && widget.result.docType != 'graduation') {
       e1 = OcrProfileValidator.validateDob(_dob.text);
    }

    final err = e1 ?? e2 ?? e3;
    if (err != null) { setState(() => _error = err); return; }

    setState(() { _error = null; _isSaving = true; });

    try {
      await widget.onConfirm(
        docType: widget.result.docType == 'graduation' ? 'Graduation' : widget.result.docType == '12th' ? '12th Pass' : widget.result.docType == '10th' ? '10th Pass' : '',
        dateOfBirth: _dob.text.trim(),
        university: _uni.text.trim(),
        percentage: _score.text.trim(),
        passingYear: _year.text.trim(),
        extractedName: _name.text.trim(),
        courseName: _course.text.trim(),
        graduationStatus: _status.text.trim(),
      );
      if (mounted) Navigator.pop(context, 'save');
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Failed to save. Please try again.'; _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSaving) {
          Navigator.pop(context, null);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Deep modern background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner_rounded, color: context.colors.primary, size: 24),
              const SizedBox(width: 8),
              const Text('AI Data Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _isSaving ? null : () => Navigator.pop(context, null),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // ── DOCUMENT VIEW SECTION ────────────────────────
            if (widget.result.imagePath != null)
              _buildImagePreview(widget.result.imagePath!),

            const SizedBox(height: 24),

            // ── INFO BANNER ───────────────────────────────
            _buildInfoBanner(),

            const SizedBox(height: 20),

            if (widget.warningMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.warningMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── FORM SECTION ──────────────────────────────
            _buildSectionHeader('Verification Details'),
            const SizedBox(height: 16),

            // 🔥 LOCKED FIELDS FOR 12th AND GRADUATION 🔥
            if (widget.result.docType == '12th' || widget.result.docType == 'graduation')
              _buildLockBanner()
            else ...[
              _buildLabelText('Full Name'),
              _buildDisplayField(_name, Icons.person_outline),
              const SizedBox(height: 16),
              _buildLabelText('Date of Birth'),
              _buildDisplayField(_dob, Icons.calendar_today_outlined),
              const SizedBox(height: 16),
            ],

            _buildLabelText('University / Board'),
            _buildDisplayField(_uni, Icons.school_outlined),
            const SizedBox(height: 16),

            if (widget.result.docType == 'graduation') ...[
              _buildLabelText('Course Name'),
              _buildDisplayField(_course, Icons.book_outlined),
              const SizedBox(height: 16),
              _buildLabelText('Graduation Status'),
              _buildDisplayField(_status, Icons.info_outline),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelText('Year'),
                      _buildDisplayField(_year, Icons.event_available_outlined),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelText('Score'),
                      _buildDisplayField(_score, Icons.analytics_outlined),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.result.subjectMarks.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader('Subjects & Marks'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.1)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.result.subjectMarks.length,
                  separatorBuilder: (context, index) => Divider(color: context.colors.textSecondary.withValues(alpha: 0.1), height: 1),
                  itemBuilder: (context, index) {
                    final key = widget.result.subjectMarks.keys.elementAt(index);
                    final value = widget.result.subjectMarks[key];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              key,
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              value ?? '',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              _buildSectionHeader('Subjects & Marks'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No subjects were extracted. Please select Re-upload if subjects are missing.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null) _buildErrorText(_error!),

            const SizedBox(height: 40),

            // ── ACTION BUTTONS ────────────────────────────
            AppButton(
              label: 'Proceed & Save',
              onPressed: _submit,
              isLoading: _isSaving,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context, 'reupload'),
              child: const Text(
                'Information is incorrect? Re-upload',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    return GestureDetector(
      onTap: () => _showFullImage(path),
      child: Center(
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.primary.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
            image: DecorationImage(
              image: FileImage(File(path)),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner_rounded, color: Colors.white, size: 38),
                  SizedBox(height: 8),
                  Text('RAW DATA CAPTURE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  SizedBox(height: 4),
                  Text('Tap to expand', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(String path) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close preview',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (dialogContext, _, __) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Center(
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'Preview not available',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(dialogContext).padding.top + 12,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.primary),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: context.colors.primary, size: 28),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'AI Engine has processed this document. Review the extracted JSON data fields below.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.security_rounded, color: Colors.orange, size: 24),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Identity Locked: Name & DOB are secured against your 10th base document.',
              style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayField(TextEditingController controller, IconData icon) {
    final hasValue = controller.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: hasValue ? context.colors.bgSurface.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasValue ? context.colors.primary.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: hasValue ? Colors.white : Colors.redAccent,
        ),
        decoration: InputDecoration(
          hintText: 'Tap to enter missing data',
          hintStyle: const TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, size: 22, color: hasValue ? context.colors.primary : Colors.redAccent),
          suffixIcon: hasValue
              ? Icon(Icons.check_circle_rounded, size: 18, color: context.colors.primary)
              : const Icon(Icons.error_outline_rounded, size: 18, color: Colors.redAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.colors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
      ),
    );
  }
}
