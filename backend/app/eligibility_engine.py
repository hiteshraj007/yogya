from __future__ import annotations

from datetime import date, datetime, timezone

from .models import (
    Category,
    EducationLevel,
    EligibilityResponse,
    EligibilityResult,
    EligibilitySummary,
    ExamCriteria,
    GraduationStatus,
    StudentProfile,
    parse_dob,
)


EDUCATION_RANK = {
    EducationLevel.TENTH: 1,
    EducationLevel.TWELFTH: 2,
    EducationLevel.GRADUATE: 3,
    EducationLevel.POST_GRADUATE: 4,
}


class EligibilityEngine:
    def __init__(self, criteria: list[ExamCriteria]):
        self._criteria = [item for item in criteria if item.is_active]

    def check_all(
        self,
        student: StudentProfile,
        *,
        today: date | None = None,
    ) -> EligibilityResponse:
        current_day = today or date.today()
        results = [
            self.check_one(student, criteria, today=current_day)
            for criteria in self._criteria
        ]
        results.sort(key=_sort_key)

        return EligibilityResponse(
            summary=EligibilitySummary(
                total_exams_checked=len(results),
                eligible_count=sum(1 for result in results if result.eligible),
                registration_open_count=sum(
                    1 for result in results if result.registration_open
                ),
            ),
            results=results,
        )

    def check_one(
        self,
        student: StudentProfile,
        criteria: ExamCriteria,
        *,
        today: date | None = None,
    ) -> EligibilityResult:
        current_day = today or date.today()
        reference_date = _age_reference_date(criteria, current_day)
        age = calculate_age(parse_dob(student.dob), reference_date)

        reasons_pass: list[str] = []
        reasons_fail: list[str] = []

        max_age = max_age_for(criteria, student.category, student.is_pwbd)
        if criteria.min_age and age < criteria.min_age:
            reasons_fail.append(f"Age {age} < minimum {criteria.min_age}")
        elif max_age and age > max_age:
            reasons_fail.append(
                f"Age {age} > maximum {max_age} for {student.category.value}"
            )
        else:
            limit_text = f"{criteria.min_age or 0}-{max_age or 'no upper limit'}"
            reasons_pass.append(f"Age {age} OK (limit: {limit_text})")

        education_ok, education_pass, education_fail = check_education(
            student, criteria
        )
        if education_ok:
            reasons_pass.extend(education_pass)
        else:
            reasons_fail.extend(education_fail)

        attempts_remaining, attempts_pass, attempts_reason = check_attempts(
            student, criteria
        )
        if attempts_pass:
            reasons_pass.append(attempts_reason)
        else:
            reasons_fail.append(attempts_reason)

        rule_pass, rule_reasons_pass, rule_reasons_fail = check_additional_rules(
            student, criteria
        )
        reasons_pass.extend(rule_reasons_pass)
        reasons_fail.extend(rule_reasons_fail)

        registration = criteria.registration
        registration_open = registration.registration_open
        if registration.registration_start and registration.registration_end:
            registration_open = (
                registration.registration_start.date()
                <= current_day
                <= registration.registration_end.date()
            )

        return EligibilityResult(
            exam_short_name=criteria.exam_short_name,
            exam_full_name=criteria.exam_full_name,
            exam_category=criteria.exam_category,
            conducting_body=criteria.conducting_body,
            eligible=not reasons_fail and education_ok and attempts_pass and rule_pass,
            reasons_pass=reasons_pass,
            reasons_fail=reasons_fail,
            age_at_cutoff=age,
            attempts_remaining=attempts_remaining,
            notification_year=criteria.notification_year,
            last_verified=criteria.verified_at,
            freshness=freshness(criteria.verified_at, today=current_day),
            source_pdf_url=criteria.source_pdf_url,
            registration_open=registration_open,
            registration_end=registration.registration_end,
            exam_date=registration.exam_date_text,
            apply_url=registration.apply_url,
            official_url=registration.official_url,
        )

    def get_detail(self, exam_short_name: str) -> ExamCriteria | None:
        normalized = _normalize_exam_name(exam_short_name)
        for criteria in self._criteria:
            if _normalize_exam_name(criteria.exam_short_name) == normalized:
                return criteria
        return None

    def open_exams(self, *, today: date | None = None) -> list[ExamCriteria]:
        current_day = today or date.today()
        open_items: list[ExamCriteria] = []
        for criteria in self._criteria:
            registration = criteria.registration
            is_open = registration.registration_open
            if registration.registration_start and registration.registration_end:
                is_open = (
                    registration.registration_start.date()
                    <= current_day
                    <= registration.registration_end.date()
                )
            if is_open:
                open_items.append(criteria)
        return open_items


def calculate_age(birth_date: date, reference_date: date) -> int:
    age = reference_date.year - birth_date.year
    if (reference_date.month, reference_date.day) < (
        birth_date.month,
        birth_date.day,
    ):
        age -= 1
    return age


def max_age_for(
    criteria: ExamCriteria,
    category: Category,
    is_pwbd: bool,
) -> int:
    if is_pwbd:
        if category == Category.OBC:
            return criteria.max_age_pwbd_obc or _pwbd_fallback_max_age(criteria, 13)
        if category in (Category.SC, Category.ST):
            return criteria.max_age_pwbd_sc_st or _pwbd_fallback_max_age(criteria, 15)
        return criteria.max_age_pwbd_general or _pwbd_fallback_max_age(criteria, 10)

    return _fallback_max_age(criteria, category)


def min_percentage_for(criteria: ExamCriteria, category: Category) -> float:
    if category == Category.OBC:
        return criteria.min_percentage_obc or criteria.min_percentage_general
    if category in (Category.SC, Category.ST):
        return criteria.min_percentage_sc_st
    if category == Category.EWS:
        return criteria.min_percentage_ews or criteria.min_percentage_general
    return criteria.min_percentage_general


def max_attempts_for(criteria: ExamCriteria, category: Category) -> int:
    if category == Category.OBC:
        return criteria.max_attempts_obc if criteria.max_attempts_obc != 0 else criteria.max_attempts_general
    if category in (Category.SC, Category.ST):
        return criteria.max_attempts_sc_st if criteria.max_attempts_sc_st != 0 else criteria.max_attempts_general
    if category == Category.EWS:
        if criteria.max_attempts_ews in (0, -1) and criteria.max_attempts_general != -1:
            return criteria.max_attempts_general
        return criteria.max_attempts_ews
    return criteria.max_attempts_general


def check_education(
    student: StudentProfile,
    criteria: ExamCriteria,
) -> tuple[bool, list[str], list[str]]:
    pass_reasons: list[str] = []
    fail_reasons: list[str] = []
    required = criteria.min_education
    student_level = _student_education_level(student)

    if student_level < EDUCATION_RANK[required]:
        fail_reasons.append(f"Required education: {required.value}")
        return False, pass_reasons, fail_reasons

    required_pct = min_percentage_for(criteria, student.category)
    student_pct = _percentage_for_required_level(student, required)
    pct_not_yet_available = (
        required == EducationLevel.GRADUATE
        and student.graduation_status == GraduationStatus.PURSUING
        and student_pct is None
    )
    if required_pct and not pct_not_yet_available and (student_pct is None or student_pct < required_pct):
        label = _education_label(required)
        fail_reasons.append(
            f"{label} percentage {student_pct or 0}% < required {required_pct}% "
            f"for {student.category.value}"
        )
    elif pct_not_yet_available:
        pass_reasons.append("Education: Graduation pursuing OK; final percentage pending")
    else:
        pass_reasons.append(f"Education: {_education_label(required)} OK")

    if criteria.required_stream:
        student_stream = (student.stream_12 or "").upper()
        required_streams = [stream.upper() for stream in criteria.required_stream]
        if student_stream not in required_streams:
            fail_reasons.append(
                "Stream required: "
                f"{', '.join(criteria.required_stream)} | Your stream: "
                f"{student.stream_12 or 'missing'}"
            )
        else:
            pass_reasons.append(f"Stream: {student.stream_12} OK")

    if criteria.required_subjects:
        subject_names = {name.lower() for name in student.subjects_12.keys()}
        missing = [
            subject
            for subject in criteria.required_subjects
            if subject.lower() not in subject_names
        ]
        if missing:
            fail_reasons.append(f"Missing required subjects: {', '.join(missing)}")
        else:
            pass_reasons.append("Required subjects OK")

    if criteria.required_degree and required == EducationLevel.GRADUATE:
        degree = (student.degree or "").lower()
        allowed = [item.lower() for item in criteria.required_degree]
        if degree not in allowed:
            fail_reasons.append(
                "Degree required: "
                f"{', '.join(criteria.required_degree)} | Your degree: "
                f"{student.degree or 'missing'}"
            )
        else:
            pass_reasons.append(f"Degree: {student.degree} OK")

    return not fail_reasons, pass_reasons, fail_reasons


def check_attempts(
    student: StudentProfile,
    criteria: ExamCriteria,
) -> tuple[int, bool, str]:
    maximum = max_attempts_for(criteria, student.category)
    used = student.attempts_used.get(criteria.exam_short_name, 0)
    if maximum == -1:
        return -1, True, "Unlimited attempts"
    remaining = max(maximum - used, 0)
    if used >= maximum:
        return remaining, False, f"No attempts remaining ({used}/{maximum} used)"
    return remaining, True, f"{remaining} attempts remaining"


def check_additional_rules(
    student: StudentProfile,
    criteria: ExamCriteria,
) -> tuple[bool, list[str], list[str]]:
    rules = criteria.additional_rules or {}
    pass_reasons: list[str] = []
    fail_reasons: list[str] = []

    expected_gender = rules.get("gender")
    if expected_gender and (student.gender or "").upper() != str(expected_gender).upper():
        fail_reasons.append(
            f"Gender required: {expected_gender} | Your gender: {student.gender or 'missing'}"
        )

    expected_marital = rules.get("marital_status")
    if expected_marital and (
        student.marital_status or ""
    ).upper() != str(expected_marital).upper():
        fail_reasons.append(
            "Marital status required: "
            f"{expected_marital} | Your status: {student.marital_status or 'missing'}"
        )

    if rules.get("nationality") == "INDIAN_ONLY":
        if (student.nationality or "").upper() != "INDIAN":
            fail_reasons.append("Nationality required: Indian")
        else:
            pass_reasons.append("Nationality: Indian OK")

    return not fail_reasons, pass_reasons, fail_reasons


def freshness(verified_at: datetime | None, *, today: date | None = None) -> str:
    if verified_at is None:
        return "OUTDATED"
    current_day = today or date.today()
    verified_day = verified_at.date()
    days = (current_day - verified_day).days
    if days < 90:
        return "FRESH"
    if days < 180:
        return "STALE"
    return "OUTDATED"


def _fallback_max_age(criteria: ExamCriteria, category: Category) -> int:
    general = criteria.max_age_general
    if category == Category.OBC:
        return criteria.max_age_obc or (general + 3 if general else 0)
    if category in (Category.SC, Category.ST):
        return criteria.max_age_sc_st or (general + 5 if general else 0)
    if category == Category.EWS:
        return criteria.max_age_ews or general
    return general


def _pwbd_fallback_max_age(criteria: ExamCriteria, relaxation: int) -> int:
    general = criteria.max_age_general
    return general + relaxation if general else 0


def _age_reference_date(criteria: ExamCriteria, today: date) -> date:
    if criteria.age_cutoff_day and criteria.age_cutoff_month:
        return date(today.year, criteria.age_cutoff_month, criteria.age_cutoff_day)
    return date(today.year, 1, 1)


def _student_education_level(student: StudentProfile) -> int:
    level = 0
    if student.percentage_10 is not None:
        level = max(level, EDUCATION_RANK[EducationLevel.TENTH])
    if student.percentage_12 is not None:
        level = max(level, EDUCATION_RANK[EducationLevel.TWELFTH])
    if student.graduation_status in (
        GraduationStatus.COMPLETED,
        GraduationStatus.PURSUING,
    ):
        level = max(level, EDUCATION_RANK[EducationLevel.GRADUATE])
    if student.post_graduation_percentage is not None:
        level = max(level, EDUCATION_RANK[EducationLevel.POST_GRADUATE])
    return level


def _percentage_for_required_level(
    student: StudentProfile,
    required: EducationLevel,
) -> float | None:
    if required == EducationLevel.TENTH:
        return student.percentage_10
    if required == EducationLevel.TWELFTH:
        return student.percentage_12
    if required == EducationLevel.GRADUATE:
        return student.graduation_percentage
    return student.post_graduation_percentage


def _education_label(level: EducationLevel) -> str:
    return {
        EducationLevel.TENTH: "10th",
        EducationLevel.TWELFTH: "12th",
        EducationLevel.GRADUATE: "Graduate",
        EducationLevel.POST_GRADUATE: "Post graduate",
    }[level]


def _sort_key(result: EligibilityResult) -> tuple[int, int, int, str]:
    freshness_order = {"FRESH": 0, "STALE": 1, "OUTDATED": 2}
    return (
        0 if result.registration_open else 1,
        0 if result.eligible else 1,
        freshness_order.get(result.freshness, 3),
        result.exam_short_name.lower(),
    )


def _normalize_exam_name(value: str) -> str:
    return value.strip().replace("_", " ").replace("-", " ").lower()


def utcnow() -> datetime:
    return datetime.now(timezone.utc)
