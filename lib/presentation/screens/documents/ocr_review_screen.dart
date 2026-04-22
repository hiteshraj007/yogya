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
        backgroundColor: context.colors.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Review Document', style: TextStyle(color: context.colors.textPrimary)),
          leading: IconButton(
            icon: Icon(Icons.close, color: context.colors.textPrimary),
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
              if (widget.result.courseName.isNotEmpty) ...[
                _buildLabelText('Course Name'),
                _buildDisplayField(_course, Icons.book_outlined),
                const SizedBox(height: 16),
              ],
              if (widget.result.graduationStatus.isNotEmpty) ...[
                _buildLabelText('Graduation Status'),
                _buildDisplayField(_status, Icons.info_outline),
                const SizedBox(height: 16),
              ],
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
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
            image: DecorationImage(
              image: FileImage(File(path)),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black26,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.zoom_in_rounded, color: Colors.white, size: 32),
                  SizedBox(height: 4),
                  Text('Tap to View Document', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.file(File(path))),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
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
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: context.colors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'OCR has extracted the following details. Please confirm if they are correct.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_person_outlined, color: Colors.orange, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Name and DOB are fetched from your verified 10th marksheet for security.',
              style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayField(TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.text.isEmpty ? 'Not found' : controller.text,
              style: TextStyle(
                color: controller.text.isEmpty ? context.colors.textSecondary : context.colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
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
