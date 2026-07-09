import unittest
from datetime import date

from app.eligibility_engine import EligibilityEngine, calculate_age
from app.models import Category, StudentProfile, parse_dob
from app.seed_data import get_seed_criteria


class EligibilityEngineTest(unittest.TestCase):
    def setUp(self):
        self.engine = EligibilityEngine(get_seed_criteria())

    def student(self, **overrides):
        data = {
            "dob": "15/07/2001",
            "category": Category.GENERAL,
            "is_pwbd": False,
            "gender": "MALE",
            "nationality": "INDIAN",
            "percentage_10": 87.4,
            "percentage_12": 79.2,
            "stream_12": "PCM",
            "subjects_12": {
                "Physics": 82,
                "Chemistry": 75,
                "Mathematics": 81,
                "English": 78,
            },
            "graduation_status": "COMPLETED",
            "degree": "BTech",
            "graduation_percentage": 74.1,
            "attempts_used": {"UPSC CSE": 2},
        }
        data.update(overrides)
        return StudentProfile(**data)

    def result_for(self, exam_name, student=None):
        response = self.engine.check_all(
            student or self.student(),
            today=date(2026, 6, 7),
        )
        return next(item for item in response.results if item.exam_short_name == exam_name)

    def test_age_is_calculated_against_exam_cutoff(self):
        self.assertEqual(calculate_age(parse_dob("15/07/2001"), date(2026, 8, 1)), 25)

    def test_upsc_general_candidate_passes_with_attempts_remaining(self):
        result = self.result_for("UPSC CSE")
        self.assertTrue(result.eligible)
        self.assertEqual(result.age_at_cutoff, 25)
        self.assertEqual(result.attempts_remaining, 4)

    def test_upsc_fails_when_attempt_limit_reached(self):
        student = self.student(attempts_used={"UPSC CSE": 6})
        result = self.result_for("UPSC CSE", student)
        self.assertFalse(result.eligible)
        self.assertIn("No attempts remaining", " ".join(result.reasons_fail))

    def test_obc_age_relaxation_fallback_allows_candidate(self):
        student = self.student(category=Category.OBC, dob="10/10/1992")
        result = self.result_for("UPSC CSE", student)
        self.assertTrue(result.eligible)

    def test_nda_requires_stream_and_subjects(self):
        student = self.student(
            dob="01/01/2009",
            stream_12="COMMERCE",
            subjects_12={"Accountancy": 80, "Economics": 82},
            graduation_status="NOT_APPLICABLE",
            graduation_percentage=None,
            marital_status="UNMARRIED",
        )
        result = self.result_for("NDA", student)
        self.assertFalse(result.eligible)
        joined = " ".join(result.reasons_fail)
        self.assertIn("Stream required", joined)
        self.assertIn("Missing required subjects", joined)

    def test_afcat_checks_minimum_graduation_percentage(self):
        student = self.student(graduation_percentage=54)
        result = self.result_for("AFCAT", student)
        self.assertFalse(result.eligible)
        self.assertIn("percentage", " ".join(result.reasons_fail))


if __name__ == "__main__":
    unittest.main()

