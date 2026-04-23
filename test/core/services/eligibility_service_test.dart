import 'package:flutter_test/flutter_test.dart';
import 'package:yogya_app/core/constants/exam_data.dart';
import 'package:yogya_app/core/services/eligibility_service.dart';
import 'package:yogya_app/data/models/academic_doc_model.dart';
import 'package:yogya_app/data/models/user_profile_model.dart';

void main() {
  group('EligibilityService', () {
    final service = EligibilityService.instance;

    UserProfileModel profile({
      String category = 'General',
      String dob = '10/10/2001',
      String qualification = 'Graduation',
      String percentage = '65%',
    }) {
      return UserProfileModel(
        id: 'u1',
        name: 'Aditi',
        email: 'aditi@example.com',
        category: category,
        dateOfBirth: dob,
        qualification: qualification,
        percentage: percentage,
      );
    }

    List<AcademicDocModel> docs() {
      return [
        AcademicDocModel(
          id: 'd10',
          docType: '10th',
          aggregate: '83%',
          uploadedAt: DateTime.now(),
        ),
        AcademicDocModel(
          id: 'd12',
          docType: '12th',
          aggregate: '79%',
          uploadedAt: DateTime.now(),
        ),
        AcademicDocModel(
          id: 'dgrad',
          docType: 'graduation',
          aggregate: '65%',
          uploadedAt: DateTime.now(),
        ),
      ];
    }

    test('marks UPSC as eligible for valid general candidate', () {
      final result = service.evaluate(
        profile: profile(),
        docs: docs(),
        attemptsByExam: {'upsc_cse': 1},
        examIds: {'upsc_cse'},
      );

      expect(result, hasLength(1));
      expect(result.first.exam.id, 'upsc_cse');
      expect(result.first.isEligible, isTrue);
      expect(result.first.status, 'ELIGIBLE');
    });

    test('applies OBC age relaxation for UPSC', () {
      final result = service.evaluate(
        profile: profile(
          category: 'OBC',
          dob: '10/10/1992', // ~33 years in 2026
        ),
        docs: docs(),
        attemptsByExam: {'upsc_cse': 1},
        examIds: {'upsc_cse'},
      );

      expect(result.first.isEligible, isTrue);
      expect(result.first.maxAge, ExamData.allExams
          .firstWhere((e) => e.id == 'upsc_cse')
          .maxAgeOBC);
    });

    test('fails when attempt limit is reached for general UPSC', () {
      final result = service.evaluate(
        profile: profile(),
        docs: docs(),
        attemptsByExam: {'upsc_cse': 6},
        examIds: {'upsc_cse'},
      );

      expect(result.first.isEligible, isFalse);
      expect(result.first.criteria['Attempts'], isFalse);
    });

    test('fails AFCAT when graduation percent is below 60', () {
      final result = service.evaluate(
        profile: profile(percentage: '54%'),
        docs: [
          AcademicDocModel(
            id: 'dgrad',
            docType: 'graduation',
            aggregate: '54%',
            uploadedAt: DateTime.now(),
          ),
        ],
        attemptsByExam: const {},
        examIds: {'afcat'},
      );

      expect(result.first.isEligible, isFalse);
      expect(result.first.criteria['Qualification'], isFalse);
    });

    test('converts CGPA to percentage for min-60 checks', () {
      final result = service.evaluate(
        profile: profile(percentage: 'CGPA 7.0'),
        docs: [
          AcademicDocModel(
            id: 'dgrad',
            docType: 'graduation',
            aggregate: 'CGPA 7.0',
            uploadedAt: DateTime.now(),
          ),
        ],
        attemptsByExam: const {},
        examIds: {'rbi_grade_b'},
      );

      expect(result.first.isEligible, isTrue); // 7.0 * 9.5 = 66.5
    });

    test('calculates correct dynamic attempts for SSC CHSL based on age', () {
      final now = DateTime.now();
      // Assume user is 19 years old today
      final birthYear = now.year - 19;
      // Using month 1 and day 1 so age calculation guarantees 19
      final dob = '01/01/$birthYear'; 
      final result = service.evaluate(
        profile: profile(dob: dob, qualification: '12th Pass'),
        docs: [],
        attemptsByExam: {},
        examIds: {'ssc_chsl'},
      );

      final chslResult = result.first;
      expect(chslResult.isEligible, isTrue);
      // maxAge for General is 27. At age 19, remaining attempts = (27 - 19 + 1) * 1 = 9
      expect(chslResult.attemptsAllowed, 9);
    });

    test('calculates correct dynamic attempts for NDA based on frequency', () {
      final now = DateTime.now();
      final birthYear = now.year - 16;
      final dob = '01/01/$birthYear';
      final result = service.evaluate(
        profile: profile(dob: dob, qualification: '12th Pass'),
        docs: [],
        attemptsByExam: {},
        examIds: {'nda'},
      );

      final ndaResult = result.first;
      expect(ndaResult.isEligible, isTrue);
      // NDA frequency is 2. maxAge for General is 18. minAge is 16.
      // At age 16, remaining = (18 - 16 + 1) * 2 = 6
      expect(ndaResult.attemptsAllowed, 6);
    });

    test('caps attempts for UPSC based on fixed limit even if age permits', () {
      final now = DateTime.now();
      final birthYear = now.year - 25;
      final dob = '01/01/$birthYear';
      final result = service.evaluate(
        profile: profile(dob: dob),
        docs: docs(),
        attemptsByExam: {'upsc_cse': 2},
        examIds: {'upsc_cse'},
      );

      final upscResult = result.first;
      expect(upscResult.isEligible, isTrue);
      // Base limit is 6. Used is 2. Fixed remaining is 4.
      // Age remaining is 8. Actual remaining is min(8, 4) = 4.
      // Calculated allowed = used(2) + actual(4) = 6.
      expect(upscResult.attemptsAllowed, 6);
    });
  });
}

