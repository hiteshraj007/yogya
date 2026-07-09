import 'package:flutter_test/flutter_test.dart';
import 'package:yogya_app/core/services/ocr_service.dart';

/// Pure unit tests for OcrService static utility methods and OcrResult model.
/// These don't need any mocking — they test logic directly.
void main() {
  group('OcrService.canonicalDocType', () {
    test('maps "10th" variants correctly', () {
      expect(OcrService.canonicalDocType('10th'), '10th');
      expect(OcrService.canonicalDocType('Class 10'), '10th');
      expect(OcrService.canonicalDocType('SSLC'), '10th');
      expect(OcrService.canonicalDocType('matric'), '10th');
      expect(OcrService.canonicalDocType('secondary'), '10th');
      expect(OcrService.canonicalDocType('10TH'), '10th');
    });

    test('maps "12th" variants correctly', () {
      expect(OcrService.canonicalDocType('12th'), '12th');
      expect(OcrService.canonicalDocType('Class 12'), '12th');
      expect(OcrService.canonicalDocType('HSC'), '12th');
      expect(OcrService.canonicalDocType('intermediate'), '12th');
      expect(OcrService.canonicalDocType('Senior Secondary'), '12th');
      expect(OcrService.canonicalDocType('Higher Secondary'), '12th');
    });

    test('maps graduation variants correctly', () {
      expect(OcrService.canonicalDocType('graduation'), 'graduation');
      expect(OcrService.canonicalDocType('bachelor'), 'graduation');
      expect(OcrService.canonicalDocType('B.Tech'), 'graduation');
      expect(OcrService.canonicalDocType('degree'), 'graduation');
      expect(OcrService.canonicalDocType('UG'), 'graduation');
    });

    test('maps post-graduation variants correctly', () {
      expect(OcrService.canonicalDocType('master'), 'pg');
      expect(OcrService.canonicalDocType('M.Tech'), 'pg');
      expect(OcrService.canonicalDocType('PG'), 'pg');
      expect(OcrService.canonicalDocType('post graduate'), 'pg');
    });

    test('maps diploma variants correctly', () {
      expect(OcrService.canonicalDocType('diploma'), 'diploma');
      expect(OcrService.canonicalDocType('polytechnic'), 'diploma');
    });

    test('returns raw value for unknown types', () {
      expect(OcrService.canonicalDocType('unknown_type'), 'unknown_type');
      expect(OcrService.canonicalDocType(''), '');
    });
  });

  group('OcrService.normaliseNameForComparison', () {
    test('lowercases and trims', () {
      expect(OcrService.normaliseNameForComparison('  Hitesh Purohit  '), 'hitesh purohit');
    });

    test('removes special characters and numbers', () {
      expect(OcrService.normaliseNameForComparison('Mr. Hitesh123'), 'mr hitesh');
    });

    test('handles empty string', () {
      expect(OcrService.normaliseNameForComparison(''), '');
    });
  });

  group('OcrService.namesMatch', () {
    test('returns true for exact match', () {
      expect(OcrService.namesMatch('Hitesh Purohit', 'Hitesh Purohit'), isTrue);
    });

    test('returns true for case-insensitive match', () {
      expect(OcrService.namesMatch('HITESH PUROHIT', 'hitesh purohit'), isTrue);
    });

    test('returns true when two common words match', () {
      expect(OcrService.namesMatch('Hitesh Kumar Purohit', 'Hitesh Purohit'), isTrue);
    });

    test('returns false for empty strings', () {
      expect(OcrService.namesMatch('', 'Hitesh'), isFalse);
      expect(OcrService.namesMatch('Hitesh', ''), isFalse);
    });

    test('returns false for completely different names', () {
      expect(OcrService.namesMatch('Hitesh Purohit', 'Rahul Sharma'), isFalse);
    });
  });

  group('OcrResult model', () {
    test('creates successful result with defaults', () {
      const result = OcrResult(
        success: true,
        rawText: 'some text',
        docType: '10th',
      );
      expect(result.success, isTrue);
      expect(result.docType, '10th');
      expect(result.board, isEmpty);
      expect(result.confidence, 0.0);
      expect(result.errorMessage, isNull);
    });

    test('creates failure result', () {
      const result = OcrResult.failure('Something went wrong');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Something went wrong');
      expect(result.rawText, isEmpty);
      expect(result.docType, isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      const original = OcrResult(
        success: true,
        rawText: 'raw',
        docType: '10th',
        board: 'CBSE',
        confidence: 0.9,
      );
      final modified = original.copyWith(board: 'ICSE');
      expect(modified.success, isTrue);
      expect(modified.rawText, 'raw');
      expect(modified.docType, '10th');
      expect(modified.board, 'ICSE'); // changed
      expect(modified.confidence, 0.9);
    });

    test('copyWith can change confidence', () {
      const original = OcrResult(
        success: true,
        rawText: 'test',
        confidence: 0.5,
      );
      final modified = original.copyWith(confidence: 0.95);
      expect(modified.confidence, 0.95);
    });
  });
}
