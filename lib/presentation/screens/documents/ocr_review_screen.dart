import 'package:flutter/material.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/ocr_profile_validator.dart';

class OcrReviewScreen extends StatefulWidget {
  final OcrResult result;
  final void Function({
    required String docType,
    required String dateOfBirth,
    required String university,
    required String percentage,
    required String passingYear,
    required String extractedName,
  }) onConfirm;

  const OcrReviewScreen({
    super.key,
    required this.result,
    required this.onConfirm,
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

  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.result.candidateName);
    _dob = TextEditingController(text: widget.result.dateOfBirth);
    _uni = TextEditingController(text: widget.result.university);
    _year = TextEditingController(text: widget.result.year);
    _score = TextEditingController(text: widget.result.aggregate);
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _uni.dispose();
    _year.dispose();
    _score.dispose();
    super.dispose();
  }

  void _submit() {
    final isGrad = widget.result.docType == 'graduation';

    final e1 = OcrProfileValidator.validateDob(_dob.text);
    final e2 = OcrProfileValidator.validateYear(_year.text);
    final e3 = OcrProfileValidator.validatePercentageOrCgpa(_score.text, isGraduation: isGrad);

    final err = e1 ?? e2 ?? e3;
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    widget.onConfirm(
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
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review OCR Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _dob, decoration: const InputDecoration(labelText: 'DOB (DD/MM/YYYY)')),
          TextField(controller: _uni, decoration: const InputDecoration(labelText: 'University / Board')),
          TextField(controller: _year, decoration: const InputDecoration(labelText: 'Passing Year')),
          TextField(controller: _score, decoration: const InputDecoration(labelText: 'Percentage / CGPA')),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
  }
}