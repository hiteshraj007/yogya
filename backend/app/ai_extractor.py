import json
import os
import re
from typing import Any

from google import genai
from google.genai import types
from groq import AsyncGroq

from .models import MarksheetData

# ─── Module-level client (initialized in init_ai) ─────────
_gemini_client: genai.Client | None = None


async def init_ai() -> None:
    """Initialize the Gemini client with API key from environment."""
    global _gemini_client
    gemini_key = os.getenv("GEMINI_API_KEY")
    if gemini_key:
        _gemini_client = genai.Client(api_key=gemini_key)


def _get_gemini_client() -> genai.Client:
    """Return initialized Gemini client or raise."""
    if _gemini_client is None:
        raise RuntimeError("GEMINI_API_KEY not configured — call init_ai() first")
    return _gemini_client


def get_groq_client() -> AsyncGroq | None:
    api_key = os.getenv("GROQ_API_KEY")
    if api_key:
        return AsyncGroq(api_key=api_key)
    return None


def _json_from_model_text(text: str) -> dict[str, Any]:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```$", "", cleaned)
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start != -1 and end != -1 and end > start:
        cleaned = cleaned[start : end + 1]
    return json.loads(cleaned)


async def extract_criteria_from_pdf(pdf_bytes: bytes, exam_short_name: str) -> dict[str, Any]:
    """Uses Gemini to extract eligibility criteria from a PDF."""
    client = _get_gemini_client()
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    prompt = f"""You are extracting eligibility criteria from an official Indian government exam notification PDF for {exam_short_name}.
Extract ONLY what is explicitly written. If a value is not found, return null.
Do NOT guess or assume any values.
Return a JSON object with confidence scores (0-100) for each field.
Also return the page_number where you found each value.

Fields to extract:
{{
  "min_education": {{"value": "10TH" | "12TH" | "GRADUATE" | "POST_GRADUATE" | null, "confidence": 95, "page": 2}},
  "required_stream": {{"value": ["PCM"] | null, "confidence": 90, "page": 3}},
  "required_subjects": {{"value": ["Physics"] | null, "confidence": 100, "page": null}},
  "required_degree": {{"value": ["BTech"] | null, "confidence": 100, "page": null}},
  "min_percentage_general": {{"value": 0, "confidence": 98, "page": 2}},
  "min_percentage_obc": {{"value": 0, "confidence": 98, "page": 2}},
  "min_percentage_sc_st": {{"value": 0, "confidence": 98, "page": 2}},
  "min_percentage_ews": {{"value": 0, "confidence": 98, "page": 2}},
  "min_age": {{"value": 21, "confidence": 99, "page": 4}},
  "max_age_general": {{"value": 32, "confidence": 99, "page": 4}},
  "max_age_obc": {{"value": 35, "confidence": 99, "page": 4}},
  "max_age_sc_st": {{"value": 37, "confidence": 99, "page": 4}},
  "max_age_pwbd_general": {{"value": 42, "confidence": 95, "page": 4}},
  "age_cutoff_day": {{"value": 1, "confidence": 99, "page": 4}},
  "age_cutoff_month": {{"value": 8, "confidence": 99, "page": 4}},
  "max_attempts_general": {{"value": 6, "confidence": 98, "page": 5}},
  "max_attempts_obc": {{"value": 9, "confidence": 98, "page": 5}},
  "max_attempts_sc_st": {{"value": -1, "confidence": 95, "page": 5}},
  "additional_rules": {{"value": {{"marital_status": null, "gender": null, "nationality": null}}, "confidence": 90, "page": null}},
  "notification_year": {{"value": 2025, "confidence": 99, "page": 1}}
}}
"""

    response = await client.aio.models.generate_content(
        model=model_name,
        contents=[
            types.Part.from_bytes(data=pdf_bytes, mime_type="application/pdf"),
            prompt,
        ],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
        ),
    )

    return _json_from_model_text(response.text)


async def extract_registration_dates_from_pdf(pdf_bytes: bytes) -> dict[str, Any]:
    """Uses Gemini to extract registration dates from a PDF."""
    client = _get_gemini_client()
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    prompt = """Extract registration details from this exam notification PDF.
Return a JSON object exactly like this, replacing placeholders with actual values or null if not found.
Use ISO8601 format for dates if possible, else just copy the text.
{
  "registration_start": "2025-02-01T00:00:00",
  "registration_end": "2025-03-01T23:59:59",
  "exam_date_text": "May-June 2025",
  "admit_card_date": "2025-04-15T00:00:00",
  "result_date": null,
  "apply_url": "https://apply.exam.gov.in",
  "official_url": "https://exam.gov.in",
  "correction_window_start": null,
  "correction_window_end": null
}"""

    response = await client.aio.models.generate_content(
        model=model_name,
        contents=[
            types.Part.from_bytes(data=pdf_bytes, mime_type="application/pdf"),
            prompt,
        ],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
        ),
    )
    return _json_from_model_text(response.text)


async def extract_marksheet_raw_text(file_bytes: bytes, mime_type: str) -> str:
    """Extract raw text from a marksheet image/PDF using Gemini Vision."""
    client = _get_gemini_client()
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    prompt = """Extract ALL text from this Indian school/college marksheet exactly as printed.
Include every: student name, roll number, date of birth, school name, board name,
exam year, subject names with marks obtained, maximum marks, grades, total, percentage, result.
Output as plain text preserving structure. Do NOT summarize or interpret."""

    response = await client.aio.models.generate_content(
        model=model_name,
        contents=[
            types.Part.from_bytes(data=file_bytes, mime_type=mime_type),
            prompt,
        ],
    )
    return response.text


async def structure_marksheet_data(raw_text: str, marksheet_type: str) -> MarksheetData:
    """Structure raw text using Groq Llama-3."""
    groq_client = get_groq_client()
    if not groq_client:
        raise RuntimeError("GROQ_API_KEY not configured")

    normalized_type = _detect_marksheet_type(raw_text) if marksheet_type == "auto" else marksheet_type
    model = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")
    
    prompt = f"""Structure this raw Indian marksheet text into JSON.
Raw Text:
{raw_text}

Extract it according to this JSON format. Leave as null if not found.
Detected marksheet_type: {normalized_type}
"""
    if normalized_type == "college":
        prompt += """{
  "student_name": "string", "roll_number": "string", "university": "string",
  "degree": "string", "branch": "string", "semester_year": "string",
  "cgpa": 0.0, "percentage": 0.0, "year_of_passing": 2023, "result": "string"
}"""
    else:
        prompt += """{
  "student_name": "string", "dob": "DD/MM/YYYY", "roll_number": "string",
  "board": "string", "exam_year": 2020, "class_level": "10 or 12", "stream": "string",
  "subjects": [{"name": "string", "marks_obtained": 0, "max_marks": 0, "grade": "string"}],
  "total_marks": 0, "max_total_marks": 0, "percentage": 0.0, "result": "PASS/FAIL", "overall_grade": "string"
}"""

    response = await groq_client.chat.completions.create(
        messages=[{"role": "user", "content": prompt}],
        model=model,
        response_format={"type": "json_object"},
        temperature=0.05,
    )
    
    content = response.choices[0].message.content
    data_dict = _json_from_model_text(content or "{}")
    if normalized_type in ("10th", "12th"):
        data_dict["class_level"] = "10" if normalized_type == "10th" else "12"
    return MarksheetData(**data_dict)


def _detect_marksheet_type(raw_text: str) -> str:
    lower = raw_text.lower()
    if any(
        key in lower
        for key in ["university", "college", "semester", "cgpa", "b.tech", "b.sc", "bca", "mba"]
    ):
        return "college"
    if any(
        key in lower
        for key in ["class xii", "class 12", "higher secondary", "intermediate", "+2", "12th", "senior secondary"]
    ):
        return "12th"
    return "10th"
