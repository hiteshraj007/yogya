"""
Yogya PDF Parser Microservice
Listens on http://127.0.0.1:5050
Endpoints:
  GET  /health         -> {"status": "ok"}
  POST /parse-pdf      -> multipart file upload  -> structured JSON
  POST /parse-image    -> multipart file upload  -> structured JSON
"""

import io
import re
import json
import traceback
from flask import Flask, request, jsonify
from flask_cors import CORS

# PDF extraction
import pdfplumber

# OCR for images / scanned PDFs
try:
    import pytesseract
    from PIL import Image
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False

app = Flask(__name__)
CORS(app)


# ─── Health ───────────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "ocr_available": OCR_AVAILABLE}), 200


# ─── Parse PDF ───────────────────────────────────────────────────────────────

@app.route("/parse-pdf", methods=["POST"])
def parse_pdf():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    pdf_bytes = file.read()

    try:
        text = _extract_pdf_text(pdf_bytes)
        if not text.strip():
            return jsonify({"error": "Could not extract text from PDF. Is it a scanned image PDF?"}), 422

        result = _parse_marksheet_text(text)
        return jsonify(result), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


# ─── Parse Image ─────────────────────────────────────────────────────────────

@app.route("/parse-image", methods=["POST"])
def parse_image():
    if not OCR_AVAILABLE:
        return jsonify({"error": "Tesseract/Pillow not installed. Run: pip install pytesseract pillow"}), 503

    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    img_bytes = file.read()

    try:
        image = Image.open(io.BytesIO(img_bytes))
        text = pytesseract.image_to_string(image, lang=request.args.get("lang", "eng"))
        result = _parse_marksheet_text(text)
        return jsonify(result), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


# ─── PDF text extraction ──────────────────────────────────────────────────────

def _extract_pdf_text(pdf_bytes: bytes) -> str:
    """Extract all text from a PDF using pdfplumber. Falls back to OCR if empty."""
    text_parts = []
    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        for page in pdf.pages:
            t = page.extract_text()
            if t:
                text_parts.append(t)

            # Also extract tables
            for table in page.extract_tables():
                for row in table:
                    if row:
                        clean = [c.strip() if c else "" for c in row]
                        text_parts.append("  |  ".join(clean))

    combined = "\n".join(text_parts)

    # If no text found and OCR available, try image-based extraction
    if not combined.strip() and OCR_AVAILABLE:
        combined = _ocr_pdf(pdf_bytes)

    return combined


def _ocr_pdf(pdf_bytes: bytes) -> str:
    """Convert PDF pages to images and run Tesseract OCR."""
    try:
        import pdf2image
        images = pdf2image.convert_from_bytes(pdf_bytes, dpi=300)
        parts = []
        for img in images:
            parts.append(pytesseract.image_to_string(img, lang="eng"))
        return "\n".join(parts)
    except ImportError:
        return ""


# ─── Core marksheet parser ────────────────────────────────────────────────────

def _parse_marksheet_text(text: str) -> dict:
    """Parse extracted text and return structured result matching OcrResult fields."""
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    full_text = " ".join(lines).lower()

    result = {
        "doc_level":            _detect_doc_level(full_text, lines),
        "name":                 _extract_name(text, lines),
        "father_name":          _extract_field(text, ["father", "father's name", "father name"]),
        "mother_name":          _extract_field(text, ["mother", "mother's name", "mother name"]),
        "dob":                  _extract_dob(text),
        "roll_number":          _extract_field(text, ["roll no", "roll number", "roll no.", "roll"]),
        "registration_number":  _extract_field(text, ["registration no", "reg no", "registration number", "enrolment no", "enrollment no"]),
        "board_university":     _extract_board(text, lines),
        "school":               _extract_school(text, lines),
        "exam":                 _extract_exam(text, lines),
        "year":                 _extract_year(text),
        "percentage":           _extract_percentage(text, lines),
        "cgpa":                 _extract_cgpa(text),
        "subject_details":      _extract_subjects(text, lines),
        "total_marks_obtained_outoff": _extract_total_marks(text),
    }

    return result


# ─── Field extractors ─────────────────────────────────────────────────────────

def _detect_doc_level(full_text: str, lines: list) -> str:
    """Detect document level: 10th, 12th, graduation, pg, diploma."""
    t = full_text

    # ── PG / Masters ──────────────────────────────────────────────────────────
    pg_kw = ["master of", "m.tech", "m.sc", "m.com", "mba", "mca", "m.a.", " ma ", "post graduate", "postgraduate", "post-graduate", "pg degree"]
    if any(k in t for k in pg_kw):
        return "pg"

    # ── 12th / HSC ────────────────────────────────────────────────────────────
    hsc_kw = ["senior secondary", "higher secondary", "class xii", "class 12", "std xii", "grade xii", "+2", "plus two", "hsc", "intermediate", "12th", "all india senior school certificate"]
    if any(k in t for k in hsc_kw):
        return "12th"

    # ── 10th / SSC ────────────────────────────────────────────────────────────
    ssc_kw = ["secondary school certificate", "class x", "class 10", "std x", "grade x", "high school", "matric", "sslc", "10th", "secondary examination", "all india secondary school examination", "aisse"]
    if any(k in t for k in ssc_kw):
        return "10th"

    # ── Diploma ───────────────────────────────────────────────────────────────
    if "diploma" in t or "polytechnic" in t:
        return "diploma"

    # ── Graduation / UG ───────────────────────────────────────────────────────
    ug_kw = ["bachelor of", "b.tech", "b.sc", "b.com", "b.a.", "bca", "bba", " be ", "degree", "graduation", "university"]
    if any(k in t for k in ug_kw):
        return "graduation"

    return "unknown"


def _extract_name(text: str, lines: list) -> str:
    """Extract student name."""
    patterns = [
        r"(?:candidate|student|name of (?:the )?(?:student|candidate))[:\s]+([A-Z][A-Za-z .'-]{2,50})",
        r"(?:certify that|certified that)\s+([A-Z][A-Za-z .'-]{2,50})",
        r"(?:^|\n)\s*Name\s*[:\-]\s*([A-Z][A-Za-z .'-]{2,50})",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.IGNORECASE | re.MULTILINE)
        if m:
            name = m.group(1).strip()
            # Remove trailing noise
            name = re.sub(r"\s+(father|mother|dob|date|roll|class|subject).*", "", name, flags=re.IGNORECASE)
            if len(name) > 2:
                return name

    # Fallback: look for lines that look like names (all caps, 2-4 words)
    for line in lines[:30]:
        if re.match(r"^[A-Z][A-Z\s.'-]{4,40}$", line):
            words = line.split()
            if 2 <= len(words) <= 5 and all(len(w) >= 2 for w in words):
                return line.title()

    return ""


def _extract_field(text: str, labels: list) -> str:
    """Generic key-value extractor for a list of possible labels."""
    for label in labels:
        pattern = rf"(?:{re.escape(label)})\s*[:\-\.]\s*([A-Za-z0-9/ .'-]{{2,80}})"
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            val = m.group(1).strip().split("\n")[0].strip()
            # Stop at next label-like boundary
            val = re.split(r"\s{2,}|\|", val)[0].strip()
            if len(val) > 1:
                return val
    return ""


def _extract_dob(text: str) -> str:
    """Extract date of birth and normalise to DD/MM/YYYY."""
    patterns = [
        r"(?:date of birth|dob|d\.o\.b|birth date)\s*[:\-\.]?\s*(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})",
        r"(?:date of birth|dob|d\.o\.b|birth date)\s*[:\-\.]?\s*(\d{1,2}\s+\w+\s+\d{4})",
        r"\b(\d{2}[/\-]\d{2}[/\-]\d{4})\b",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            raw = m.group(1).strip()
            return _normalise_date(raw)
    return ""


def _normalise_date(raw: str) -> str:
    raw = raw.strip()
    # DD/MM/YYYY or DD-MM-YYYY
    m = re.match(r"(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})", raw)
    if m:
        return f"{m.group(1).zfill(2)}/{m.group(2).zfill(2)}/{m.group(3)}"
    # YYYY-MM-DD
    m = re.match(r"(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})", raw)
    if m:
        return f"{m.group(3).zfill(2)}/{m.group(2).zfill(2)}/{m.group(1)}"
    # DD Month YYYY
    months = {"jan":1,"feb":2,"mar":3,"apr":4,"may":5,"jun":6,"jul":7,"aug":8,"sep":9,"oct":10,"nov":11,"dec":12,
               "january":1,"february":2,"march":3,"april":4,"june":6,"july":7,"august":8,"september":9,"october":10,"november":11,"december":12}
    m = re.match(r"(\d{1,2})\s+([a-zA-Z]+)\s+(\d{4})", raw)
    if m:
        mon = months.get(m.group(2).lower(), 0)
        if mon:
            return f"{m.group(1).zfill(2)}/{str(mon).zfill(2)}/{m.group(3)}"
    return raw


def _extract_board(text: str, lines: list) -> str:
    """Extract board/university name."""
    normalized_text = re.sub(r'\s+', ' ', text).lower()

    # Common known boards appearing verbatim
    known = [
        "Central Board of Secondary Education",
        "CBSE",
        "Council for the Indian School Certificate Examinations",
        "National Institute of Open Schooling",
        "UP Board", "Bihar School Examination Board",
        "Maharashtra State Board", "Karnataka Secondary Education",
    ]
    for board in known:
        if board.lower() in normalized_text:
            if board == "CBSE":
                return "Central Board of Secondary Education"
            return board

    patterns = [
        r"(?:board of education|university|board of secondary)[:\s]+([A-Za-z ()&,.'-]{5,80})",
        r"(central board of secondary education)",
        r"(central board|state board|council for)[^\n]{0,60}",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            val = m.group(1) if m.lastindex else m.group(0)
            val = val.strip().split("\n")[0].strip()
            # filter out false positives
            if len(val) > 5 and not val.lower().startswith("examination"):
                return val.title()

    return ""


def _extract_school(text: str, lines: list) -> str:
    """Extract school / centre / institution name."""
    patterns = [
        r"(?:school|institution|college|centre|center|vidyalaya|done from which place and school|place and school)[:\s]+([A-Za-z ()&,.'0-9-]{5,100})",
        r"(?:school|institution|college|centre|center|vidyalaya)\s+([A-Za-z ()&,.'0-9-]{5,100})",
        r"(?:name of school|name of institution|place|school)[:\s]+([A-Za-z ()&,.'0-9-]{5,100})",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            val = m.group(1).strip().split("\n")[0]
            val = re.split(r"\s{2,}|\|", val)[0].strip()
            if len(val) > 4:
                return val.title()
    return ""


def _extract_exam(text: str, lines: list) -> str:
    """Extract exam name."""
    patterns = [
        r"(?:examination|exam)[:\s]+([A-Za-z ()&,.'0-9-]{5,100})",
        r"(?:all india|senior school|secondary school|higher secondary)[^\n]{0,80}",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            return m.group(0).strip().title()
    return ""


def _extract_year(text: str) -> str:
    """Extract year of passing."""
    patterns = [
        r"(?:year of passing|passing year|year|session)\s*[:\-]\s*(\d{4}(?:[/\-]\d{2,4})?)",
        r"\b(20[0-2]\d)\b",
        r"\b(19[8-9]\d)\b",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            return m.group(1).strip()
    return ""


def _extract_percentage(text: str, lines: list) -> float | None:
    """Extract aggregate percentage."""
    patterns = [
        r"(?:total percentage of marks obtained|percentage of marks|percentage|per cent|marks percentage|overall percentage|aggregate)[^\d]*(\d{1,3}(?:\.\d{1,2})?)\s*%?",
        r"(\d{2,3}\.\d{1,2})\s*%",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.IGNORECASE)
        if m:
            try:
                val = float(m.group(1))
                if 0 < val <= 100:
                    return round(val, 2)
            except ValueError:
                pass
                
    # If not found directly, calculate from subjects
    subjects = _extract_subjects(text, lines)
    if subjects:
        obtained = sum(s.get("total_marks", s.get("marks_obtained", 0)) for s in subjects)
        maximum = sum(s.get("max_marks", 100) for s in subjects if "total_marks" in s or "marks_obtained" in s)
        if maximum > 0 and obtained > 0 and obtained <= maximum:
            return round((obtained / maximum) * 100, 2)
            
    return None


def _extract_cgpa(text: str) -> float | None:
    """Extract CGPA if present."""
    m = re.search(r"(?:cgpa|gpa|grade point average)[^\d]*(\d(?:\.\d{1,2})?)", text, re.IGNORECASE)
    if m:
        try:
            return float(m.group(1))
        except ValueError:
            pass
    return None


def _extract_subjects(text: str, lines: list) -> list:
    """Extract subject-wise marks as a list of dicts."""
    subjects = []
    seen = set()

    # Digilocker CBSE specific format: Code Subject Th Pr Total Words Grade
    # 184 ENGLISH LNG & LIT. 071 020 091 NINETY ONE A2
    cbse_pattern = re.compile(
        r"^\s*(?:\d{3})\s+([A-Z][A-Z\s&.-]{3,40}?)\s+(?:AB|\d{2,3})\s+(?:AB|\d{2,3})\s+(\d{2,3})\s+[A-Z\s]+\s+([A-E][1-2]?)\s*$",
        re.IGNORECASE | re.MULTILINE
    )
    for m in cbse_pattern.finditer(text):
        subj = m.group(1).strip().title()
        obtained = int(m.group(2))
        grade = m.group(3)
        if subj not in seen:
            seen.add(subj)
            subjects.append({
                "name": subj,
                "total_marks": obtained,
                "max_marks": 100,
                "grade": grade,
            })

    # Pattern: SubjectName  MarksObtained  MaxMarks  Grade
    table_pattern = re.compile(
        r"([A-Za-z][A-Za-z (),./:-]{3,50}?)\s{2,}(\d{1,3})\s*/\s*(\d{1,3})(?:\s+([A-E][1-9]?|\bPass\b|\bFail\b))?",
        re.IGNORECASE,
    )
    for m in table_pattern.finditer(text):
        subj = m.group(1).strip().title()
        obtained = int(m.group(2))
        maximum = int(m.group(3))
        grade = m.group(4) or ""

        # Filter noise
        noise = ["roll", "total", "grand", "aggregate", "theory", "practical", "name", "date", "father", "mother"]
        if any(n in subj.lower() for n in noise):
            continue
        if not (0 <= obtained <= maximum <= 600):
            continue
        if subj in seen:
            continue
        seen.add(subj)

        subjects.append({
            "name": subj,
            "total_marks": obtained,
            "max_marks": maximum,
            "grade": grade.strip(),
        })

    # Fallback: marks without max
    if not subjects:
        simple_pattern = re.compile(
            r"([A-Za-z][A-Za-z (),./:-]{3,45}?)\s{2,}(\d{2,3})(?:\s+([A-E][1-9]?|\bPass\b|\bFail\b))?",
            re.IGNORECASE,
        )
        for m in simple_pattern.finditer(text):
            subj = m.group(1).strip().title()
            obtained = int(m.group(2))
            grade = m.group(3) or ""

            noise = ["roll", "total", "grand", "aggregate", "year", "session"]
            if any(n in subj.lower() for n in noise):
                continue
            if obtained > 600:
                continue
            if subj in seen:
                continue
            seen.add(subj)

            subjects.append({
                "name": subj,
                "marks_obtained": obtained,
                "grade": grade.strip(),
            })

    return subjects[:20]  # Cap at 20 subjects


def _extract_total_marks(text: str) -> str:
    """Extract total marks obtained out of maximum."""
    m = re.search(
        r"(?:total|grand total|total marks)\s*[:\-]?\s*(\d{2,4})\s*/\s*(\d{2,4})",
        text, re.IGNORECASE
    )
    if m:
        return f"{m.group(1)}/{m.group(2)}"
    m = re.search(r"(?:total marks obtained)\s*[:\-]?\s*(\d{2,4})", text, re.IGNORECASE)
    if m:
        return m.group(1)
    return ""


# ─── Entrypoint ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 55)
    print("  Yogya PDF Parser Microservice")
    print("  Listening on http://127.0.0.1:5050")
    print("  Endpoints:")
    print("    GET  /health")
    print("    POST /parse-pdf   (multipart file)")
    print("    POST /parse-image (multipart file)")
    print("=" * 55)
    app.run(host="127.0.0.1", port=5050, debug=False)
