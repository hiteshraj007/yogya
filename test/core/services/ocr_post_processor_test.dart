import 'package:flutter_test/flutter_test.dart';
import 'package:yogya_app/core/services/ocr_post_processor.dart';
import 'package:yogya_app/core/services/ocr_service.dart';

/// Tests for OcrPostProcessor — the AI output fixer.
/// These test real-world OCR errors that happen with Indian marksheets.
void main() {
  group('OcrPostProcessor.process — Subject marks fixing', () {
    test('swaps obtained/max when obtained > max', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        subjectMarks: {
          'Mathematics': '100/75',  // Swapped: obtained > max
          'Science': '80/100',       // Correct
        },
      );
      final result = OcrPostProcessor.process(input);
      expect(result.subjectMarks['Mathematics'], '75/100');
      expect(result.subjectMarks['Science'], '80/100');
    });

    test('removes subjects with max > 200 (total row misidentified)', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        subjectMarks: {
          'Mathematics': '85/100',
          'Total': '425/500',  // This is a total row, should be removed
        },
      );
      final result = OcrPostProcessor.process(input);
      expect(result.subjectMarks.containsKey('Total'), isFalse);
      expect(result.subjectMarks['Mathematics'], '85/100');
    });

    test('preserves grade in parentheses', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        subjectMarks: {
          'Hindi': '78/100 (B+)',
        },
      );
      final result = OcrPostProcessor.process(input);
      expect(result.subjectMarks['Hindi'], '78/100 (B+)');
    });

    test('keeps grade-only entries (Kerala SSLC style)', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        subjectMarks: {
          'Malayalam': 'A+',
          'English': 'B',
        },
      );
      final result = OcrPostProcessor.process(input);
      expect(result.subjectMarks['Malayalam'], 'A+');
      expect(result.subjectMarks['English'], 'B');
    });
  });

  group('OcrPostProcessor.process — Percentage fixing', () {
    test('keeps valid percentage unchanged', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        aggregate: '82.5%',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.aggregate, '82.5%');
    });

    test('clears percentage > 100 when no subjects to recalculate', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        aggregate: '150.0%',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.aggregate, isEmpty);
    });

    test('recalculates percentage from subjects when AI value is wrong', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        aggregate: '50.0%', // AI says 50% but subjects say higher
        subjectMarks: {
          'Math': '90/100',
          'Science': '85/100',
          'English': '80/100',
          'Hindi': '75/100',
        },
      );
      final result = OcrPostProcessor.process(input);
      // Calculated: (90+85+80+75)/(100*4) = 330/400 = 82.5%
      // diff from 50% > 5%, so should recalculate
      expect(result.aggregate, '82.5%');
    });
  });

  group('OcrPostProcessor.process — CGPA fixing', () {
    test('keeps valid CGPA unchanged', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        aggregate: 'CGPA 8.5',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.aggregate, 'CGPA 8.5');
    });

    test('converts CGPA > 10 to percentage (likely percentage stored as CGPA)', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        aggregate: 'CGPA 78.5',  // This is actually a percentage
      );
      final result = OcrPostProcessor.process(input);
      expect(result.aggregate, '78.5%');
    });

    test('clears invalid CGPA > 100', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        aggregate: 'CGPA 150',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.aggregate, isEmpty);
    });
  });

  group('OcrPostProcessor.process — Name fixing', () {
    test('clears name if it matches father name', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        candidateName: 'Rajesh Kumar',
        fatherName: 'Rajesh Kumar',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.candidateName, isEmpty);
    });

    test('clears name if it contains subject keywords', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        candidateName: 'MATHEMATICS TOTAL',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.candidateName, isEmpty);
    });

    test('removes digits from candidate name', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        candidateName: 'Hitesh123 Purohit',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.candidateName, 'Hitesh Purohit');
    });

    test('keeps valid name unchanged', () {
      const input = OcrResult(
        success: true,
        rawText: 'test',
        candidateName: 'Aditi Sharma',
        fatherName: 'Rakesh Sharma',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.candidateName, 'Aditi Sharma');
    });
  });

  group('OcrPostProcessor.process — Confidence recalculation', () {
    test('high confidence for result with many fields', () {
      const input = OcrResult(
        success: true,
        rawText: 'test data',
        docType: '10th',
        board: 'CBSE',
        year: '2020',
        aggregate: '82.5%',
        candidateName: 'Test Student',
        rollNumber: '12345',
        subjectMarks: {
          'Math': '85/100',
          'Science': '78/100',
          'English': '80/100',
        },
      );
      final result = OcrPostProcessor.process(input);
      expect(result.confidence, greaterThan(0.5));
    });

    test('low confidence for nearly empty result', () {
      const input = OcrResult(
        success: true,
        rawText: 'garbage',
      );
      final result = OcrPostProcessor.process(input);
      expect(result.confidence, lessThan(0.5));
    });
  });
}
