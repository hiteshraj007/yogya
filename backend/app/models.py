from __future__ import annotations

from datetime import date, datetime
from enum import StrEnum
from typing import Any

from pydantic import BaseModel, Field, field_validator


class Category(StrEnum):
    GENERAL = "GENERAL"
    OBC = "OBC"
    SC = "SC"
    ST = "ST"
    EWS = "EWS"


class EducationLevel(StrEnum):
    TENTH = "10TH"
    TWELFTH = "12TH"
    GRADUATE = "GRADUATE"
    POST_GRADUATE = "POST_GRADUATE"


class GraduationStatus(StrEnum):
    COMPLETED = "COMPLETED"
    PURSUING = "PURSUING"
    NOT_APPLICABLE = "NOT_APPLICABLE"


class RegistrationStatus(BaseModel):
    registration_open: bool = False
    registration_start: datetime | None = None
    registration_end: datetime | None = None
    exam_date_text: str | None = None
    admit_card_date: datetime | None = None
    result_date: datetime | None = None
    apply_url: str | None = None
    official_url: str | None = None
    notification_pdf_url: str | None = None
    correction_window_start: datetime | None = None
    correction_window_end: datetime | None = None
    last_scraped_at: datetime | None = None


class ExamCriteria(BaseModel):
    exam_short_name: str
    exam_full_name: str
    conducting_body: str = ""
    exam_category: str = "OTHER"

    min_education: EducationLevel = EducationLevel.TENTH
    required_stream: list[str] | None = None
    required_subjects: list[str] | None = None
    required_degree: list[str] | None = None
    min_percentage_general: float = 0
    min_percentage_obc: float = 0
    min_percentage_sc_st: float = 0
    min_percentage_ews: float = 0

    min_age: int = 0
    max_age_general: int = 0
    max_age_obc: int = 0
    max_age_sc_st: int = 0
    max_age_ews: int = 0
    max_age_pwbd_general: int = 0
    max_age_pwbd_obc: int = 0
    max_age_pwbd_sc_st: int = 0
    age_cutoff_day: int | None = None
    age_cutoff_month: int | None = None

    max_attempts_general: int = -1
    max_attempts_obc: int = -1
    max_attempts_sc_st: int = -1
    max_attempts_ews: int = -1

    additional_rules: dict[str, Any] | None = None
    notification_year: int | None = None
    source_pdf_url: str | None = None
    admin_verified: bool = False
    verified_by: str | None = None
    verified_at: datetime | None = None
    verification_notes: str | None = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = True

    registration: RegistrationStatus = Field(default_factory=RegistrationStatus)


class StudentProfile(BaseModel):
    dob: str = Field(..., description="DD/MM/YYYY")
    category: Category = Category.GENERAL
    is_pwbd: bool = False
    gender: str | None = None
    marital_status: str | None = None
    nationality: str | None = "INDIAN"

    percentage_10: float | None = None
    board_10: str | None = None
    year_10: int | None = None
    percentage_12: float | None = None
    board_12: str | None = None
    year_12: int | None = None
    stream_12: str | None = None
    subjects_12: dict[str, float] = Field(default_factory=dict)

    graduation_status: GraduationStatus = GraduationStatus.NOT_APPLICABLE
    degree: str | None = None
    graduation_percentage: float | None = None
    graduation_year: int | None = None
    post_graduation_percentage: float | None = None

    attempts_used: dict[str, int] = Field(default_factory=dict)

    @field_validator("dob")
    @classmethod
    def validate_dob(cls, value: str) -> str:
        parse_dob(value)
        return value


class EligibilityResult(BaseModel):
    exam_short_name: str
    exam_full_name: str
    exam_category: str
    conducting_body: str
    eligible: bool
    reasons_pass: list[str]
    reasons_fail: list[str]
    age_at_cutoff: int
    attempts_remaining: int
    notification_year: int | None
    last_verified: datetime | None
    freshness: str
    source_pdf_url: str | None
    registration_open: bool
    registration_end: datetime | None
    exam_date: str | None
    apply_url: str | None
    official_url: str | None


class EligibilitySummary(BaseModel):
    total_exams_checked: int
    eligible_count: int
    registration_open_count: int


class EligibilityResponse(BaseModel):
    summary: EligibilitySummary
    results: list[EligibilityResult]


class SubjectMarks(BaseModel):
    name: str
    marks_obtained: float | None = None
    max_marks: float | None = None
    grade: str | None = None


class MarksheetData(BaseModel):
    student_name: str | None = None
    dob: str | None = None
    roll_number: str | None = None
    board: str | None = None
    exam_year: int | None = None
    class_level: str | None = None
    stream: str | None = None
    subjects: list[SubjectMarks] = Field(default_factory=list)
    total_marks: float | None = None
    max_total_marks: float | None = None
    percentage: float | None = None
    result: str | None = None
    overall_grade: str | None = None
    university: str | None = None
    degree: str | None = None
    branch: str | None = None
    semester_year: str | None = None
    cgpa: float | None = None
    year_of_passing: int | None = None


class MarksheetValidationResponse(BaseModel):
    success: bool
    marksheet_type: str
    confidence: str
    data: MarksheetData
    validation_errors: list[str] = Field(default_factory=list)
    validation_warnings: list[str] = Field(default_factory=list)
    needs_user_correction: bool


def parse_dob(value: str) -> date:
    parts = value.strip().split("/")
    if len(parts) != 3:
        raise ValueError("DOB must be DD/MM/YYYY")
    day, month, year = (int(part) for part in parts)
    return date(year, month, day)
