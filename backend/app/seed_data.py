from __future__ import annotations

from datetime import datetime, timezone

from .models import EducationLevel, ExamCriteria, RegistrationStatus


def _verified_at() -> datetime:
    return datetime(2026, 1, 1, tzinfo=timezone.utc)


SEED_CRITERIA: list[ExamCriteria] = [
    ExamCriteria(
        exam_short_name="UPSC CSE",
        exam_full_name="UPSC Civil Services Examination",
        conducting_body="UPSC",
        exam_category="CIVIL_SERVICES",
        min_education=EducationLevel.GRADUATE,
        min_age=21,
        max_age_general=32,
        max_age_obc=35,
        max_age_sc_st=37,
        age_cutoff_day=1,
        age_cutoff_month=8,
        max_attempts_general=6,
        max_attempts_obc=9,
        max_attempts_sc_st=-1,
        additional_rules={"nationality": "INDIAN_ONLY"},
        notification_year=2025,
        official_url="https://upsc.gov.in",
        admin_verified=True,
        verified_at=_verified_at(),
        registration=RegistrationStatus(
            official_url="https://upsc.gov.in",
            apply_url="https://upsconline.nic.in",
        ),
    ),
    ExamCriteria(
        exam_short_name="SSC CGL",
        exam_full_name="SSC Combined Graduate Level",
        conducting_body="SSC",
        exam_category="SSC",
        min_education=EducationLevel.GRADUATE,
        min_age=18,
        max_age_general=32,
        max_age_obc=35,
        max_age_sc_st=37,
        max_attempts_general=-1,
        max_attempts_obc=-1,
        max_attempts_sc_st=-1,
        notification_year=2025,
        admin_verified=True,
        verified_at=_verified_at(),
        registration=RegistrationStatus(
            official_url="https://ssc.gov.in",
            apply_url="https://ssc.gov.in",
        ),
    ),
    ExamCriteria(
        exam_short_name="SSC CHSL",
        exam_full_name="SSC Combined Higher Secondary Level",
        conducting_body="SSC",
        exam_category="SSC",
        min_education=EducationLevel.TWELFTH,
        min_age=18,
        max_age_general=27,
        max_age_obc=30,
        max_age_sc_st=32,
        notification_year=2025,
        admin_verified=True,
        verified_at=_verified_at(),
        registration=RegistrationStatus(
            official_url="https://ssc.gov.in",
            apply_url="https://ssc.gov.in",
        ),
    ),
    ExamCriteria(
        exam_short_name="NDA",
        exam_full_name="National Defence Academy and Naval Academy Examination",
        conducting_body="UPSC",
        exam_category="DEFENCE",
        min_education=EducationLevel.TWELFTH,
        required_stream=["PCM"],
        required_subjects=["Physics", "Mathematics"],
        min_age=16,
        max_age_general=18,
        max_age_obc=18,
        max_age_sc_st=18,
        additional_rules={"marital_status": "UNMARRIED"},
        notification_year=2025,
        admin_verified=True,
        verified_at=_verified_at(),
        registration=RegistrationStatus(
            official_url="https://upsc.gov.in",
            apply_url="https://upsconline.nic.in",
        ),
    ),
    ExamCriteria(
        exam_short_name="AFCAT",
        exam_full_name="Air Force Common Admission Test",
        conducting_body="Indian Air Force",
        exam_category="DEFENCE",
        min_education=EducationLevel.GRADUATE,
        min_percentage_general=60,
        min_percentage_obc=60,
        min_percentage_sc_st=60,
        min_percentage_ews=60,
        min_age=20,
        max_age_general=24,
        max_age_obc=24,
        max_age_sc_st=24,
        notification_year=2025,
        admin_verified=True,
        verified_at=_verified_at(),
        registration=RegistrationStatus(
            official_url="https://afcat.cdac.in",
            apply_url="https://afcat.cdac.in",
        ),
    ),
]


def get_seed_criteria() -> list[ExamCriteria]:
    return [criteria.model_copy(deep=True) for criteria in SEED_CRITERIA]
