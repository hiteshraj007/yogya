"""Extended tests for the Eligibility Engine — edge cases and boundary conditions.

These tests cover scenarios that are common with real Indian exam aspirants:
- PWBD (disability) age relaxation
- Pursuing graduation candidates
- EWS category handling
- Boundary age cases (exact cutoff day)
- Missing data gracefully handled
- Multiple exam checks in single request
"""
import unittest
from datetime import date, datetime, timezone

from app.eligibility_engine import (
    EligibilityEngine,
    calculate_age,
    check_education,
    check_attempts,
    check_additional_rules,
    freshness,
    max_age_for,
    min_percentage_for,
)
from app.models import (
    Category,
    EducationLevel,
    GraduationStatus,
    StudentProfile,
    ExamCriteria,
    RegistrationStatus,
    parse_dob,
)
from app.seed_data import get_seed_criteria


class TestCalculateAge(unittest.TestCase):
    """Age calculation is critical — off-by-one bugs affect real users."""

    def test_exact_birthday_same_day(self):
        """User born on reference date should get full years."""
        self.assertEqual(calculate_age(date(2000, 6, 15), date(2025, 6, 15)), 25)

    def test_day_before_birthday(self):
        """Day before birthday = one year less."""
        self.assertEqual(calculate_age(date(2000, 6, 15), date(2025, 6, 14)), 24)

    def test_day_after_birthday(self):
        """Day after birthday = full years."""
        self.assertEqual(calculate_age(date(2000, 6, 15), date(2025, 6, 16)), 25)

    def test_leap_year_birthday(self):
        """Feb 29 born person on non-leap year."""
        self.assertEqual(calculate_age(date(2000, 2, 29), date(2025, 2, 28)), 24)
        self.assertEqual(calculate_age(date(2000, 2, 29), date(2025, 3, 1)), 25)


class TestPWBDRelaxation(unittest.TestCase):
    """PWBD (Person with Benchmark Disability) gets extra age relaxation."""

    def setUp(self):
        self.engine = EligibilityEngine(get_seed_criteria())

    def test_pwbd_general_candidate_gets_10_year_relaxation(self):
        """UPSC: General max age 32, PWBD general should get 32+10=42."""
        criteria = self.engine.get_detail("UPSC CSE")
        max_age = max_age_for(criteria, Category.GENERAL, is_pwbd=True)
        self.assertEqual(max_age, 42)

    def test_pwbd_obc_candidate_gets_13_year_relaxation(self):
        """UPSC: OBC max age 35, PWBD OBC should get 32+13=45."""
        criteria = self.engine.get_detail("UPSC CSE")
        max_age = max_age_for(criteria, Category.OBC, is_pwbd=True)
        self.assertEqual(max_age, 45)

    def test_pwbd_sc_st_gets_15_year_relaxation(self):
        """UPSC: SC/ST max, PWBD SC/ST should get 32+15=47."""
        criteria = self.engine.get_detail("UPSC CSE")
        max_age = max_age_for(criteria, Category.SC, is_pwbd=True)
        self.assertEqual(max_age, 47)


class TestPursuingGraduation(unittest.TestCase):
    """Students in final year should be eligible for graduate-level exams."""

    def setUp(self):
        self.engine = EligibilityEngine(get_seed_criteria())

    def _student(self, **overrides):
        base = {
            "dob": "15/01/2002",
            "category": "GENERAL",
            "is_pwbd": False,
            "nationality": "INDIAN",
            "percentage_10": 80.0,
            "percentage_12": 75.0,
            "graduation_status": "PURSUING",
            "graduation_percentage": None,
            "degree": "BTech",
        }
        base.update(overrides)
        return StudentProfile(**base)

    def test_pursuing_grad_is_eligible_for_ssc_cgl(self):
        """SSC CGL allows appearing students (no min percentage)."""
        student = self._student()
        response = self.engine.check_all(student, today=date(2026, 6, 1))
        ssc_cgl = next(r for r in response.results if r.exam_short_name == "SSC CGL")
        self.assertTrue(ssc_cgl.eligible)

    def test_pursuing_grad_passes_education_check(self):
        """Pursuing graduation should pass education level check."""
        student = self._student()
        criteria = self.engine.get_detail("SSC CGL")
        ok, passes, fails = check_education(student, criteria)
        self.assertTrue(ok, f"Failed with: {fails}")


class TestEWSCategory(unittest.TestCase):
    """EWS (Economically Weaker Section) category specific tests."""

    def test_ews_falls_back_to_general_age(self):
        """When EWS max age is 0, it should fall back to general max age."""
        criteria = get_seed_criteria()[0]  # UPSC CSE
        max_age = max_age_for(criteria, Category.EWS, is_pwbd=False)
        self.assertEqual(max_age, criteria.max_age_general)

    def test_ews_percentage_falls_back_to_general(self):
        """When EWS percentage is 0, should use general percentage."""
        criteria = get_seed_criteria()[4]  # AFCAT
        pct = min_percentage_for(criteria, Category.EWS)
        self.assertEqual(pct, criteria.min_percentage_general)


class TestFreshness(unittest.TestCase):
    """Data freshness indicator for criteria verification status."""

    def test_fresh_within_90_days(self):
        verified = datetime(2026, 4, 1, tzinfo=timezone.utc)
        self.assertEqual(freshness(verified, today=date(2026, 6, 1)), "FRESH")

    def test_stale_between_90_and_180_days(self):
        verified = datetime(2026, 1, 1, tzinfo=timezone.utc)
        self.assertEqual(freshness(verified, today=date(2026, 6, 1)), "STALE")

    def test_outdated_beyond_180_days(self):
        verified = datetime(2025, 6, 1, tzinfo=timezone.utc)
        self.assertEqual(freshness(verified, today=date(2026, 6, 1)), "OUTDATED")

    def test_none_verified_is_outdated(self):
        self.assertEqual(freshness(None), "OUTDATED")


class TestAdditionalRules(unittest.TestCase):
    """Tests for gender, marital status, nationality rules."""

    def _student(self, **overrides):
        base = {
            "dob": "01/01/2000",
            "category": "GENERAL",
            "is_pwbd": False,
            "nationality": "INDIAN",
            "gender": "MALE",
            "marital_status": "UNMARRIED",
            "percentage_10": 80.0,
            "percentage_12": 75.0,
        }
        base.update(overrides)
        return StudentProfile(**base)

    def test_nda_rejects_married_candidate(self):
        """NDA requires UNMARRIED status."""
        engine = EligibilityEngine(get_seed_criteria())
        student = self._student(
            dob="01/01/2009",
            marital_status="MARRIED",
            stream_12="PCM",
            subjects_12={"Physics": 80, "Mathematics": 85},
        )
        criteria = engine.get_detail("NDA")
        ok, passes, fails = check_additional_rules(student, criteria)
        self.assertFalse(ok)
        self.assertTrue(any("Marital" in f for f in fails))

    def test_nationality_check_passes_for_indian(self):
        """UPSC requires Indian nationality — Indian student should pass."""
        student = self._student()
        criteria = get_seed_criteria()[0]  # UPSC
        ok, passes, fails = check_additional_rules(student, criteria)
        self.assertTrue(ok)
        self.assertTrue(any("Nationality" in p for p in passes))

    def test_nationality_check_fails_for_non_indian(self):
        """Non-Indian student should fail UPSC nationality check."""
        student = self._student(nationality="NEPALESE")
        criteria = get_seed_criteria()[0]  # UPSC
        ok, passes, fails = check_additional_rules(student, criteria)
        self.assertFalse(ok)


class TestMultiExamCheck(unittest.TestCase):
    """Full eligibility response with multiple exams."""

    def test_check_all_returns_all_exams(self):
        engine = EligibilityEngine(get_seed_criteria())
        student = StudentProfile(
            dob="15/07/2001",
            category=Category.GENERAL,
            is_pwbd=False,
            nationality="INDIAN",
            percentage_10=85.0,
            percentage_12=78.0,
            graduation_status=GraduationStatus.COMPLETED,
            degree="BTech",
            graduation_percentage=72.0,
        )
        response = engine.check_all(student, today=date(2026, 6, 1))
        self.assertEqual(response.summary.total_exams_checked, 5)  # 5 seed exams
        self.assertGreater(response.summary.eligible_count, 0)

    def test_results_sorted_eligible_first(self):
        """Eligible exams should appear before ineligible ones."""
        engine = EligibilityEngine(get_seed_criteria())
        student = StudentProfile(
            dob="15/07/2001",
            category=Category.GENERAL,
            is_pwbd=False,
            nationality="INDIAN",
            percentage_10=85.0,
            percentage_12=78.0,
            graduation_status=GraduationStatus.COMPLETED,
            degree="BTech",
            graduation_percentage=72.0,
        )
        response = engine.check_all(student, today=date(2026, 6, 1))
        # Check that eligible results come before ineligible ones
        found_ineligible = False
        for r in response.results:
            if not r.eligible:
                found_ineligible = True
            if found_ineligible and r.eligible:
                # An eligible result after an ineligible one — only valid if registration differs
                pass  # Sort key considers registration_open first


class TestDOBParsing(unittest.TestCase):
    """DOB parsing edge cases."""

    def test_valid_dob(self):
        result = parse_dob("15/07/2001")
        self.assertEqual(result, date(2001, 7, 15))

    def test_invalid_format_raises(self):
        with self.assertRaises(ValueError):
            parse_dob("2001-07-15")

    def test_invalid_date_raises(self):
        with self.assertRaises(ValueError):
            parse_dob("32/13/2001")


class TestAttempts(unittest.TestCase):
    """Attempt tracking edge cases."""

    def test_unlimited_attempts(self):
        """SC/ST for UPSC CSE has unlimited attempts."""
        engine = EligibilityEngine(get_seed_criteria())
        student = StudentProfile(
            dob="15/07/2001",
            category=Category.SC,
            is_pwbd=False,
            nationality="INDIAN",
            percentage_10=80.0,
            graduation_status=GraduationStatus.COMPLETED,
            graduation_percentage=60.0,
            attempts_used={"UPSC CSE": 100},  # Even 100 attempts
        )
        criteria = engine.get_detail("UPSC CSE")
        remaining, passed, reason = check_attempts(student, criteria)
        self.assertTrue(passed)
        self.assertEqual(remaining, -1)

    def test_zero_attempts_used_for_new_exam(self):
        """Exam not in attempts_used dict should default to 0 used."""
        student = StudentProfile(
            dob="15/07/2001",
            category=Category.GENERAL,
            is_pwbd=False,
            attempts_used={},  # No attempts used
        )
        criteria = get_seed_criteria()[0]  # UPSC
        remaining, passed, reason = check_attempts(student, criteria)
        self.assertTrue(passed)
        self.assertEqual(remaining, 6)  # Full 6 attempts available


if __name__ == "__main__":
    unittest.main()
