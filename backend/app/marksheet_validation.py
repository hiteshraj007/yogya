from __future__ import annotations

from datetime import date

from .models import MarksheetData, MarksheetValidationResponse


BOARD_MAPPINGS = {
    "central board": "CBSE",
    "cbse": "CBSE",
    "rajasthan board": "RBSE",
    "rbse": "RBSE",
    "bser": "RBSE",
    "maharashtra board": "MSBSHSE",
    "msbshse": "MSBSHSE",
    "madhya pradesh board": "MPBSE",
    "mpbse": "MPBSE",
    "uttar pradesh board": "UPMSP",
    "upmsp": "UPMSP",
    "up board": "UPMSP",
    "bihar board": "BSEB",
    "bseb": "BSEB",
    "haryana board": "HBSE",
    "hbse": "HBSE",
    "bseh": "HBSE",
    "jharkhand board": "JAC",
    "jac": "JAC",
    "karnataka board": "KSEEB",
    "kseeb": "KSEEB",
    "sslc": "KSEEB",
    "tamil nadu board": "TNBSE",
    "tnbse": "TNBSE",
}


def validate_marksheet(
    data: MarksheetData,
    marksheet_type: str,
) -> MarksheetValidationResponse:
    errors: list[str] = []
    warnings: list[str] = []
    normalized = data.model_copy(deep=True)

    if normalized.board:
        normalized.board = standardize_board(normalized.board)

    if marksheet_type == "auto":
        marksheet_type = detect_marksheet_type(normalized)

    if marksheet_type == "12th":
        normalized.stream = normalized.stream or detect_stream(
            [subject.name for subject in normalized.subjects]
        )

    calculated_pct = percentage_from_subjects(normalized)
    if calculated_pct is not None:
        if normalized.percentage is not None:
            diff = abs(calculated_pct - normalized.percentage)
            if diff > 3:
                warnings.append(
                    "Percentage mismatch: "
                    f"stated {normalized.percentage:.1f}% vs calculated "
                    f"{calculated_pct:.1f}%"
                )
                normalized.percentage = round(calculated_pct, 2)
        else:
            normalized.percentage = round(calculated_pct, 2)

    for subject in normalized.subjects:
        if (
            subject.marks_obtained is not None
            and subject.max_marks is not None
            and subject.marks_obtained > subject.max_marks
        ):
            errors.append(
                f"{subject.name}: marks obtained cannot exceed maximum marks"
            )

    year = normalized.exam_year or normalized.year_of_passing
    current_year = date.today().year
    if year is not None and not 2000 <= year <= current_year:
        errors.append(f"Exam year {year} is outside valid range 2000-{current_year}")

    confidence = confidence_label(normalized, errors)

    return MarksheetValidationResponse(
        success=not errors,
        marksheet_type=marksheet_type,
        confidence=confidence,
        data=normalized,
        validation_errors=errors,
        validation_warnings=warnings,
        needs_user_correction=confidence == "LOW" or bool(errors),
    )


def detect_marksheet_type(data: MarksheetData) -> str:
    text = " ".join(
        [
            data.university or "",
            data.degree or "",
            data.semester_year or "",
            data.class_level or "",
        ]
    ).lower()
    if any(
        key in text
        for key in ["university", "college", "semester", "cgpa", "b.tech", "b.sc", "bca", "mba"]
    ):
        return "college"
    if any(
        key in text
        for key in ["class xii", "class 12", "higher secondary", "intermediate", "+2", "12th"]
    ):
        return "12th"
    return "10th"


def standardize_board(value: str) -> str:
    lower = value.lower()
    for key, board in BOARD_MAPPINGS.items():
        if key in lower:
            return board
    return value.strip()


def detect_stream(subjects: list[str]) -> str:
    subject_set = {subject.lower() for subject in subjects}
    joined = " ".join(subject_set)
    has_physics = "physics" in joined
    has_chemistry = "chemistry" in joined
    has_math = "mathematics" in joined or "math" in joined
    has_biology = (
        "biology" in joined or "botany" in joined or "zoology" in joined
    )
    has_accounts = "accountancy" in joined or "accounts" in joined
    has_business = "business studies" in joined or "economics" in joined

    if has_physics and has_math and has_chemistry:
        return "PCM"
    if has_physics and has_chemistry and has_biology:
        return "PCB"
    if has_accounts and has_business:
        return "COMMERCE"
    return "ARTS"


def percentage_from_subjects(data: MarksheetData) -> float | None:
    total = data.total_marks or 0
    maximum = data.max_total_marks or 0

    if not total or not maximum:
        for subject in data.subjects:
            if subject.marks_obtained is None or subject.max_marks is None:
                continue
            total += subject.marks_obtained
            maximum += subject.max_marks

    if maximum <= 0 or total <= 0 or total > maximum:
        return None
    return (total / maximum) * 100


def confidence_label(data: MarksheetData, errors: list[str]) -> str:
    required = [
        data.student_name,
        data.percentage,
        data.board or data.university,
        data.exam_year or data.year_of_passing,
    ]
    found_count = sum(1 for item in required if item not in (None, ""))
    if found_count == 4 and not errors:
        return "HIGH"
    if found_count >= 2:
        return "MEDIUM"
    return "LOW"
