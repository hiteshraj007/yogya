import 'package:flutter/material.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/ocr_profile_validator.dart';

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
    _name.dispose();
    _dob.dispose();
    _uni.dispose();
    _year.dispose();
    _score.dispose();
    _course.dispose();
    _status.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final isGrad = widget.result.docType == 'graduation';

    final e1 = OcrProfileValidator.validateDob(_dob.text);
    final e2 = OcrProfileValidator.validateYear(_year.text);
    final e3 = OcrProfileValidator.validatePercentageOrCgpa(
      _score.text,
      isGraduation: isGrad,
    );

    final err = e1 ?? e2 ?? e3;
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    try {
      await widget.onConfirm(
        docType: widget.result.docType == 'graduation'
            ? 'Graduation'
            : widget.result.docType == '12th'
                ? '12th Pass'
                : widget.result.docType == '10th'
                    ? '10th Pass'
                    : '',
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
      setState(() {
        _error = 'Failed to save. Please try again.';
        _isSaving = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSaving) return false;
    Navigator.pop(context, null);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review OCR Data'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isSaving ? null : () => Navigator.pop(context, null),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This information is read-only. Please verify it matches your document. If incorrect, use the Re-upload button.',
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.warningMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.warningMessage!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            TextField(
              controller: _name,
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _dob,
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(labelText: 'DOB (DD/MM/YYYY)'),
            ),
            TextField(
              controller: _uni,
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(labelText: 'University / Board'),
            ),
            if (widget.result.docType == 'graduation' && widget.result.courseName.isNotEmpty)
              TextField(
                controller: _course,
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
            if (widget.result.docType == 'graduation' && widget.result.graduationStatus.isNotEmpty)
              TextField(
                controller: _status,
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(labelText: 'Graduation Status'),
              ),
            TextField(
              controller: _year,
              readOnly: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(labelText: 'Passing Year'),
            ),
            TextField(
              controller: _score,
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(labelText: 'Percentage / CGPA'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm & Save'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context, 'reupload'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Re-upload Document'),
            ),
          ],
        ),
      ),
    );
  }
}